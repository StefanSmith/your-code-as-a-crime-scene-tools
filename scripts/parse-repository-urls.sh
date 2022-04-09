#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrls="${1}"

# shellcheck disable=SC2001
sed 's/ *; */\n/g' <<< "${repositoryUrls}" | grep -vE '^ *$' | sort