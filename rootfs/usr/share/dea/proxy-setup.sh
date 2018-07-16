#!/bin/bash

set -eu

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./functions.sh
source "${DIR}/functions.sh"

[ -z "${DOMAIN}" ] && exit 1
DOMAIN_POSTFIX=$(echo "${DOMAIN}" | cut -d . -f 2-100)
CERTS_DIR=/run/dea/certs

configure_nginx () {
    #generate nginx config
    jinja2 --format ini \
           -D domain="${DOMAIN}" \
           -D certpath="${CERTS_DIR}/${DOMAIN_POSTFIX}" \
           /usr/share/dea/nginx-proxy.conf.jinja2 /dev/null > "/run/dea/${DOMAIN}.conf"

    (cd /etc/nginx/conf.d && ln -sf "/run/dea/${DOMAIN}.conf")
}

[ -d "${CERTS_DIR}" ] || fetch_certs "${CERTS_DIR}"
configure_nginx

systemctl is-active --quiet nginx && systemctl reload nginx
