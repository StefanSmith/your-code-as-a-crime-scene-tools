#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePathsString="${1}"
analysesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

linesOfCodeReportFilePaths="$(echo "${linesOfCodeReportFilePathsString}" | tr ' ' '\n')"

if [ "$(echo "${linesOfCodeReportFilePaths}" | wc -l)" -eq 1 ]; then
  grep -v "^SUM" "${linesOfCodeReportFilePaths}"
else
  printf "language,filename,blank,comment,code,\n%s" "$(echo "${linesOfCodeReportFilePaths}" | xargs -I {}  -S 2048 "${scriptDirectoryPath}/prefix-lines-of-code-report-with-repo.sh" "{}" "${analysesDirectoryPath}" "${linesOfCodeReportFileRelativePath}" | grep -v -e "^language,filename,blank,comment,code," -e "^SUM")"
fi