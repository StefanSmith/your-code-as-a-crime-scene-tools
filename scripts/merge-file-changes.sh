#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

fileChangesLogFilePathsString="${1}"
analysesDirectoryPath="${2}"
fileChangesLogFileRelativePath="${3}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

fileChangesLogFilePaths="$(echo "${fileChangesLogFilePathsString}" | tr ' ' '\n')"

if [ "$(echo "${fileChangesLogFilePaths}" | wc -l)" -eq 1 ]; then
  cat "${fileChangesLogFilePaths}"
else
  echo "${fileChangesLogFilePaths}" | xargs -I {} "${scriptDirectoryPath}/prefix-file-changes-with-repo.sh" "{}" "${analysesDirectoryPath}" "${fileChangesLogFileRelativePath}"
fi