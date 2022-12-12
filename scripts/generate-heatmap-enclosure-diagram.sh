#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePath="${1}"
entityWeightsFilePath="${2}"
weightColumnIndex="${3:-1}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

enclosureDiagramData="$(python "${scriptDirectoryPath}/../maat-scripts/transform/csv_as_enclosure_json.py" --structure "${linesOfCodeReportFilePath}" --weights "${entityWeightsFilePath}" --weightcolumn "${weightColumnIndex}")"

cat "${scriptDirectoryPath}/../enclosure-diagram/enclosure-diagram-header.html"
echo "<script>var root=${enclosureDiagramData};</script>"
cat "${scriptDirectoryPath}/../enclosure-diagram/heatmap-enclosure-diagram-footer.html"