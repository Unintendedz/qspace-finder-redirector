#!/usr/bin/env bash
set -euo pipefail

LABEL="com.local.qspace-finder-redirector"
APP_NAME="QSpace Pro"
APP_BUNDLE_ID="com.jinghaoshe.qspace.pro"
EXTENSION_ID="com.jinghaoshe.qspace.pro.FinderExtension"
SUPPORT_DIR="${HOME}/Library/Application Support/QSpaceFinderRedirector"
BIN_DIR="${HOME}/.local/bin"
AGENT_DIR="${HOME}/Library/LaunchAgents"
LOG_DIR="${HOME}/Library/Logs"
AGENT_PLIST="${AGENT_DIR}/${LABEL}.plist"
REDIRECTOR="${SUPPORT_DIR}/redirector.applescript"
QSPACE_OPEN="${BIN_DIR}/qspace-open"
UID_VALUE="$(id -u)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer supports macOS only." >&2
  exit 1
fi

if ! /usr/bin/osascript -e "id of application \"${APP_NAME}\"" >/dev/null 2>&1; then
  echo "QSpace Pro was not found. Install QSpace Pro first, then rerun this installer." >&2
  exit 1
fi

mkdir -p "${SUPPORT_DIR}" "${BIN_DIR}" "${AGENT_DIR}" "${LOG_DIR}"

cat > "${REDIRECTOR}" <<'APPLESCRIPT'
property pollInterval : 0.35

on run
  repeat
    try
      tell application "Finder"
        set finderWindows to Finder windows
        repeat with finderWindow in finderWindows
          my redirectFinderWindow(finderWindow)
        end repeat
      end tell
    end try
    delay pollInterval
  end repeat
end run

on redirectFinderWindow(finderWindow)
  try
    tell application "Finder"
      set targetAlias to target of finderWindow as alias
      set targetPath to POSIX path of targetAlias
      close finderWindow
    end tell

    set targetUrl to my fileUrlForPath(targetPath)
    tell application "QSpace Pro"
      open urlstr targetUrl
    end tell
    delay 0.15
    tell application "QSpace Pro" to activate
  end try
end redirectFinderWindow

on fileUrlForPath(targetPath)
  set jxa to "function run(argv) { ObjC.import('Foundation'); return $.NSURL.fileURLWithPath(argv[0]).absoluteString.js; }"
  return do shell script "/usr/bin/osascript -l JavaScript -e " & quoted form of jxa & " " & quoted form of targetPath
end fileUrlForPath
APPLESCRIPT

cat > "${QSPACE_OPEN}" <<'SHELL'
#!/usr/bin/env bash
# qspace-finder-redirector managed file
set -euo pipefail

target="${1:-${PWD}}"
if [[ "${target}" != /* ]]; then
  target="${PWD}/${target}"
fi

if [[ ! -e "${target}" ]]; then
  echo "Path does not exist: ${target}" >&2
  exit 1
fi

url=$(/usr/bin/osascript -l JavaScript -e 'function run(argv) { ObjC.import("Foundation"); return $.NSURL.fileURLWithPath(argv[0]).absoluteString.js; }' "${target}")

/usr/bin/osascript - "${url}" <<'APPLESCRIPT'
on run argv
  tell application "QSpace Pro"
    open urlstr (item 1 of argv)
    activate
  end tell
end run
APPLESCRIPT
SHELL

chmod 755 "${QSPACE_OPEN}"

cat > "${AGENT_PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/osascript</string>
    <string>${REDIRECTOR}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/qspace-finder-redirector.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/qspace-finder-redirector.err</string>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "${AGENT_PLIST}" >/dev/null
/usr/bin/pluginkit -e use -i "${EXTENSION_ID}" >/dev/null 2>&1 || true
/bin/launchctl bootout "gui/${UID_VALUE}" "${AGENT_PLIST}" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "gui/${UID_VALUE}" "${AGENT_PLIST}"
/bin/launchctl enable "gui/${UID_VALUE}/${LABEL}" >/dev/null 2>&1 || true

echo "Installed QSpace Finder Redirector."
echo "Try: open ~/Downloads"
echo "Helper command: ${QSPACE_OPEN} ~/Downloads"
echo "macOS may ask for Automation permission for osascript. Approve Finder and QSpace Pro."
