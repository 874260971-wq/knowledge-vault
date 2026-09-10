#!/usr/bin/env bash
# ============================================================
# 同步 vault —— 一键把本地知识库推送到 GitHub 私有仓库
# ------------------------------------------------------------
# 用法(在 Git Bash 里运行):
#     bash "~/sync_vault.sh"
#
# 前提:
#   1. 已切手机热点(家用 WiFi 透明代理会封 git 443/掐 SSH 长连接)
#   2. SSH 私钥已存在: ~/.ssh/horizon_deploy_ed25519
#
# 做的事:
#   暂存全部改动 → 提交(带当天日期) → 走 SSH 推送到 knowledge-vault
#   → fetch 更新 origin/main 引用 → 验证 ahead 数(避免假成功/假阴性)
# ============================================================
set -eu

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

# --- 3/4 推送(SSH)---
echo "▶ [3/4] 推送(SSH)..."
GIT_SSH_COMMAND="$SSH_OPTS" git push "$REMOTE_SSH" main

# --- 4/4 fetch 更新 origin/main + 验证(必须 SSH,否则引用过时)---
echo "▶ [4/4] fetch + 验证推送结果..."
GIT_SSH_COMMAND="$SSH_OPTS" git fetch "$REMOTE_SSH" main:refs/remotes/origin/main 2>/dev/null || {
  echo ""
  echo "⚠️  fetch 失败(SSH 可能被掐),无法验证 ahead/behind"
  echo "    但 push 步骤已成功(exit 0),请到 GitHub 网页端确认"
  exit 1
}
AHEAD=$(git rev-list --left-right --count HEAD...origin/main 2>/dev/null | awk '{print $1}')
if [ "${AHEAD:-0}" = "0" ]; then
  echo ""
  echo "✅ 同步完成(已确认云端无落后)"
else
  echo ""
  echo "⚠️  本地仍领先云端 ${AHEAD} 个提交,推送可能未完整成功"
  echo "    可能原因: 网络被掐(未切热点)/ SSH 私钥无写权限"
  exit 1
fi
