#!/bin/bash
# ログイン時にBotを自動起動し、落ちたら自動で再起動する設定を登録して、今すぐ裏で起動する
BOTDIR="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="com.yorisongs.discord-souji-bot"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

cd "$BOTDIR" || exit 1
if [ ! -x .venv/bin/python ]; then
  python3 -m venv .venv || { echo "Python3が見つかりません。https://www.python.org からインストールしてください。"; read -r; exit 1; }
fi
.venv/bin/python -m pip install -q -r requirements.txt

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BOTDIR/.venv/bin/python</string>
    <string>-u</string>
    <string>$BOTDIR/bot.py</string>
  </array>
  <key>WorkingDirectory</key><string>$BOTDIR</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key><string>$BOTDIR/bot.log</string>
  <key>StandardErrorPath</key><string>$BOTDIR/bot.log</string>
  <key>EnvironmentVariables</key>
  <dict><key>PYTHONUTF8</key><string>1</string></dict>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "自動起動を登録して、Botを裏で起動しました。"
echo "動作ログ: $BOTDIR/bot.log"
echo "フォルダを移動したら、移動先でもう一度このファイルを実行してください。"
read -r -p "Enterで閉じます"
