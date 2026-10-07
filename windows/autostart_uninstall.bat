@echo off
rem 自動起動を解除し、裏で動いているBotを止める
chcp 65001 > nul
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\discord-souji-bot.vbs" 2> nul
call "%~dp0stop.bat" nowait
echo 自動起動を解除しました。
pause
