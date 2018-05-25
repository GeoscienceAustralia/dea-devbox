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
    echo $1 | grep "\." > /dev/null
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
         jupyterhub=='0.8.*' \
         oauthenticator \
         dockerspawner

    apt-get install -y --no-install-recommends npm
    ln -sf /usr/bin/nodejs /usr/local/bin/node
    npm install -g configurable-http-proxy
    npm cache clean --force

    install -D -m 644 jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
    install -D -m 644 jupyterhub.service /etc/systemd/system/jupyterhub.service
    install -D -d -m 755 /var/lib/jupyterhub/

    [ "$SKIP_LAUNCH" ] && return 0

    systemctl enable jupyterhub
    systemctl start jupyterhub
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
            libav-tools \
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
    apt-get install -y certbot nginx

    pip3 install --no-cache "git+https://github.com/Kirill888/jhub-nginx-vhost.git@4b0c4e16"'#egg=jhub-nginx-vhost[ec2]'

    install -m 644 update-dns.service /etc/systemd/system/update-dns.service
    install -m 644 jupyterhub-proxy.service /etc/systemd/system/jupyterhub-proxy.service
    install -D -m 755 proxy_setup.sh /etc/jupyterhub/proxy_setup.sh

    [ "$SKIP_LAUNCH" ] && return 0

    systemctl enable update-dns jupyterhub-proxy
    systemctl start update-dns jupyterhub-proxy
}

install_datacube_db() {
    local v=${1:-"9.5"}
    apt-get install -y \
            "postgresql-${v}" \
            "postgresql-client-${v}" \
            "postgresql-contrib-${v}"

    sudo -u postgres createdb datacube
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
    local home_dir=$(eval echo "~${user}")

    echo "Running new user hook: $@"
    add_db_user "${user}" "${role}"

    cat <<EOF | sudo -u "${user}" tee "${home_dir}/.datacube.conf"
[datacube]
db_name: datacube
EOF
}


gen_config() {
    local ec2env="$(which ec2env.py || echo $(pwd)/ec2env.py)"

    local ee="$($ec2env \
               DOMAIN=domain \
               ADMIN_USER=admin \
               EMAIL='ssm:///dev/jupyterhub/email')"
    eval "$ee"

    for x in "${DOMAIN}" "${ADMIN_USER}" "${EMAIL}"; do
        [ -z "$x" ] && return 1
    done

    has_dot "${DOMAIN}" || DOMAIN="${DOMAIN}.dea.gadevs.ga"
    domain_prefix=$(echo "${DOMAIN}" | cut -d . -f 1)

    cat <<EOF
OAUTH_CLIENT_ID=ssm:///dev/jupyterhub/oauth.client.id
OAUTH_CLIENT_SECRET=ssm:///dev/jupyterhub/oauth.client.secret
OAUTH_CALLBACK_URL=ssm:///dev/jupyterhub/oauth.callback.url
OAUTH_CALLBACK_POSTFIX=${domain_prefix}
DOMAIN=${DOMAIN}
ADMIN_USER=${ADMIN_USER}
EMAIL=${EMAIL}
NEW_USER_HOOK=/opt/dea/dea-new-user-hook.sh
EOF

    return 0
}

init_instance() {
    [ -f /etc/jupyterhub/jupyterhub.conf ] && echo "Already configured" && return 0

    if gen_config > /tmp/jupyterhub.conf ; then
        mv /tmp/jupyterhub.conf /etc/jupyterhub/jupyterhub.conf
        systemctl enable update-dns.service jupyterhub.service jupyterhub-proxy.service
        systemctl start update-dns.service jupyterhub.service jupyterhub-proxy.service
    else
        echo "Failed to generate config"
        return 1
    fi
}

revoke_all_certs() {
    find /etc/letsencrypt/live/ -name fullchain.pem | xargs -l1 certbot -n revoke --cert-path
}
