#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./functions.sh
source "${DIR}/functions.sh"

new_user_hook "$@"
