#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrl="${1}"

awk -F "|" '{ print $2 }' <<< "${repositoryUrl}"