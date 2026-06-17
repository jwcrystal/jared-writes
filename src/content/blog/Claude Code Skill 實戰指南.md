---
title: Claude Code Skill 怎麼寫才有效？Anthropic 內部實戰整理
description: >-
  從 Anthropic 官方 blog 和 Claude Code 文件整理出的 Skill 實戰指南：如何用資料夾、gotchas、腳本與
  plugin，把重複提示詞變成可分享、可維護的團隊工作知識。
type: publish
status: draft
tags:
  - claude-code
  - skill
  - agent
  - ai-coding
  - context-engineering
  - plugin
  - engineering-practice
source:
  - 'https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills'
  - 'https://code.claude.com/docs/en/skills'
  - 'https://code.claude.com/docs/en/plugins'
related: []
pubDate: 2026-06-13T16:00:00.000Z
updatedDate: 2026-06-13T16:00:00.000Z
---

> 這篇整理自 Anthropic 官方 blog、Claude Code Skills 文件與 Plugins 文件，重點放在 Skill 的設計原則、9 種實戰類型、製作技巧與團隊分發策略。

---

如果你常用 Claude Code，大概會遇到同一個問題：每次開新的 session，都要重新貼一次 coding style、專案規則、測試流程、部署注意事項。

這些內容其實不該每次都靠手動貼上。它們應該被整理成 Claude 能在需要時自動讀取的工作知識。這就是 Claude Code Skill 要解決的問題。

但 Skill 也不是「把提示詞存成 markdown」這麼簡單。Anthropic 內部已經有數百個 skill 在使用，他們的經驗是：真正好用的 Skill，是一個能放腳本、範本、參考資料、gotchas 的資料夾。它的核心不是文件管理，而是 context engineering：在對的時機，把對的資訊餵給模型。

這篇重點回答三個問題：

- Skill 應該怎麼設計？
- 哪些類型的 Skill 最值得做？
- 團隊要怎麼把 Skill 從個人技巧變成可分享的工程資產？

## Skill 的本質：在對的時機，餵對的資訊

Skill 的設計核心是一個概念叫**脈絡工程（context engineering）**。LLM 的 context window 有限，你不能把所有資訊都塞進去。Skill 的任務是：只在 Claude 需要的時候，才載入需要的內容。不需要的時候，它不佔任何 context。

一個常見的誤解是「Skill 就是一個 markdown 檔，把指令寫進去就好」。實際上 Skill 是一個**資料夾**，裡面可以放腳本、參考文件、範本、資料檔。SKILL.md 只是入口，負責告訴 Claude「什麼時候該讀哪個檔案」。

```
my-skill/
├── SKILL.md           # 入口，告訴 Claude 什麼時候讀什麼
├── config.json        # 需要使用者設定的參數
├── references/        # 詳細文件，Claude 按需讀取
├── scripts/           # Claude 可以執行的腳本
├── assets/            # 範本，Claude 複製來填
└── examples/          # 期望的輸出範例
```

## 9 種 Skill 類型：你的第一張技能地圖

Anthropic 盤點內部上百個 skill 後，歸納出 9 種最常見的類型。一條好用的原則是：**一個 skill 只做一類**。跨太多類反而會讓 agent 混淆。

![9 種 Claude Code Skill 類型](./assets/Claude%20Code%20Skill%20%E5%AF%A6%E6%88%B0%E6%8C%87%E5%8D%97/claude-code-skill-9-types.jpeg)

| # | 類型 | 核心用途 | 適合誰做 |
|---|------|----------|----------|
| 1 | 函式庫與 API 參考 | 教 Claude 正確用某個內部/外部 lib 或 CLI | 任何團隊 |
| 2 | **產品驗證** | 描述怎麼測試、驗證程式碼是否真的動了 | **影響最大，值得投資** |
| 3 | 資料抓取與分析 | 接上監控/資料系統，含 fetch script | 有資料團隊的組織 |
| 4 | 業務流程自動化 | standup、開票、週報等重複工作流 | 所有團隊 |
| 5 | 程式鷹架與範本 | 自動生出新 service/module 的 boilerplate | 有一定規模的 codebase |
| 6 | 程式碼品質與審查 | 強制 code style、自動 code review | 多工程師協作的團隊 |
| 7 | CI/CD 與部署 | 顧 PR、跑測試、漸進部署、自動回滾 | DevOps / Platform 團隊 |
| 8 | Runbooks | 從症狀出發，多工具調查，產出結構化報告 | on-call 團隊 |
| 9 | 基礎設施操作 | 例行維運，對破壞性動作加護欄 | Infra 團隊 |

其中第 2 類「產品驗證」被 Anthropic 內部認為**對產出品質的影響最可量測**，他們建議值得派一位工程師花一週把驗證 skill 做到極好。

## 7 個設計原則

### 1. Gotchas 區塊最有價值

任何 skill 裡訊號最高的內容是 Gotchas——告訴 Claude「哪些地方容易踩坑」。這些往往是文件不寫、但你被坑過才知道的細節。例如：

![Claude Code Skill 的 Gotchas 設計重點](./assets/Claude%20Code%20Skill%20%E5%AF%A6%E6%88%B0%E6%8C%87%E5%8D%97/claude-code-skill-gotchas.jpeg)

