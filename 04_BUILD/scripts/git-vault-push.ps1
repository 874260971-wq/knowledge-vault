# ====================================================================
# git-vault-push.ps1 — vault 手动推送脚本（Windows）
# ====================================================================
# 用途：方案 B 下，vault 仓库已经 git 化、云端日报 Actions 也已配好
#       vault 仓库凭据 —— 但日常偶发"我想立即把本地修改推上去"时，
#       用这个脚本一键 add / commit / push。
#
# 适用：
#   - 早晨 Obsidian 里手改了一些笔记，想立刻同步到远端
#   - 中午新增了内容草稿，想同步
#   - 测试 vault 仓库连接是否正常
#
# 不适用（自动场景）：
#   - obsidian-git 插件已经接管了定时 pull / push
#   - 云端 Horizon 日报通过 Actions 自动推送（无需手动）
#
# 用法（在该 vault 根目录下）：
#   .\04_BUILD\scripts\git-vault-push.ps1                    # 默认 origin / main
#   .\04_BUILD\scripts\git-vault-push.ps1 -Message "fix typo" # 自定义提交信息
#   .\04_BUILD\scripts\git-vault-push.ps1 -Remote upstream -Branch main
# ====================================================================

[CmdType()]
param(
    [string]$Message = "vault: sync from local",
    [string]$Remote = "origin",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\..")  # 回到 vault 根

# ---------- 1. 检查是否为 git 仓库 ----------
if (-not (Test-Path ".git")) {
    Write-Host "[FATAL] 当前目录不是 git 仓库，请先 git init 并配置 remote。" -ForegroundColor Red
    exit 1
}

# ---------- 2. 检查 remote 是否配置 ----------
$remoteUrl = git remote get-url $Remote 2>$null
if (-not $remoteUrl) {
    Write-Host "[FATAL] remote '$Remote' 未配置。请先 git remote add $Remote <vault-repo-url>" -ForegroundColor Red
    exit 2
}
Write-Host "[INFO] Remote: $Remote -> $remoteUrl" -ForegroundColor Cyan

# ---------- 3. 拉取最新 ----------
Write-Host "[INFO] Pulling latest from $Remote/$Branch ..." -ForegroundColor Cyan
git pull --rebase --autostash $Remote $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] pull 失败（可能没有上游提交，或有冲突）。继续尝试提交本地变更。" -ForegroundColor Yellow
}

# ---------- 4. 检查变更 ----------
$status = git status --porcelain
if (-not $status) {
    Write-Host "[OK] 工作区干净，无需提交。" -ForegroundColor Green
    exit 0
}

Write-Host "[INFO] 检测到以下变更：" -ForegroundColor Cyan
$status | ForEach-Object { Write-Host "  $_" }

# ---------- 5. 提交 ----------
git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FATAL] 提交失败。请检查 git 状态。" -ForegroundColor Red
    exit 3
}

# ---------- 6. 推送 ----------
Write-Host "[INFO] Pushing to $Remote/$Branch ..." -ForegroundColor Cyan
git push $Remote $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FATAL] 推送失败。请检查网络 / 凭据。" -ForegroundColor Red
    exit 4
}

Write-Host "[OK] 已同步到 $Remote/$Branch。" -ForegroundColor Green
exit 0