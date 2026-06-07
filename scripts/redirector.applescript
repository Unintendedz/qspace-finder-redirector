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
