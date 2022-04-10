#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrl="${1}"

awk -F "|" '{ split($1, url, ":"); split(url[1], sshParts, "@"); split(sshParts[2], hostParts, "."); split(url[2], repoParts, "/"); split(repoParts[2], repoName, "."); print $2 hostParts[2] "/" hostParts[1] "/" repoParts[1] "/" repoName[1] }' <<< "${repositoryUrl}"