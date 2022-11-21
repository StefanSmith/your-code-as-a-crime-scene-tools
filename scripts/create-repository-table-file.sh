#! /usr/bin/env bash

set -o pipefail -o nounset -o errexit

repositoryUrls="${1}"

repositoryFilePathsListFilePath=$(mktemp)

# shellcheck disable=SC2001
sed 's/ *; */\n/g' <<< "${repositoryUrls}" | grep -vE '^ *$' | awk -F "|" '{ split($1, url, ":"); split(url[1], sshParts, "@"); split(sshParts[2], hostParts, "."); split(url[2], repoParts, "/"); split(repoParts[2], repoName, "."); print $1 "," hostParts[2] "." hostParts[1] "." repoParts[1] "." repoName[1] "," repoName[1] "," $2 "," $2 hostParts[2] "/" hostParts[1] "/" repoParts[1] "/" repoName[1] }' | sort > "${repositoryFilePathsListFilePath}"

echo "${repositoryFilePathsListFilePath}"