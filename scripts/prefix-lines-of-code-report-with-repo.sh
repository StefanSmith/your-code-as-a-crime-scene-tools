#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePath="${1}"
repositoriesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"

repositoryUrl="$(sed -E 's@^'"${repositoriesDirectoryPath}"'/([^/]+)/'"${linesOfCodeReportFileRelativePath}"'@\1@' <<< "${linesOfCodeReportFilePath}" | base64 -d)"

filePathPrefix="$(awk -F ":" '{ split($1, sshParts, "@"); split(sshParts[2], hostParts, "."); split($2, repoParts, "/"); split(repoParts[2], repoName, "."); print hostParts[2] "/" hostParts[1] "/" repoParts[1] "/" repoName[1] }' <<< "${repositoryUrl}")"

linesOfCodeReportWithPrefix="$(sed -r 's@^([^,]+,)\.@\1'"${filePathPrefix}"'@' "${linesOfCodeReportFilePath}")"

echo "${linesOfCodeReportWithPrefix}" | grep -v '^$'