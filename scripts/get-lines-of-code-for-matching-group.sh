#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePath="${1}"
analysesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"
groupsTable="${4}"

repositoryPath="$(sed -E 's@^'"${analysesDirectoryPath}"'/(.+)/'"${linesOfCodeReportFileRelativePath}"'@\1@' <<< "${linesOfCodeReportFilePath}")"
matchedGroupName="$(grep -E "^${repositoryPath}," <<< "${groupsTable}" | cut -d ',' -f2 )"

grep "SUM" "${linesOfCodeReportFilePath}" | sed -r "s|^SUM,,|SUM,${matchedGroupName},|"