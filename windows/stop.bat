@echo off
rem 裏で動いているBot（再起動ループごと）を止める
chcp 65001 > nul
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'run_forever\.bat|bot\.py' -and $_.ProcessId -ne $PID } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
echo Botを停止しました。（自動起動の設定はそのままです。次回ログイン時にまた起動します）
if not "%1"=="nowait" pause
