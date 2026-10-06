@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo === 1. Cloudflare にログイン（ブラウザが開きます）===
call npx -y wrangler login || goto :err

echo.
echo === 2. 公開キーを登録 ===
echo Developer Portal「一般情報」の「公開キー」を貼り付けて Enter
call npx -y wrangler secret put DISCORD_PUBLIC_KEY || goto :err

echo.
echo === 3. Botトークンを登録 ===
echo Developer Portal「Bot」のトークンを貼り付けて Enter（.env と同じもの）
call npx -y wrangler secret put DISCORD_TOKEN || goto :err

echo.
echo === 4. デプロイ ===
call npx -y wrangler deploy || goto :err

echo.
echo === 5. コマンド登録 ===
node register.mjs || goto :err

echo.
echo 完了！上に表示された https://souji-bot.xxxx.workers.dev のURLを
echo Developer Portal「一般情報」の「インタラクションエンドポイントURL」に貼って保存してください。
pause
exit /b 0

:err
echo.
echo エラーで止まりました。上のメッセージを確認してください。
pause
exit /b 1
