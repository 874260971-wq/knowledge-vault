#!/usr/bin/env bash
# ============================================================
# 同步 vault —— 一键把本地知识库推送到 GitHub 私有仓库
# ------------------------------------------------------------
# 用法(在 Git Bash 里运行):
#     bash "E:/知识库自生长/知识库自生长/06_SYSTEM/同步vault.sh"
#
# 前提:
#   1. 已切手机热点(家用 WiFi 透明代理会封 git 443/掐 SSH 长连接)
#   2. SSH 私钥已存在: ~/.ssh/horizon_deploy_ed25519
#
# 做的事:
#   暂存全部改动 → 提交(带当天日期) → 走 SSH 推送到 knowledge-vault
# ============================================================
set -u

VAULT_DIR="E:/知识库自生长/知识库自生长"
KEY="$HOME/.ssh/horizon_deploy_ed25519"
REMOTE_SSH="git@github.com:874260971-wq/knowledge-vault.git"
SSH_OPTS="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no"

# --- 前置检查 ---
cd "$VAULT_DIR" || { echo "[错误] 进不去 vault 目录: $VAULT_DIR"; exit 1; }
[ -f "$KEY" ] || { echo "[错误] 缺 SSH 私钥: $KEY"; exit 1; }

# --- 1/4 暂存 ---
echo "▶ [1/4] 暂存所有改动..."
git add -A

# --- 2/4 提交 ---
echo "▶ [2/4] 提交(带日期)..."
if git diff --cached --quiet; then
  echo "  · 没有可提交的改动，跳过 commit"
else
  git commit -m "sync: vault update $(date +%F)"
fi

# --- 3/4 先拉取(尽力而为，减少推送被拒) ---
echo "▶ [3/4] 拉取云端(SSH)..."
GIT_SSH_COMMAND="$SSH_OPTS" git pull --ff-only "$REMOTE_SSH" main 2>&1 | tail -5 || \
  echo "  · pull 未成功(可能无新提交或网络不稳)，继续尝试 push"

# --- 4/4 推送 ---
echo "▶ [4/4] 推送(SSH)..."
GIT_SSH_COMMAND="$SSH_OPTS" git push "$REMOTE_SSH" main

echo ""
echo "✅ 同步完成"
