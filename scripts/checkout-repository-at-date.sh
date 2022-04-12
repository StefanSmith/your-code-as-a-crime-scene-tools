#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

date="${1}"
repositoryDirectoryPath="${2}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${repositoryDirectoryPath}"
lastCommitHashBeforeDate="$(git log "$("${scriptDirectoryPath}/get-repository-mainline-branch-name.sh" "${repositoryDirectoryPath}")" --before="${date}" --pretty=format:%h -1)"
git reset --hard "${lastCommitHashBeforeDate}"
git clean -fdx