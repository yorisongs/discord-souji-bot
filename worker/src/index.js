// 掃除Bot（Cloudflare Workers版）
// Discord からのスラッシュコマンドを HTTP で受け取り、メッセージを削除する

const API = "https://discord.com/api/v10";
const MANAGE_MESSAGES = 1n << 13n;
const FOURTEEN_DAYS = 14 * 24 * 60 * 60 * 1000;
const DISCORD_EPOCH = 1420070400000n;

export default {
  async fetch(request, env, ctx) {
    if (request.method !== "POST") return new Response("掃除Bot is running");

    const body = await request.text();
    if (!(await verify(request, body, env.DISCORD_PUBLIC_KEY))) {
      return new Response("invalid signature", { status: 401 });
    }

    const interaction = JSON.parse(body);

    // PING（Developer Portal でURLを登録するときの確認）
    if (interaction.type === 1) return json({ type: 1 });

    // スラッシュコマンド
    if (interaction.type === 2) {
      const perms = BigInt(interaction.member?.permissions ?? 0);
      if (!(perms & MANAGE_MESSAGES)) {
        return json({ type: 4, data: { content: "権限がありません（メッセージの管理が必要）。", flags: 64 } });
      }
      // 3秒以内に「考え中…」を返し、削除は裏で続ける
      ctx.waitUntil(run(interaction, env).catch((e) => followup(interaction, `エラー: ${e.message}`)));
      return json({ type: 5, data: { flags: 64 } });
    }

    return new Response("unknown interaction", { status: 400 });
  },
};

async function run(interaction, env) {
  const { name, options = [] } = interaction.data;
  const opt = Object.fromEntries(options.map((o) => [o.name, o.value]));
  const channelId = interaction.channel_id;

  let deleted;
  if (name === "purge") {
    deleted = await purge(env, channelId, { limit: opt.count, userId: opt.user, onlyRecent: false });
  } else if (name === "purge_all") {
    deleted = await purge(env, channelId, { limit: 1000, onlyRecent: true });
  } else {
    return followup(interaction, "不明なコマンドです。");
  }
  await followup(interaction, `${deleted} 件削除しました。`);
}

// メッセージを新しい順に取得して削除する
async function purge(env, channelId, { limit, userId, onlyRecent }) {
  const now = Date.now();
  let before;
  let scanned = 0;
  const recent = [];
  const old = [];

  while (scanned < limit) {
    const n = Math.min(100, limit - scanned);
    const q = `limit=${n}` + (before ? `&before=${before}` : "");
    const msgs = await discord(env, "GET", `/channels/${channelId}/messages?${q}`);
    if (msgs.length === 0) break;
    scanned += msgs.length;
    before = msgs[msgs.length - 1].id;

    let reachedOld = false;
    for (const m of msgs) {
      if (userId && m.author.id !== userId) continue;
      if (now - snowflakeTime(m.id) < FOURTEEN_DAYS - 60_000) recent.push(m.id);
      else if (onlyRecent) reachedOld = true;
      else old.push(m.id);
    }
    if (reachedOld || msgs.length < n) break;
  }

  // 14日以内はまとめて削除（100件ずつ）
  for (let i = 0; i < recent.length; i += 100) {
    const chunk = recent.slice(i, i + 100);
    if (chunk.length === 1) await discord(env, "DELETE", `/channels/${channelId}/messages/${chunk[0]}`);
    else await discord(env, "POST", `/channels/${channelId}/messages/bulk-delete`, { messages: chunk });
  }
  // 14日より古いものは1件ずつ（無料プランの制限で最大30件まで）
  const oldTargets = old.slice(0, 30);
  for (const id of oldTargets) {
    await discord(env, "DELETE", `/channels/${channelId}/messages/${id}`);
  }
  return recent.length + oldTargets.length;
}

async function discord(env, method, path, body) {
  for (let attempt = 0; attempt < 3; attempt++) {
    const res = await fetch(API + path, {
      method,
      headers: {
        Authorization: `Bot ${env.DISCORD_TOKEN}`,
        ...(body && { "Content-Type": "application/json" }),
      },
      body: body && JSON.stringify(body),
    });
    if (res.status === 429) {
      const { retry_after = 1 } = await res.json();
      await new Promise((r) => setTimeout(r, retry_after * 1000));
      continue;
    }
    if (res.status === 403) throw new Error("Botにこのチャンネルの権限がありません（チャンネルを見る／メッセージの管理／メッセージ履歴を読む）。");
    if (!res.ok) throw new Error(`Discord API ${res.status}: ${await res.text()}`);
    return res.status === 204 ? null : res.json();
  }
  throw new Error("Discordの回数制限にかかりました。少し待ってから再実行してください。");
}

function followup(interaction, content) {
  return fetch(`${API}/webhooks/${interaction.application_id}/${interaction.token}/messages/@original`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ content }),
  });
}

async function verify(request, body, publicKey) {
  const sig = request.headers.get("X-Signature-Ed25519");
  const ts = request.headers.get("X-Signature-Timestamp");
  if (!sig || !ts || !publicKey) return false;
  const key = await crypto.subtle.importKey("raw", hex(publicKey), { name: "Ed25519" }, false, ["verify"]);
  return crypto.subtle.verify("Ed25519", key, hex(sig), new TextEncoder().encode(ts + body));
}

function hex(s) {
  return new Uint8Array(s.match(/../g).map((b) => parseInt(b, 16)));
}

function snowflakeTime(id) {
  return Number((BigInt(id) >> 22n) + DISCORD_EPOCH);
}

function json(obj) {
  return new Response(JSON.stringify(obj), { headers: { "Content-Type": "application/json" } });
}
