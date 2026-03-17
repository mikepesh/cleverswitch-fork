#!/bin/bash

# 1. Define variables
APP_NAME="cleverswitch"
PLIST_LABEL="com.user.$APP_NAME"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

# 2. Resolve the venv binary path (same as setup.sh computes)
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VENV_DIR="$PROJECT_DIR/.venv"
BINARY_PATH="$VENV_DIR/bin/$APP_NAME"

if [ ! -x "$BINARY_PATH" ]; then
    echo "Error: $APP_NAME not found at $BINARY_PATH"
    echo "Please run setup.sh first to install into the venv."
    exit 1
fi

echo "Found $APP_NAME at: $BINARY_PATH"

# 3. Unload any running instance first
launchctl bootout "gui/$(id -u)/$PLIST_LABEL" 2>/dev/null
launchctl unload "$PLIST_PATH" 2>/dev/null

# 4. Create the Launch Agent .plist file
cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/$APP_NAME.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/$APP_NAME.err.log</string>
    <key>ThrottleInterval</key>
    <integer>5</integer>
</dict>
</plist>
EOF

# 5. Set correct permissions
chmod 644 "$PLIST_PATH"

# 6. Load the agent
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || launchctl load "$PLIST_PATH"

echo ""
echo "Successfully installed and started $APP_NAME startup agent."
echo "  Binary:  $BINARY_PATH"
echo "  Plist:   $PLIST_PATH"
echo "  Logs:    /tmp/$APP_NAME.out.log  /tmp/$APP_NAME.err.log"
echo ""
echo "NOTE: The daemon needs Input Monitoring and Accessibility permissions."
echo "  If it fails, go to System Settings → Privacy & Security and add:"
echo "  $(readlink -f "$VENV_DIR/bin/python3" 2>/dev/null || echo "$VENV_DIR/bin/python3")"
