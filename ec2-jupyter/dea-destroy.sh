#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/functions.sh"

revoke_all_certs
