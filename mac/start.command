#!/bin/bash
# ダブルクリックでBotを起動する（ターミナルを閉じると止まる）
cd "$(dirname "$0")/.." || exit 1

# 初回だけ専用のPython環境(.venv)を作る
if [ ! -x .venv/bin/python ]; then
  python3 -m venv .venv || { echo "Python3が見つかりません。https://www.python.org からインストールしてください。"; read -r; exit 1; }
fi
.venv/bin/python -m pip install -q -r requirements.txt
.venv/bin/python bot.py
read -r -p "Enterで閉じます"
