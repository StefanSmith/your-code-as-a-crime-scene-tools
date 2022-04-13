#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryPath="${1}"
groupsExpression="${2}"

while IFS=';' read -ra ADDR; do
  for i in "${ADDR[@]}"; do

    # xargs used to trim whitespace (by default, xargs uses echo and treats whitespace as delimiters)
    groupName="$(xargs <<< "${i##*=>}")"
    relativePath="$(xargs <<< "${i%=>*}")"

    if [ "${relativePath}" == "${repositoryPath}" ]; then
      echo "${groupName}"
      exit
    fi

  done
done <<< "${groupsExpression}"

echo "No matching group found for repository path '${repositoryPath}'"
exit 1