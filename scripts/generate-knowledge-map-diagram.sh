#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

linesOfCodeReportFilePath="${1}"
mainDevReportFilePath="${2}"
authorColorsFilePath="${3}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

authorColoursAbsoluteFilePath="${scriptDirectoryPath}/../${authorColorsFilePath}"

enclosureDiagramData="$(python "${scriptDirectoryPath}/../maat-scripts/transform/csv_main_dev_as_knowledge_json.py" --structure "${linesOfCodeReportFilePath}" --owners "${mainDevReportFilePath}" --authors "${authorColoursAbsoluteFilePath}")"

uniqueAuthors="$(awk -F',' '{ if (NR!=1) { print $2 } }' "${mainDevReportFilePath}" | sort | uniq)"
grepPattern="$(xargs -I {} printf "{}|" <<< "${uniqueAuthors}" | sed -E 's/(.+)\|/^(\1),/')"
filteredAuthorColours=$(grep -E "${grepPattern}" "${authorColoursAbsoluteFilePath}" || echo)

cat "${scriptDirectoryPath}/../enclosure-diagram/enclosure-diagram-header.html"
echo "<script>var root=${enclosureDiagramData};</script>"
echo "<table><tbody>"

if [ -n "${filteredAuthorColours}" ]; then
  awk -F',' '{ print "<tr><td style=\"background-color:" $2 "\" class=\"authorColorCell\"></td><td>"$1"</td></tr>" }' <<< "${filteredAuthorColours}"
fi

echo "<tr><td style=\"background-color:Black\" class=\"authorColorCell\"></td><td>Other</td></tr>"
echo "</tbody></table>"
cat "${scriptDirectoryPath}/../enclosure-diagram/knowledge-map-diagram-footer.html"