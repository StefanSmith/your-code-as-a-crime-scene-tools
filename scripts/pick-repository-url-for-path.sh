#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryPath="${1}"
repositoryUrlsToPathsMappingFilePath="${2}"

grep "${repositoryPath}," "${repositoryUrlsToPathsMappingFilePath}" | sed -r 's/^.+,([^\|]+)(\|.+)?$/\1/'
