#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryDirectoryPath="${1}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${repositoryDirectoryPath}"
git reset --hard "$("${scriptDirectoryPath}/get-repository-mainline-branch-name.sh" "${repositoryDirectoryPath}")"
git clean -fdx