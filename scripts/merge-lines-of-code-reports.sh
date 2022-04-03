#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePathsString="${1}"
repositoriesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

linesOfCodeReportFilePaths="$(echo "${linesOfCodeReportFilePathsString}" | tr ' ' '\n')"

if [ "$(echo "${linesOfCodeReportFilePaths}" | wc -l)" -eq 1 ]; then
  cat "${linesOfCodeReportFilePaths}"
else
  echo "${linesOfCodeReportFilePaths}" | xargs -I {} "${scriptDirectoryPath}/prefix-lines-of-code-report-with-repo.sh" "{}" "${repositoriesDirectoryPath}" "${linesOfCodeReportFileRelativePath}"
fi