add_repos(){
    apt-get update
    apt-get install -y --no-install-recommends \
            software-properties-common

    for repo in "$@"; do
        add-apt-repository -y "$repo"
    done
    apt-get update
}

## Common Python
install_common_py() {
    apt-get install -y --no-install-recommends \
            git \
            curl \
            python3 \
            python3-pip

    pip3 install --no-cache pip --upgrade
    pip3 install --no-cache wheel setuptools
    pip3 install --no-cache --upgrade dateutils
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
    local rasterio_version=1.0a12
    export CPLUS_INCLUDE_PATH=/usr/include/gdal
    export C_INCLUDE_PATH=/usr/include/gdal

    apt-get install -y --no-install-recommends\
            gdal-bin \
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

    systemctl enable update-dns
    systemctl enable jupyterhub-proxy

    systemctl start update-dns
    systemctl start jupyterhub-proxy
}
