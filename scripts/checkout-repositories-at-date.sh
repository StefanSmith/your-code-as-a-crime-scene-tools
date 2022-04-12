#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

date="${1}"
repositoryDirectoryPaths="${2}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

tr ' ' '\n' <<< "${repositoryDirectoryPaths}" | xargs -I {}  -S 2048 "${scriptDirectoryPath}/checkout-repository-at-date.sh" "${date}" "{}"