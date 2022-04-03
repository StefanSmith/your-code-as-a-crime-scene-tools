#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

date="${1}"
repositoryDirectoryPath="${2}"

cd "${repositoryDirectoryPath}"
git reset --hard origin/master || git reset --hard origin/main
git reset --hard "$(git log --before="${date}" --pretty=format:%h -1)"
git clean -fdx