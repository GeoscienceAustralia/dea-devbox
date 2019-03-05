#!/bin/bash

set -e

s3_fetch_config () {
    aws s3 cp s3://dea-devbox-config/SSL/letsencrypt.tgz.gpg - | \
      gpg --batch --passphrase "$P" --decrypt 2> /dev/null | \
         (cd /etc && tar xzv)
}

s3_backup_config () {
    local F="/tmp/letsencrypt-$(date -I).tgz.gpg"
    (cd /etc && tar cz letsencrypt) | \
        gpg --batch --passphrase "$P" --symmetric --output "$F"

    aws s3 cp "$F" "s3://dea-devbox-config/SSL/${F}"
    aws s3 cp "$F" "s3://dea-devbox-config/SSL/letsencrypt.tgz.gpg"
}

s3_upload_certs () {
    (cd /etc/letsencrypt/live/ && tar cz --dereference .) | \
      gpg --batch --passphrase "$P" --symmetric | \
        aws s3 cp - s3://dea-devbox-config/SSL/certs.tgz.gpg
}

run_renew () {
    certbot -n renew --no-directory-hooks --deploy-hook "$0 deploy"
}

cmd=${1:-help}

case "$cmd" in
    help)
        echo "Usage: dea-ssl fetch|backup|upload|renew"
    ;;

    fetch)
        eval $(dea-tool ec2env P=ssm:///dev/devbox/key)
        s3_fetch_config
    ;;

    backup)
        eval $(dea-tool ec2env P=ssm:///dev/devbox/key)
        s3_backup_config
    ;;

    upload)
        eval $(dea-tool ec2env P=ssm:///dev/devbox/key)
        s3_upload_certs
    ;;

    deploy)
        eval $(dea-tool ec2env P=ssm:///dev/devbox/key)
        s3_upload_certs
        s3_backup_config
    ;;

    renew)
        run_renew
    ;;

    *)
        echo "Unknown command: $1"
        exit 1
esac
