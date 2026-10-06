// スラッシュコマンドを Discord に登録する（コマンド内容を変えたときだけ実行）
// 使い方: node register.mjs   （トークンは親フォルダの .env から読む）
import { fileURLToPath } from "node:url";
import path from "node:path";

const dir = path.dirname(fileURLToPath(import.meta.url));
process.loadEnvFile(path.join(dir, "..", ".env"));

const APP_ID = "1556834422500630658";
const MANAGE_MESSAGES = String(1 << 13);

const commands = [
  {
    name: "purge",
    description: "このチャンネルのメッセージを削除します",
    default_member_permissions: MANAGE_MESSAGES,
    dm_permission: false,
    options: [
      { type: 4, name: "count", description: "削除する件数（1〜1000）", required: true, min_value: 1, max_value: 1000 },
      { type: 6, name: "user", description: "指定したユーザーのメッセージだけ削除（省略可）", required: false },
    ],
  },
  {
    name: "purge_all",
    description: "このチャンネルの直近14日以内のメッセージを全削除します",
    default_member_permissions: MANAGE_MESSAGES,
    dm_permission: false,
  },
];

const res = await fetch(`https://discord.com/api/v10/applications/${APP_ID}/commands`, {
  method: "PUT",
  headers: { Authorization: `Bot ${process.env.DISCORD_TOKEN}`, "Content-Type": "application/json" },
  body: JSON.stringify(commands),
});
console.log(res.ok ? "コマンドを登録しました。" : `失敗: ${res.status} ${await res.text()}`);
