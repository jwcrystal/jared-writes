---
title: Mastering Claude Code in 30 minutes 影片筆記
description: >-
  Anthropic 官方示範 Coding Agent 實戰操作哲學——不是功能介紹，而是「如何像使用 Senior Engineer 一樣使用 AI
  Coding Agent」的方法論，適用 Claude Code、Cursor、OpenAI Codex、OpenChamber 等主流 agent。
type: publish
status: draft
tags:
  - claude-code
  - ai-coding
  - agent
  - workflow
  - prompt-engineering
  - context-engineering
  - anthropic
source:
  - >-
    影片：Mastering Claude Code in 30 minutes｜Anthropic
    官方頻道｜https://www.youtube.com/watch?v=6eBSHbLKuN0
  - 'Claude Code 官方文件｜Anthropic｜https://docs.anthropic.com/en/docs/claude-code'
  - >-
    Building effective agents｜Anthropic
    官方部落格｜https://docs.anthropic.com/en/docs/build-with-claude/agentic
  - >-
    Lessons from building Claude Code: how we use Skills｜Anthropic
    官方部落格｜https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills
publish_target: ''
published_url: ''
pubDate: 2026-06-25T02:00:00.000Z
updatedDate: 2026-06-25T02:00:00.000Z
---

## 核心摘要

Anthropic 官方發布了一支 30 分鐘的教學影片 "Mastering Claude Code in 30 minutes"，內容不是功能逐項介紹，而是 **Coding Agent 的實戰操作哲學**。影片示範了如何將 AI Coding Agent 當作一個自主的工程師夥伴來協作，而非僅僅是進階版的自動完成工具。這些原則不僅適用 Claude Code，也同樣適用於 Cursor Agent、OpenAI Codex、OpenChamber 等其他現代 AI 開發代理。

## 一句話理解

**不要把 AI Coding Agent 當成 Autocomplete，要當成 Senior Engineer。告訴它目標與限制，讓它自己探索、規劃、執行、修正。**

## 為什麼這件事值得看

AI Coding Agent 正在快速成為軟體開發的主流工具，但多數開發者仍然在用「聊天模式」使用它們——寫一句 prompt、得到一段 code、手動複製貼上。這種使用方式只發揮了這些工具不到 20% 的潛力。

Anthropic 作為最早推出 Agent 模式 Coding 工具的公司之一，在這支影片中系統性地展示了「正確的使用方法」。這些方法論不是 Claude Code 專屬，而是整個 AI Coding Agent 領域的通用最佳實踐。無論你使用哪個工具，這套 workflow 都能直接提升你的產出品質與開發效率。

## 背景 / 問題

多數開發者習慣將 AI 工具當作聊天視窗——寫一句 prompt、得到一段 code、複製貼上。但 Anthropic 設計 Claude Code 的出發點是 **Agent 模式**：模型可以閱讀整個 repository、執行 terminal command、修改多個檔案、執行測試、根據結果持續修正，一直到任務完成。

這不是一次性的問答，而是一個持續循環：

```
Task
  ↓
Read Code
  ↓
Think
  ↓
Use Tool
  ↓
Observe
  ↓
Repeat
```

這也是現在幾乎所有 Coding Agent 的基本架構。理解這個循環，才能正確使用這些工具。

## 核心內容

### 核心工作流程

全片可以濃縮成這個流程：

```
Describe Goal
       │
       ▼
Ask Claude to Explore
       │
       ▼
Produce Plan
       │
       ▼
Review Plan
       │
       ▼
Implement
       │
       ▼
Run Tests
       │
       ▼
Fix Errors
       │
       ▼
Commit
```

### 十個關鍵原則

**① Prompt 不要只寫需求，要寫工作方式與限制**

傳統用法：
```
Add dark mode.
```

有效用法：
```
Implement dark mode.
Requirements:
- follow existing design system
- don't break API
- add tests
- explain tradeoffs
```

Agent 知道的 constraints 越多，產出品質越高。提供的不是「要做什麼」，而是「在什麼框架下做」。

**② 讓 Agent 自己探索 Codebase**

不要急著貼檔案或指定修改位置。更好的做法：

```
Explore the codebase.
Find where authentication is implemented.
Explain the architecture first.
Then propose changes.
```

讓模型先建立完整的 context，再開始修改。這是 Anthropic 一直推崇的 workflow，也是 Context Engineering 的實戰應用。

**③ 一次不要要求太多**

將任務拆解為多個階段：
- Step 1: Understand
- Step 2: Plan
- Step 3: Implement
- Step 4: Test

Agent 在每一步都有機會修正方向，避免一次下達複雜指令導致的偏離。

**④ 多利用 Plan Mode**

在實作之前，先要求：

```
Don't write code. Only produce a plan.
```

確認的事項：
- 哪些檔案要改
- 哪些 API 受影響
- 是否需要 migration
- 風險評估

確認無誤後再下達：

```
Now implement.
```

大型專案的成功率通常會大幅提升。

**⑤ 每完成一個 milestone 就 Commit**

不要等到最後才一次 commit。每個可運作的功能完成後就 commit，方便 rollback 與 trace。

**⑥ 讓 Agent 自己處理測試**

不要自己手動跑測試再回報結果。直接要求：

```
Run tests. Fix failures until everything passes.
```

