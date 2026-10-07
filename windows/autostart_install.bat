@echo off
rem ログイン時にBotを自動起動する設定を登録し、今すぐ裏で起動する
chcp 65001 > nul
set "BOTDIR=%~dp0"

rem Googleドライブの準備ができるまで最大5分待ってから、画面なしで起動するスクリプトを
rem スタートアップに作る（日本語パス対応のためUnicodeで保存）
powershell -NoProfile -Command ^
  "$bat = Join-Path $env:BOTDIR 'run_forever.bat';" ^
  "$vbs = Join-Path ([Environment]::GetFolderPath('Startup')) 'discord-souji-bot.vbs';" ^
  "$code = 'Set sh = CreateObject(\"WScript.Shell\")', 'Set fs = CreateObject(\"Scripting.FileSystemObject\")', ('bat = \"' + $bat + '\"'), 'For i = 1 To 60', '  If fs.FileExists(bat) Then Exit For', '  WScript.Sleep 5000', 'Next', 'sh.Run \"cmd /c \"\"\" & bat & \"\"\"\", 0, False';" ^
  "Set-Content -Path $vbs -Value $code -Encoding Unicode;" ^
  "Start-Process wscript -ArgumentList ('\"' + $vbs + '\"')"

echo 自動起動を登録して、Botを裏で起動しました。
echo 動作ログ: %BOTDIR%..\bot.log
echo フォルダを移動したら、移動先でもう一度このファイルを実行してください。
pause
