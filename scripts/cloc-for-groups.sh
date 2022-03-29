#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

targetDirectory="$1"
gitCommitHash="$2"
langs="$3"
groupsExpression="$4"

cd "${targetDirectory}"
git reset --hard "${gitCommitHash}" >/dev/null 2>&1

echo "language,filename,blank,comment,code"

while IFS=';' read -ra ADDR; do
  for i in "${ADDR[@]}"; do

    # xargs used to trim whitespace (by default, xargs uses echo and treats whitespace as delimiters)
    groupName="$(xargs <<< "${i##*=>}")"
    relativePath="$(xargs <<< "${i%=>*}")"

    # TODO: Support regex instead of relative path
    cloc ./ --by-file --csv --quiet --include-lang="${langs}" --fullpath --match-f="^./${relativePath}/" | (grep ^SUM || echo 'SUM,,0,0,0') | sed "s/^SUM,,/SUM,${groupName},/" | grep -v ",0,0,0" || true

  done
done <<< "${groupsExpression}"

