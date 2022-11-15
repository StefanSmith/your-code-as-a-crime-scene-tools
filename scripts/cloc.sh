#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit
targetDirectory="$1"

# shellcheck disable=SC2001
parameters="$(sed 's/::::/\n/g' <<< "$2")"

langs="$(sed -n 1p <<< "${parameters}" | xargs)"
groupsExpression="$(sed -n 2p <<< "${parameters}" | xargs)"

cd "${targetDirectory}"

clocCommand=(cloc ./ --by-file --csv --quiet "--include-lang=${langs}")

clocStderrFile=$(mktemp)

if [ -z "${groupsExpression:-}" ]; then
  clocStdout=$("${clocCommand[@]}" 2>"${clocStderrFile}")
else
  echo "language,filename,blank,comment,code"

  while IFS=';' read -ra ADDR; do
    for i in "${ADDR[@]}"; do

      # xargs used to trim whitespace (by default, xargs uses echo and treats whitespace as delimiters)
      groupName="$(xargs <<< "${i##*=>}")"
      relativePath="$(xargs <<< "${i%=>*}")"

      # TODO: Support regex instead of relative path
      clocStdout="$("${clocCommand[@]}" --fullpath --match-f="^./${relativePath}/" 2>"${clocStderrFile}" | (grep ^SUM || echo 'SUM,,0,0,0') | sed "s/^SUM,,/SUM,${groupName},/" | grep -v ",0,0,0" || true)"
    done
  done <<< "${groupsExpression}"

fi

clocStderr="$(<"${clocStderrFile}")"

if [ -n "${clocStderr}" ]; then
  echo "Aborting because cloc reported the following error when analysing ${targetDirectory}: ${clocStderr}" >&2
  exit 1
fi

if [ -z "${clocStdout}" ]; then
  printf "\nlanguage,filename,blank,comment,code\nSUM,,0,0,0"
fi

echo "${clocStdout}"