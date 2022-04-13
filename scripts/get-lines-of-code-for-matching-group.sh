#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePath="${1}"
analysesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"
groupsExpression="${4}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

repositoryPath="$(sed -E 's@^'"${analysesDirectoryPath}"'/(.+)/'"${linesOfCodeReportFileRelativePath}"'@\1@' <<< "${linesOfCodeReportFilePath}")"
matchedGroupName="$("${scriptDirectoryPath}/get-group-name-for-repository-path.sh" "${repositoryPath}" "${groupsExpression}")"

grep "SUM" "${linesOfCodeReportFilePath}" | sed -r "s|^SUM,,|SUM,${matchedGroupName},|"