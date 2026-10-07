import os
import socket
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import discord
from discord import app_commands
from dotenv import load_dotenv

# bot.py と同じフォルダの .env を読む（フォルダを移動しても動くように）
load_dotenv(Path(__file__).resolve().parent / ".env")
TOKEN = os.getenv("DISCORD_TOKEN")

# 二重起動防止：固定ポートを確保できなければ既に起動中とみなす（終了時に自動解放）
LOCK_PORT = 47391
_lock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    _lock.bind(("127.0.0.1", LOCK_PORT))
except OSError:
    print("Botは既に起動しています。終了します。")
    sys.exit(3)  # run_forever.bat はこの番号を見て再起動をやめる

intents = discord.Intents.default()
client = discord.Client(intents=intents)
tree = app_commands.CommandTree(client)


@client.event
async def on_ready():
    await tree.sync()
    print(f"ログイン: {client.user}")


@tree.command(name="purge", description="このチャンネルのメッセージを削除します")
@app_commands.describe(
    count="削除する件数（1〜1000）",
    user="指定したユーザーのメッセージだけ削除（省略可）",
)
@app_commands.default_permissions(manage_messages=True)
@app_commands.checks.has_permissions(manage_messages=True)
async def purge(
    interaction: discord.Interaction,
    count: app_commands.Range[int, 1, 1000],
    user: discord.User | None = None,
):
    await interaction.response.defer(ephemeral=True)

    def check(m: discord.Message) -> bool:
        return user is None or m.author.id == user.id

    # 14日より古いメッセージは一括削除できないため個別削除になる（遅い）
    deleted = await interaction.channel.purge(limit=count, check=check, bulk=True)
    await interaction.followup.send(f"{len(deleted)} 件削除しました。", ephemeral=True)


@tree.command(name="purge_all", description="このチャンネルの直近14日以内のメッセージを全削除します")
@app_commands.default_permissions(manage_messages=True)
@app_commands.checks.has_permissions(manage_messages=True)
async def purge_all(interaction: discord.Interaction):
    await interaction.response.defer(ephemeral=True)
    after = datetime.now(timezone.utc) - timedelta(days=14)
    deleted = await interaction.channel.purge(limit=None, after=after)
    await interaction.followup.send(f"{len(deleted)} 件削除しました。", ephemeral=True)


@tree.error
async def on_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    original = getattr(error, "original", error)
    if isinstance(error, app_commands.MissingPermissions):
        msg = "権限がありません（メッセージの管理が必要）。"
    elif isinstance(original, discord.Forbidden):
        msg = ("Botにこのチャンネルの権限がありません。\n"
               "チャンネルの設定 → 権限 で、Botのロールに「チャンネルを見る」"
               "「メッセージの管理」「メッセージ履歴を読む」を許可してください。")
    else:
        msg = f"エラー: {original}"
    if interaction.response.is_done():
        await interaction.followup.send(msg, ephemeral=True)
    else:
        await interaction.response.send_message(msg, ephemeral=True)


client.run(TOKEN)
