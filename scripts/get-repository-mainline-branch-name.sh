#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryDirectoryPath="${1}"

cd "${repositoryDirectoryPath}"
head -n1 <<< "$(git branch -r | grep -o '\borigin/main$' || git branch -r | grep -o '\borigin/master$' || git branch -r | grep -o '\borigin/develop$')"