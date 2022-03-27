#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit
set -m

# Shut down HTTP server
trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT

enclosureDiagramDirectoryRelativePath="../enclosure-diagram"
port=$1
dataFilePath=$2

scriptDirectoryPath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
enclosureDiagramDirectoryRealPath=$(cd -- "${scriptDirectoryPath}/${enclosureDiagramDirectoryRelativePath}" &> /dev/null && pwd)
dataFileRealPath="$(cd -- "$( dirname -- "${dataFilePath}" )" &> /dev/null && pwd)/$( basename  -- "${dataFilePath}")"
# shellcheck disable=SC2001
dataFileHttpPath="$( sed "s#${enclosureDiagramDirectoryRealPath}##" <<< "${dataFileRealPath}" )"

url="http://localhost:$port/enclosure-diagram.html?file=${dataFileHttpPath}"

cd "${enclosureDiagramDirectoryRealPath}"
python -m http.server "${port}" &

# Wait for URL to be available
until curl --output /dev/null --silent --head --fail "$url"; do :; done
open "$url"

# Give browser enough time to request URL before shutting down HTTP server
sleep 2