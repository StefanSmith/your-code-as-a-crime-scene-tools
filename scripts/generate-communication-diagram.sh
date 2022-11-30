#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

communicationReportFilePath="${1}"

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

communicationDiagramData="$(python "${scriptDirectoryPath}/../maat-scripts/transform/communication_csv_as_edge_bundling.py" --communication "${communicationReportFilePath}")"

cat "${scriptDirectoryPath}/../enclosure-diagram/communication-diagram-header.html"
echo "<script>var classes=${communicationDiagramData};</script>"
cat "${scriptDirectoryPath}/../enclosure-diagram/communication-diagram-footer.html"