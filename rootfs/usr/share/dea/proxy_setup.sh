#!/bin/bash

dns_wait () {
    local domain=$1
    jhub-vhost dns --no-update $domain && return 0

    for s in 30 30 60 180; do
        echo "Not yet ${domain}, sleeping ${s}"
        sleep "${s}"
        jhub-vhost dns --no-update $domain && return 0
    done

    echo "Giving up: ${domain}"
    return 1
}

dns_wait $DOMAIN && exec jhub-vhost add --email $EMAIL --skip-dns-check $DOMAIN
