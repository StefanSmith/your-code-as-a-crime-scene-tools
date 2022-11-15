#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryDirectoryPath="${1}"

cd "${repositoryDirectoryPath}"
head -n1 <<< "$(git symbolic-ref refs/remotes/origin/HEAD | cut -d '/' -f4)"