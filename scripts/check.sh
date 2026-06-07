#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "${ROOT}/install.sh" "${ROOT}/uninstall.sh" "${ROOT}/scripts/qspace-open"

if command -v osacompile >/dev/null 2>&1; then
  osacompile -o /tmp/qspace-finder-redirector.scpt "${ROOT}/scripts/redirector.applescript"
  rm -f /tmp/qspace-finder-redirector.scpt
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${ROOT}/install.sh" "${ROOT}/uninstall.sh" "${ROOT}/scripts/qspace-open"
fi

if grep -RInE '(/Users/[^ ]+|gho_[A-Za-z0-9_]+|BEGIN (RSA|OPENSSH|PRIVATE) KEY)' \
  --exclude-dir=.git \
  --exclude=check.sh \
  "${ROOT}"; then
  echo "Sensitive local material detected." >&2
  exit 1
fi

echo "Checks passed."
