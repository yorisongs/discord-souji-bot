#!/bin/bash
# 自動起動を解除し、裏で動いているBotを止める
LABEL="com.yorisongs.discord-souji-bot"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
echo "自動起動を解除して、Botを停止しました。"
read -r -p "Enterで閉じます"
