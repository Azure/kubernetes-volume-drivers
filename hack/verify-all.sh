#!/bin/bash

set -euo pipefail

readonly PKG_ROOT=$(git rev-parse --show-toplevel)

${PKG_ROOT}/hack/verify-yamllint.sh
${PKG_ROOT}/hack/verify-spelling.sh
