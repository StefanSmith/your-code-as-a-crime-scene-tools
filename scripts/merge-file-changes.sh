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
  # Use sed to collapse multiple empty lines together and then to remove any newlines from the start of the file. maat-scripts does not tolerate new lines in unexpected places
  echo "${fileChangesLogFilePaths}" | xargs -I {}  -S 2048 "${scriptDirectoryPath}/prefix-file-changes-with-repo.sh" "{}" "${analysesDirectoryPath}" "${fileChangesLogFileRelativePath}" | sed -e '/^$/N' -e '/^\n$/D' | sed '/./,$!d'
fi