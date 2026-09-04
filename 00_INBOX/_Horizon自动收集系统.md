# 📡 Horizon · AI 自动信息收集系统

> **定位:知识库的"雷达"——人肉收集(00_INBOX 手动部分)之外的自动化输入源。**
> 仓库:https://github.com/Thysrael/Horizon

Horizon 是一个 AI 驱动的个人新闻雷达:多源抓取 → AI 评分过滤 → 去重 → 补充背景 → 生成中英双语每日简报。正好补上知识库图 1 中"输入层"的自动化一环。

## 🧩 它在整个知识库中的位置

```
┌─ 自动输入(每天自动跑)─────────────┐
│ Horizon 抓取:HN / RSS / Reddit /   │
│ Telegram / Twitter / GitHub /      │
│ OpenBB 金融新闻                    │
│        ↓ AI 评分过滤 + 去重          │
│ 每日简报(飞书/邮件/GitHub Pages)   │
└──────────┬──────────────────────────┘
           ↓ 人工筛一遍(5 min)
     00_INBOX/热点-行业新闻/
           ↓
     01_AI_BRAIN(清洗/分类/沉淀)
           ↓
     02_KNOWLEDGE/选题库 · 商业观察
```

**关键分工:Horizon 负责"广撒网 + 排噪",你只负责"品味筛选"。** 不要试图让 Horizon 直接产出选题——它给的是弹药,选题判断永远留给人。

## 📖 支持的来源

| 来源 | 内容 | 社区评论 |
|---|---|---|
| Hacker News | 首页/Ask/Show HN | ✅ |
| RSS | 任意订阅源 | — |
| Reddit | 指定 subreddit | ✅ |
| Telegram | 公开频道 | — |
| Twitter/X | 关注列表(需 Apify token 或 Playwright+Cookie) | — |
| GitHub | Release / 用户动态 | — |
| OpenBB | 金融新闻 | — |

## 🔥 国内"今日热点"接法(RSSHub)

国内热榜(微博/知乎/B站/抖音/百度)没有官方 RSS,标准做法是自托管 RSSHub 转一层:

| 热榜 | RSSHub 路由 |
|---|---|
| 微博热搜 | `/weibo/search/hot` |
| 知乎热榜 | `/zhihu/hotlist` |
| B站综合排行 | `/bilibili/ranking/0/3/1` |
| 抖音热点 | `/douyin/trending` |
| 百度热搜 | `/baidu/whole` |

自托管 RSSHub(Docker 一条命令):

```bash
docker run -d -p 1200:1200 diygod/rsshub
```

然后在 Horizon 的 RSS 源里填 `http://localhost:1200/weibo/search/hot` 这样的地址即可。

⚠️ **两个坑**:
1. 公共实例(rsshub.app)不稳定,自托管最可靠
2. 全站热榜噪音大(娱乐八卦多),**必须把 AI 评分阈值调高**,只放行与自己定位相关的条目,否则简报会被淹没

## 🇨🇳 推荐源配置(起步 5 源)

先少后多,跑一周看质量再加减:

1. **Hacker News**(海外科技风向)
2. **机器之心**(AI 资讯,RSS)
3. **36氪**(创投商业,RSS)
4. **Reddit r/SideProject**(一人公司选题富矿)
5. **知乎热榜**(经 RSSHub,阈值调高)

可选补充:虎嗅、晚点 LatePost、少数派、即刻热门(均需 RSSHub)、微博热搜(噪音最大,慎加)。

## 🚀 部署(选一种)

### 方式 A:本地运行(推荐起步)
```bash
git clone https://github.com/Thysrael/Horizon.git
cd Horizon
uv sync                      # 或 pip install -e .
cp .env.example .env         # 填 API key
uv run horizon-wizard        # 交互式向导,按兴趣生成 data/config.json
uv run horizon               # 跑一次,生成今日简报
```

### 方式 B:Docker
```bash
docker compose build
docker compose run --rm horizon
```

### 方式 C:GitHub Actions 定时任务(全自动,免费跑)
Fork 仓库 → 配置 Secrets(API key)→ 启用自带的定时 Workflow → 每天自动生成并部署简报。

## 🔑 AI 模型配置

不绑定单一厂商,支持:Claude / GPT / Gemini / DeepSeek / 豆包 / MiniMax / Ollama(本地)。

`config.json` 示例:
```json
{
  "ai": {
    "provider": "deepseek",
    "model": "deepseek-chat",
    "api_key_env": "DEEPSEEK_API_KEY"
  }
}
```

⚠️ `api_key_env` 填的是**环境变量名**,真实 key 放 `.env` 文件,绝不写进 config。

## 📬 交付渠道(简报送到哪)

- **飞书 / 钉钉 / Slack / Discord / 自定义 Webhook**(推荐飞书,手机直接看)
- 邮件(自托管 SMTP)
- GitHub Pages 网站
- MCP Server(可以让 AI 助手直接查询简报)
- 本地 Markdown 文件 → **可直接落到 `00_INBOX/热点-行业新闻/`**

## ✅ 与知识库工作流的接法(每日 5 分钟)

1. **早上**:打开 Horizon 简报(飞书推送或本地文件),只看标题
2. **筛选**:与自己定位相关的条目,复制进 `00_INBOX/热点-行业新闻/` 模板,一句话写"为什么值得记"
3. **触发处理**:在对话里说"处理今天 INBOX 里的热点",AI 走 [[../01_AI_BRAIN/README|AI Brain]] 流程
4. **月末**:看哪类新闻反复出现 → 那是选题库的信号

## ⚙️ Profile(品味层)建议

Horizon 的 profile 决定 AI 如何打分过滤。结合 [[../06_SYSTEM/个人定位|个人定位]] 来写,例如:

- 只保留与"AI + 一人公司 + 内容创业"相关的条目
- 评分阈值设高一点(宁缺毋滥,简报太厚等于没有)
- 开启中文简报 + 背景补充(不熟悉的概念自动查)

## 🔗 相关

- [[README|00_INBOX 总览]]
- [[../06_SYSTEM/每日处理模板|每日处理模板]](早晨收集环节)
- [[../06_SYSTEM/Codex-Prompt|Codex Prompt]](处理素材的 Prompt)

---
*记录:2026-09-02 由小知根据用户提供的仓库整理。*
