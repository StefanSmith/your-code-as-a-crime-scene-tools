#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit
set -m

# Shut down HTTP server
trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT

port=$1
dataFile=$2
url="http://localhost:$port/enclosure-diagram.html?file=./$dataFile"

cd enclosure-diagram
python -m http.server "${port}" &

# Wait for URL to be available
until curl --output /dev/null --silent --head --fail "$url"; do :; done
open "$url"

# Give browser enough time to request URL before shutting down HTTP server
sleep 2