#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePathsString="${1}"
analysesDirectoryPath="${2}"
linesOfCodeReportFileRelativePath="${3}"
groupsExpression="${4}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

linesOfCodeReportFilePaths="$(echo "${linesOfCodeReportFilePathsString}" | tr ' ' '\n')"

groupsTable="$(echo "${groupsExpression}" | tr ';' '\n' | sed -E 's/^ ?(.+) \=\> /\1,/')"

printf "language,filename,blank,comment,code,\n%s" "$(echo "${linesOfCodeReportFilePaths}" | xargs -I {}  -S 2048 "${scriptDirectoryPath}/get-lines-of-code-for-matching-group.sh" '{}' "${analysesDirectoryPath}" "${linesOfCodeReportFileRelativePath}" "${groupsTable}")"