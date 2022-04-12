#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

date="${1}"
repositoryDirectoryPath="${2}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${repositoryDirectoryPath}"
git reset --hard "$("${scriptDirectoryPath}/get-repository-mainline-branch-name.sh" "${repositoryDirectoryPath}")"
git reset --hard "$(git log --before="${date}" --pretty=format:%h -1)"
git clean -fdx