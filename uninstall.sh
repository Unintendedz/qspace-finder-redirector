#!/usr/bin/env bash
set -euo pipefail

LABEL="com.local.qspace-finder-redirector"
SUPPORT_DIR="${HOME}/Library/Application Support/QSpaceFinderRedirector"
BIN_DIR="${HOME}/.local/bin"
AGENT_PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
QSPACE_OPEN="${BIN_DIR}/qspace-open"
UID_VALUE="$(id -u)"

/bin/launchctl bootout "gui/${UID_VALUE}" "${AGENT_PLIST}" >/dev/null 2>&1 || true
rm -f "${AGENT_PLIST}"
rm -rf "${SUPPORT_DIR}"

if [[ -f "${QSPACE_OPEN}" ]] && /usr/bin/grep -q "qspace-finder-redirector managed file" "${QSPACE_OPEN}"; then
  rm -f "${QSPACE_OPEN}"
fi

echo "Uninstalled QSpace Finder Redirector."
