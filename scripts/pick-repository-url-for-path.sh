#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrls="${1}"
repositoryPath="${2}"

# shellcheck disable=SC2001
# shellcheck disable=SC2016
sed 's/ *; */\n/g' <<< "${repositoryUrls}" | sort | xargs -I {} bash -c 'echo "$(scripts/get-repository-path.sh '\''{}'\'')|{}"' | grep "^${repositoryPath}|" | sed -r 's/^.+\|(.+)$/\1/'