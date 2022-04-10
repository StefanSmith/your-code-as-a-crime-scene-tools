#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrls="${1}"
repositoryPath="${2}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck disable=SC2001
# shellcheck disable=SC2016
"${scriptDirectoryPath}/foreach-repository-url.sh" "${repositoryUrls}" 'echo "$('"${scriptDirectoryPath}/get-repository-path.sh"' "{repoUrl}") => {repoUrl}"' | grep "${repositoryPath}" | sed -r 's/^.+ => ([^\|]+)(\|.+)?$/\1/'
