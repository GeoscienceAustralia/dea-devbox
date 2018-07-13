#!/bin/bash

add_repos() {
    apt-get update
    apt-get install -y --no-install-recommends \
            software-properties-common

    for repo in "$@"; do
        add-apt-repository -y "$repo"
    done
    apt-get update
}

has_dot () {
    echo "${1}" | grep "\." > /dev/null
}


## Common Python
install_common_py() {
    apt-get install -y --no-install-recommends \
            git \
            curl \
            python3 \
            python3-distutils \
            python3-setuptools \
            python3-pip

    pip3 install --no-cache pip --upgrade
    hash -r
    pip3 install --no-cache wheel setuptools
    pip3 install --no-cache --upgrade dateutils
}

install_dev_tools() {
    apt-get install -y --no-install-recommends \
            tig \
            htop
}

install_jupyter_hub() {
    pip3 install --no-cache \
         jupyterhub \
         oauthenticator \
         dockerspawner

    apt-get install -y --no-install-recommends npm
    hash node >/dev/null 2>&1 || ln -sf /usr/bin/nodejs /usr/local/bin/node
    npm install -g configurable-http-proxy
    npm cache clean --force

    install -D -d -m 755 /var/lib/jupyterhub/
}

install_notebook() {
    # notebook dependencies (download as pdf for example)
    apt-get install -y --no-install-recommends \
            vim \
            lmodern \
            texlive-fonts-extra \
            texlive-fonts-recommended \
            texlive-generic-recommended \
            texlive-latex-base \
            texlive-latex-extra \
            texlive-xetex \
            pandoc \
            ffmpeg \
            unzip

    pip3 install --no-cache notebook
}

## GDAL
install_geo_libs() {
    local rasterio_version=${1:-"1.0a12"}
    export CPLUS_INCLUDE_PATH=/usr/include/gdal
    export C_INCLUDE_PATH=/usr/include/gdal

    apt-get install -y --no-install-recommends\
            gdal-bin \
            gdal-data \
            libgdal-dev \
            libgdal20 \
            libudunits2-0

    apt-get install -y --no-install-recommends\
            build-essential \
            python3-dev \
            python3-numpy \
            python3-matplotlib

    pip3 install --no-cache GDAL fiona shapely
    pip3 install --no-cache --upgrade cython
    pip3 install --no-cache --upgrade boto3  # S3 for rasterio
    pip3 install --no-cache "git+https://github.com/mapbox/rasterio.git@${rasterio_version}"
}

install_datacube_lib() {
    local DATACUBE_VERSION=develop

    # deal with psycopg2 binary warning
    pip3 install --no-cache --no-binary :all: psycopg2

    pip3 install --no-cache \
         'git+https://github.com/opendatacube/datacube-core.git@'"${DATACUBE_VERSION}"'#egg=datacube[s3,test]'
}

install_jh_proxy() {
    ## Nginx + certbot + DNS
    local v="v0.1"
    apt-get install -y certbot nginx

    pip3 install --no-cache "https://github.com/Kirill888/jhub-nginx/archive/${v}.tar.gz#egg=jhub-nginx"'[ec2]'
}

install_db() {
    local v=${1:-"10"}
    apt-get install -y \
            "postgresql-${v}" \
            "postgresql-client-${v}" \
            "postgresql-contrib-${v}"
}

add_db_user() {
    local user=${1:-"ubuntu"}
    local role=${2}

    if [ "${role}" = "admin" ]; then
        sudo -u postgres createuser --superuser "${user}"
    else
        sudo -u postgres createuser "${user}"
    fi

    sudo -u postgres createdb "${user}"
}

new_user_hook () {
    local user=${1}
    local role=${2}
    local home_dir
    home_dir=$(eval echo "~${user}")

    echo "Running new user hook: $*"
    add_db_user "${user}" "${role}"

    cat <<EOF | sudo -u "${user}" tee "${home_dir}/.datacube.conf"
[datacube]
db_name: datacube
EOF
}

setup_datacube_db() {
    local dbname=${1:-"datacube"}
    local user=${2:-"ubuntu"}
    local role=${3:-"admin"}

    if psql -lqt | grep -qw "${dbname}" ; then
        echo "Database ${dbname} exists already"
    else
        sudo -u postgres createdb "${dbname}"
        new_user_hook "${user}" "${role}"
    fi
}

gen_config() {
    local ee
    ee="$(ec2env DOMAIN=domain ADMIN_USER=admin)"
    eval "$ee"

    for x in "${DOMAIN}" "${ADMIN_USER}"; do
        [ -z "$x" ] && return 1
    done

    has_dot "${DOMAIN}" || DOMAIN="${DOMAIN}.devbox.gadevs.ga"
    domain_prefix=$(echo "${DOMAIN}" | cut -d . -f 1)

    cat <<EOF
OAUTH_CLIENT_ID=ssm:///dev/jupyterhub/oauth.client.id
OAUTH_CLIENT_SECRET=ssm:///dev/jupyterhub/oauth.client.secret
OAUTH_CALLBACK_URL=ssm:///dev/jupyterhub/oauth.callback.url
OAUTH_CALLBACK_POSTFIX=${domain_prefix}
DOMAIN=${DOMAIN}
ADMIN_USER=${ADMIN_USER}
NEW_USER_HOOK=/opt/dea/dea-new-user-hook.sh
EOF

    return 0
}

dea_key () {
    local key_file="/run/dea/key.txt"

    if [ -f "${key_file}" ]; then
        cat "${key_file}"
        exit 0
    fi

    eval "$(ec2env KEY=ssm:///dev/devbox/key)"

    mkdir -p /run/dea
    echo "${KEY}" > "${key_file}"
    chmod 400 "${key_file}"
    echo "${KEY}"
}

fetch_certs () {
    # get wild card cert from s3 bucket
    local dir=${1:-"/run/dea/certs"}
    mkdir -p "${dir}"
    echo "Trying to fetch certificates from s3"
    aws s3 cp s3://dea-devbox-config/SSL/certs.tgz.gpg - | gpg --batch --passphrase "$(dea_key)" --decrypt 2> /dev/null | (cd "${dir}" && tar xz)
    echo "OK"
}

init_instance() {
    [ -f /etc/jupyterhub/jupyterhub.conf ] && echo "Already configured" && return 0

    if gen_config > /tmp/jupyterhub.conf ; then
        setup_datacube_db datacube ubuntu admin
        mv /tmp/jupyterhub.conf /etc/jupyterhub/jupyterhub.conf
        systemctl enable update-dns.service jupyterhub.service jupyterhub-proxy.service
        systemctl start update-dns.service jupyterhub.service jupyterhub-proxy.service
    else
        echo "Failed to generate config"
        return 1
    fi
}

revoke_all_certs() {
    find /etc/letsencrypt/live/ -name fullchain.pem -print0 | xargs -0 -l1 certbot -n revoke --cert-path
}
