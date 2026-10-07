#!/bin/bash
# Botを一時停止する（自動起動の設定は残る。次回ログイン時にまた起動する）
LABEL="com.yorisongs.discord-souji-bot"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
pkill -f "bot\.py" 2>/dev/null
echo "Botを停止しました。"
read -r -p "Enterで閉じます"
