#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryTableFilePath="${1}"
fullyQualifiedRepoNames="${2}"

if [ "${fullyQualifiedRepoNames}" == "true" ]; then
  # shellcheck disable=SC2016
  outputFormat='$2'
else
  # shellcheck disable=SC2016
  outputFormat='$3'
fi

awk -F ',' '{ print $5 " => " $4 '"${outputFormat}"' ";" }' "${repositoryTableFilePath}"