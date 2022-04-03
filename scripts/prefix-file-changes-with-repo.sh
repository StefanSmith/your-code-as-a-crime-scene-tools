#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

fileChangesLogFilePath="${1}"
repositoriesDirectoryPath="${2}"
fileChangesLogFileRelativePath="${3}"

repositoryUrl="$(sed -E 's@^'"${repositoriesDirectoryPath}"'/([^/]+)/'"${fileChangesLogFileRelativePath}"'@\1@' <<< "${fileChangesLogFilePath}" | base64 -d)"

filePathPrefix="$(awk -F ":" '{ split($1, sshParts, "@"); split(sshParts[2], hostParts, "."); split($2, repoParts, "/"); split(repoParts[2], repoName, "."); print hostParts[2] "/" hostParts[1] "/" repoParts[1] "/" repoName[1] }' <<< "${repositoryUrl}")"

fileChangesWithPrefix="$(sed -r 's@^([0-9]+\t[0-9]+\t)@\1'"${filePathPrefix}"'/@' "${fileChangesLogFilePath}")"

printf "%s\n\n" "${fileChangesWithPrefix}"