#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrls="${1}"
repositoryUrlScript="${2}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck disable=SC2001
"${scriptDirectoryPath}/parse-repository-urls.sh" "${repositoryUrls}" | xargs -I '{repoUrl}' bash -c "${repositoryUrlScript}"