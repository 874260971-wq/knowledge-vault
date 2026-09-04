# Vault Git 化方案（方案 B）— 实施文档

> 目标：把"Mac 同步脚本 + 私有仓库凭据 + 终端机拉取"这一长串脆弱链路  
> 压缩成"云端直推 vault + Obsidian 自动拉取"的两端闭环。

---

## 一、架构对比

[874260971-wq/knowledge-vault](https://github.com/874260971-wq/knowledge-vault)



核心收益：

- 终端机零凭据（不在本机存任何 GitHub token）
- 知识库获得版本控制 + 跨设备同步 + 误删可回滚
- 日报生成与本地知识库之间只隔一个 `git pull`

---

## 二、本次已完成的工作（我这边做完了）

| 文件                                                            | 作用                                                     |
| ------------------------------------------------------------- | ------------------------------------------------------ |
| `E:\知识库自生长\知识库自生长\.gitignore`                                 | vault 标准 gitignore，忽略 .obsidian 缓存、.workbuddy/、OS 临时文件 |
| `E:\知识库自生长\知识库自生长\04_BUILD\scripts\git-vault-push.ps1`        | Windows 手动推送脚本（obsidian-git 已接管定时后，留作应急）               |
| `E:\知识库自生长\Horizon\.github\workflows\daily-summary-vault.yml` | 云端日报 Actions 增强版：生成日报后直接 push 到 vault 仓库               |

⚠️ 注意：

- `.gitignore` 已写好但 **还没执行 `git init`**，等你在 GitHub 建好仓库后再 init
- `daily-summary-vault.yml` 是新文件，**还没有替换原 `daily-summary.yml.disabled`**，等你配好 vault 仓库凭据后再启用

---

## 三、需要你操作的 3 步（按顺序）

### 第 1 步 · 建 vault 仓库（5 分钟）

1. GitHub 上新建一个 **私有**仓库，建议命名 `knowledge-vault`（或你喜欢的名字）
2. 仓库设置：
   - Visibility: Private
   - 不要勾选 "Add a README file"（避免初始文件冲突）
   - 不要选 .gitignore / license
3. 记下仓库 URL，类似 `https://github.com/874260971-wq/knowledge-vault`

### 第 2 步 · vault 本地初始化（5 分钟）

在 vault 根目录 `E:\知识库自生长\知识库自生长\` 打开 Git Bash 或 PowerShell：

```bash
# 1. 初始化
git init
git checkout -b main 2>/dev/null || git branch -M main

# 2. 配置 remote
git remote add origin https://github.com/874260971-wq/knowledge-vault.git
# ↑ 把 874260971-wq/knowledge-vault 替换成你第 1 步建的仓库 URL

# 3. 首次提交 + 推送
git add -A
git commit -m "vault: initial commit"
git push -u origin main
```

推送时如果弹凭据框，填 GitHub 用户名 + 一个能写仓库的 PAT（Password 用 PAT）。

### 第 3 步 · 三处收尾（10 分钟）

**a) 云端仓库 `zhengxn1/horizon-ai-daily` 配置 Secrets（跨账号场景）：**

> ⚠️ **跨账号**：vault 仓库在 `874260971-wq` 账号下，Horizon 仓库仍在 `zhengxn1` 账号下 —— 跨账号 push 完全合法，但 `VAULT_REPO_PAT` **必须从 vault 仓库所在的 `874260971-wq` 账号生成**（不能用 zhengxn1 的 PAT）。

Settings → Secrets and variables → Actions → New repository secret，依次添加：

| Secret 名           | 值                                             | 说明                                      |
| ------------------ | --------------------------------------------- | --------------------------------------- |
| `VAULT_REPO_URL`   | `https://github.com/874260971-wq/knowledge-vault` | 第 1 步建的 vault 仓库                        |
| `VAULT_REPO_PAT`   | `<你的 GitHub PAT>`                             | 必须勾选 `repo` scope，强烈建议只授予 vault 仓库的写入权限 |
| `OPENAI_API_KEY` 等 | 已有就保留，缺失就补                                    | Horizon 调用 AI 模型所需                      |

PAT 创建方法：GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens → 选 vault 仓库 + `Contents: Read and Write`。

**b) 把新 workflow 启用，替换旧的：**

进入 `E:\知识库自生长\Horizon\.github\workflows\` 目录：

```bash
# 把新文件作为正式启用版
mv daily-summary-vault.yml daily-summary.yml

# 旧的 disabled 版本留作参考或删除
rm daily-summary.yml.disabled  # 或保留作为历史
```

**c) Obsidian 装 obsidian-git 插件：**

1. Obsidian → Settings → Community plugins → Browse
2. 搜索 `obsidian-git`，安装并启用
3. 插件设置里：
   - **Vault backup folder**: 留空（用 vault 根目录）
   - **Auto pull on startup**: ✅ 打开
   - **Auto pull interval**: 5 分钟（够用，又不打扰）
   - **Commit message**: `vault: {{date}} {{hostname}}` 之类
   - **Pull before commit**: ✅ 打开
4. 点左侧 Ribbon 上的 "Open git source control" 按钮，确认能看到 commit 历史

---

## 四、验收

完成上面 3 步后，第二天早上做这 3 件事验证链路打通：

1. **看云端是否跑了**：打开 `zhengxn1/horizon-ai-daily` 的 Actions 页面，应该看到绿色 ✅ 的 `Daily Horizon Summary → Vault` 任务
2. **看 vault 仓库是否收到**：打开 `874260971-wq/knowledge-vault`，`00_INBOX/热点-行业新闻/` 下应该有当天的 `YYYY-MM-DD.md`
3. **看 Obsidian 是否拉到**：启动 Obsidian（或手动点 obsidian-git 的 Pull），左侧文件列表里出现当天的日报

任意一步不通过，按对应链路反向排查（凭据 / 文件名 / 网络）。

---

## 五、故障排查速查

| 现象                               | 大概率原因                                       | 修复                                                                    |
| -------------------------------- | ------------------------------------------- | --------------------------------------------------------------------- |
| Actions 跑失败，日志 "Bad credentials" | `VAULT_REPO_PAT` 无效或过期                      | 重新生成 PAT，更新 Secret                                                    |
| Actions 跑失败，"没有找到 $DATE 的日报文件"   | Horizon 实际输出文件名不是 `docs/${DATE}.md`         | 先手动跑一次 `uv run horizon --hours 24`，看 `docs/` 下实际生成的文件名，调整 yml 里 cp 那行 |
| Actions 成功但 vault 仓库没有新文件        | commit hook / branch protection 拒绝了空 commit | 检查 vault 仓库 Settings → Branches → Branch protection rules             |
| Obsidian 没拉到                     | obsidian-git 插件未启用 / 凭据未配                   | 插件设置里检查 Authorization，可在终端跑 `git pull` 测试                             |
| 推送时弹凭据框且反复失败                     | PAT 没存进凭据管理器                                | Windows：`git config --global credential.helper manager` 后重试           |

---

## 六、回滚方案

如果方案 B 跑不起来想退回方案 A（旧脚本），恢复路径：

1. 把 `daily-summary.yml` 改回 `daily-summary-vault.yml.disabled`
2. 把 `daily-summary.yml.disabled` 改回 `daily-summary.yml.disabled`（即保持原状）
3. vault 仓库保留也行（不影响 Obsidian 本地使用，只是失去了云端自动同步）

---

*最后更新：2026-09-03 by 小知*
