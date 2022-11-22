#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

fileChangesLogFilePath="${1}"
analysesDirectoryPath="${2}"
fileChangesLogFileRelativePath="${3}"

repositoryPath="$(sed -E 's@^'"${analysesDirectoryPath}"'/(.+)/'"${fileChangesLogFileRelativePath}"'@\1@' <<< "${fileChangesLogFilePath}")"

echo "Prefixing file change log file paths with ${repositoryPath}..." >&2

fileChangesWithPrefix="$(sed -r 's@^((-|[0-9]+)\t(-|[0-9]+)\t)@\1'"${repositoryPath}"'/@' "${fileChangesLogFilePath}")"

printf "%s\n\n" "${fileChangesWithPrefix}"