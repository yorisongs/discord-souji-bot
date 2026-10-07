@echo off
rem Keep the bot running in background (restart 10s after crash). Launched by autostart_install.bat
cd /d "%~dp0.."
set PYTHONUTF8=1
python -m pip install -q -r requirements.txt >> bot.log 2>&1

:loop
echo [%date% %time%] start >> bot.log
python -u bot.py >> bot.log 2>&1
if %errorlevel%==3 exit /b 0
echo [%date% %time%] stopped (exit code %errorlevel%), restarting in 10s >> bot.log
timeout /t 10 /nobreak > nul
goto loop
