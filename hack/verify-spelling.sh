#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TOOL_VERSION="v0.3.4"

# cd to the root path
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT}"

# create a temporary directory
TMP_DIR=$(mktemp -d)

# cleanup
exitHandler() (
  echo "Cleaning up..."
  rm -rf "${TMP_DIR}"
)
trap exitHandler EXIT

# perform go get in a temp dir as we are not tracking this version in a go module
# if we do the go get in the repo, it will create / update a go.mod and go.sum
cd "${TMP_DIR}"
GO111MODULE=on GOBIN="${TMP_DIR}" go get "github.com/client9/misspell/cmd/misspell@${TOOL_VERSION}"
export PATH="${TMP_DIR}:${PATH}"
cd "${ROOT}"

# check spelling
RES=0
echo "Checking spelling..."
ERROR_LOG="${TMP_DIR}/errors.log"
git ls-files | grep -v vendor | xargs misspell > "${ERROR_LOG}"
if [[ -s "${ERROR_LOG}" ]]; then
  sed 's/^/error: /' "${ERROR_LOG}" # add 'error' to each line to highlight in e2e status
  echo "Found spelling errors!"
  RES=1
fi
exit "${RES}"