Agent 就會自動進入 Edit → Run → Read error → Fix → Run again 的循環。這正是 Agent Loop 的核心運作方式。

**⑦ 描述目標，不要描述操作**

無效的指令：
```
Open app.ts. Go to line 28. Replace...
```

有效的指令：
```
Update authentication to support OAuth.
Maintain backwards compatibility.
```

讓 Agent 自行決定要修改哪些檔案、哪些函式、引入哪些相依套件。

**⑧ 充分利用 Repository Context**

Claude Code 最大的優勢之一就是能直接讀取整個 repository。不需要一直手動貼 code，直接說：

```
Search the repository.
Understand existing patterns.
Follow conventions.
```

模型會自行閱讀並理解專案結構。

**⑨ 用途不限於寫 Code**

影片示範 Claude Code 可以勝任多種任務：
- Debug
- Refactor
- Explain architecture
- Generate migration scripts
- Review PR
- Write tests
- Update documentation

它的定位比較像 Senior Engineer，而不是 Autocomplete。

**⑩ 設定品質閘門**

在 prompt 中明確加入品質標準，讓 Agent 在實作過程中有判斷依據：

```
- don't break existing API
- add tests with 80% coverage
- explain tradeoffs before implementation
```

### 架構對應表

這些原則可以對應到更抽象的系統架構概念：

| 影片實踐 | 對應架構層面 |
|---|---|
| Explore repository | Context Engineering |
| Produce plan | Planning Layer |
| Tool use | Tool Calling Layer |
| Run tests | Harness / Workflow |
| Fix until pass | Agent Loop |
| Commit milestones | Workflow Orchestration |
| Follow project conventions | System Prompt / Skills |
| Let Claude inspect the codebase | Autonomous Context Gathering |

## 案例 / 輔助說明

### Prompt 對比

| 場景 | ❌ 低效寫法 | ✅ 有效寫法 |
|---|---|---|
| 加入新功能 | Add dark mode. | Implement dark mode. Requirements: follow existing design system, don't break API, add tests |
| 理解程式碼 | 把這個檔案讀一遍 | Explore the codebase. Find where auth is implemented. Explain the architecture. |
| 修改功能 | 打開 app.ts 第 28 行，把 validate 改掉 | Update authentication to support OAuth. Maintain backwards compatibility. |
| 除錯 | 執行 npm test 然後告訴我結果 | Run tests. Fix failures until everything passes. |

### 適用場景

- **適合**：大型專案重構、跨檔案功能新增、技術債清理、程式碼審查、自動化測試
- **也適合**：學習新 codebase、產生 migration plan、撰寫技術文件
- **較不適合**：單行修改、簡單的 regex 操作、不需要 context 的獨立腳本

## 風險與限制

- **Agent 並非萬能**：複雜的架構決策仍需要開發者判斷，特別是在涉及商業邏輯或法規遵循時
- **Context 品質決定結果**：Agent 的輸出好壞高度依賴於它接收到的 context。混亂或不完整的 repository 會導致混亂的產出
- **成本考量**：Agent 模式會產生大量的 token 消耗（探索 + 規劃 + 實作 + 測試），相較於簡單的 Chat 模式成本更高
- **安全性**：讓 Agent 執行 terminal command 意味著需要信任它的操作。建議在隔離環境或受版本控制的 branch 上作業
- **不是取代開發者**：正確的定位是生產力倍增工具，而非人力替代方案。開發者的審查與決策仍然是品質的最終保障

## 我的觀察

- 「Prompt 不要寫需求，要寫工作方式」是從 Chat 模式轉換到 Agent 模式最難跨越的認知門檻。多數人直覺是描述「要什麼」，但 Agent 模式下描述「怎麼思考、有什麼限制」的邊際效益高得多。
- Context Engineering 是這套 workflow 的隱藏核心。讓 Agent 自己探索 codebase、大量使用 repository context——這些做法的本質是幫 Agent 建立高品質的 context，而非依賴一則完美的 prompt。
- 測試在 Agent Loop 中的角色經常被低估：它不是終點驗收，而是 Observe 階段的觀測點，用來驅動下一輪修正。
- 這套方法論不僅適用 Claude Code，對任何採用 Agent 模式的 AI Coding 工具（Cursor Agent、OpenAI Codex、OpenChamber 等）幾乎完全通用。如果你正在設計自己的 Agent 平台，這支影片提供了一組很好的 UX 與 workflow 設計參考。

## 最後記住這句

**告訴 Agent 目標與限制，讓它自己探索、規劃、執行、修正——這就是 Coding Agent 的正確打開方式。

## 參考資料

1. **Mastering Claude Code in 30 minutes** — Anthropic 官方頻道
   https://www.youtube.com/watch?v=6eBSHbLKuN0
2. **Claude Code 官方文件** — Anthropic
   https://docs.anthropic.com/en/docs/claude-code
3. **Building effective agents** — Anthropic 官方部落格，論述 agent 的設計原則與架構模式
   https://docs.anthropic.com/en/docs/build-with-claude/agentic
4. **Lessons from building Claude Code: how we use Skills** — Anthropic 官方部落格，分享 Claude Code Skills 的設計心法
   https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills
5. **Anthropic: Agent 的工作模式與概念** — Anthropic 官方文件，說明 agent loop、tool use、context 的核心概念
   https://docs.anthropic.com/en/docs/build-with-claude/agentic

**
