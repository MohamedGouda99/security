#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python -m pip install -e "${ROOT_DIR}/app[dev]"
ruff check "${ROOT_DIR}/app/src"
mypy "${ROOT_DIR}/app/src"
pytest "${ROOT_DIR}/app/tests"

pushd "${ROOT_DIR}/infra/envs/dev" >/dev/null
terraform fmt -recursive
terraform init -backend=false
terraform validate
popd >/dev/null

checkov -d "${ROOT_DIR}/infra"
opa test "${ROOT_DIR}/policies/opa"