- 「`subscriptions` table 是 append-only，你要的是 version 最高的那列，不是 `created_at` 最新的」
- 「這個欄位在 API gateway 叫 `@request_id`，在 billing service 叫 `trace_id`，是同一個值」
- 「staging 永遠回 200，即使 webhook 沒真的處理。去看 `payment_events` 才是真實狀態」

關鍵動作：**每次 Claude 踩坑後，立刻把坑補進 Gotchas。** 這個區塊是活的，要隨時間持續更新。

### 2. Description 寫給模型看，不是給人看

Skill 的 `description` 欄位不是給人讀的摘要。Claude Code 啟動時會掃所有 skill 的 description，用它來判斷「這個請求有沒有對應的 skill」。所以 description 應該寫成**觸發條件說明**，包含使用者可能輸入的關鍵詞。

```
description: 彙整這週完成的工作，產生週報。當使用者說「跑週報」「整理這週進度」時觸發。
```

### 3. 用檔案系統做漸進揭露

不要把所有內容塞進 SKILL.md。把詳細 API 文件、範例、腳本放在子目錄裡，SKILL.md 只負責導航。Claude 會在需要時自己讀取對應檔案。這樣 SKILL.md 可以保持在 500 行以內，減少 token 消耗。

### 4. 給 Claude 腳本，讓它組合而非重造

把可重複的動作寫成 script 放進 skill，Claude 每一回合就可以花在「決定下一步做什麼」，而非重打 boilerplate。這對資料分析、CI/CD 類 skill 尤其有效。

### 5. 幫 Claude 記住歷史

用 append-only log 或 JSON 檔儲存每次執行結果。例如週報 skill 維護一個 `standups.log`，下次跑的時候 Claude 可以讀取歷史，自動判斷什麼是新進度、什麼是舊的重複。

### 6. 不要過度限制 Claude

給資訊，保留靈活性。Skill 的目的是補充 Claude 不知道的知識，不是把它鎖死在固定流程裡。寫「通常應該這樣做」，而不是「只能這樣做」。

### 7. 用 on-demand hooks 做安全護欄

Skill 可以註冊只在 skill active 期間生效的 hooks。兩個經典用法：

- `/careful`：動 production 時自動擋掉 `rm -rf`、`DROP TABLE`、force-push
- `/freeze`：debug 時只准動特定目錄，防止手滑修到無關的 code

## 如何分發：Repo vs Plugin

|            | Repo check-in                             | Plugin Marketplace                           |
| ---------- | ----------------------------------------- | -------------------------------------------- |
| 適合規模       | 小團隊、1-3 個 repo                            | 大團隊、跨 repo、跨專案                               |
| Skill 命名   | `/deploy`                                 | `/team-tools:deploy`                         |
| 可包內容       | skill + hooks                             | skill + agent + hooks + MCP + LSP + monitors |
| 安裝方式       | 放在 `.claude/skills/`                      | `/plugin install`                            |
| Context 成本 | 每個 skill 的 description 都進 context, 本體按需載入 | 成員自選安裝，只裝需要的                                 |

關鍵提醒：Plugin 的目錄結構中，`skills/`、`agents/`、`hooks/` 等都要放在 plugin 根目錄，只有 `plugin.json` 放在 `.claude-plugin/` 裡面。這是新手最常犯的錯誤。

## 常見顧慮 Q&A

**Q: 每個 skill 都會佔 context，裝太多會不會影響效能？**
A: 會。每個 skill 的 `description` 都會進入 session 的 skill listing。團隊規模變大後，建議改用 plugin marketplace，讓成員只裝自己需要的。

**Q: Skill 內文載入後會一直留在 context 嗎？**
A: 會。一旦 skill 被觸發，內容就會跨 turn 保留。autocompaction 會帶上最近 5000 tokens 的 skill 內容。因此 skill 正文要保持精簡。

**Q: Skill A 可以依賴 Skill B 嗎？**
A: 目前沒有原生的依賴管理。做法是在 A 的內容裡直接 reference B 的名字，讓 Claude 自己去 call。不是真正的 dependency graph。

**Q: 舊的 `.claude/commands/` 還能用嗎？**
A: 能。但新開發建議直接用 `.claude/skills/`，因為 skills 支援更多功能（子目錄、hooks、fork context 等）。同名時 skill 優先。

## SKILL.md 最小可行範本

直接複製這個骨架，改成自己的內容就能上線：

```markdown
---
description: [寫給模型看的觸發條件，含關鍵詞]
---

# [Skill 名稱]

## 怎麼做
1. [步驟一]
2. [步驟二]
3. [步驟三]

## Gotchas
- [踩過的坑 1]
- [踩過的坑 2]

## 參考
- 詳細規格見 [references/spec.md](references/spec.md)
```

## 起步建議

不用追求一次寫完。Anthropic 團隊的經驗是：**最好用的 skill 都是從幾行字加一個 gotcha 起步**，然後團隊成員每次撞到新狀況就補一條，慢慢變強的。與其花一週設計完美規格，不如今天寫一個最小版本，開始讓它被實際使用、持續進化。

---

## 參考資料

- [Anthropic: Lessons from building Claude Code — How we use skills](https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills) (Thariq Shihipar, 2026.06)
- [Claude Code Docs: Skills](https://code.claude.com/docs/en/skills)
- [Claude Code Docs: Plugins](https://code.claude.com/docs/en/plugins)
