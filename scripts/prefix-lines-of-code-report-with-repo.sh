#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePath="${1}"
analysesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"

repositoryPath="$(sed -E 's@^'"${analysesDirectoryPath}"'/(.+)/'"${linesOfCodeReportFileRelativePath}"'@\1@' <<< "${linesOfCodeReportFilePath}")"

linesOfCodeReportWithPrefix="$(sed -r 's@^([^,]+,)\.@\1'"${repositoryPath}"'@' "${linesOfCodeReportFilePath}")"

echo "${linesOfCodeReportWithPrefix}" | grep -v '^$'