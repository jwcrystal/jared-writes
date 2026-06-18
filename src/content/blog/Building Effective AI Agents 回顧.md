---
title: Building Effective AI Agents 回顧
description: 你不需要另一個 agent framework。Anthropic 用一年 production 經驗告訴你，五種 pattern 就夠了。
type: publish
status: draft
tags:
  - ai
  - agent
  - llm
  - anthropic
  - workflow
source: 'https://www.anthropic.com/engineering/building-effective-agents'
publish_target: ''
published_url: ''
pubDate: 2025-06-15T16:00:00.000Z
updatedDate: 2025-06-17T16:00:00.000Z
---
如果你正在用 LLM 開發產品，大概每週都會看到一個新的 agent framework。LangChain、CrewAI、AutoGPT、各種 SDK⋯⋯每個都說自己是最佳解。你開始懷疑：我到底需不需要這些東西？

Anthropic 花了一年陪客戶從 production 經驗裡找答案。答案很直白：**最成功的團隊用的不是框架，是 pattern。**

2024 這篇文章就是那個答案的完整版。它不是 framework 的推廣文，反過來，它是一份「哪些模式真的 work、什麼時候你其實不需要 agent」的實戰手冊。

這篇重點回答三個問題：

- Workflow 和 Agent 到底差在哪，怎麼選？
- 五種 production 驗證過的 pattern，各適合什麼場景？
- 為什麼工具設計比 prompt 更重要？

---

## 核心摘要

Anthropic 這篇文章是 2024 年關於 LLM agent 最值得讀的實戰總結之一。

核心論點很簡單：**最成功的 agent 實作沒有用複雜框架，而是用簡單、可組合的模式。**

文章區分了兩類架構 — Workflow（程式碼預先編排）和 Agent（LLM 動態控制）— 並給出五種 production 驗證過的 pattern。更重要的是，它反覆提醒一件事：**很多時候你根本不需要 agent。**

## 一句話理解

先從最簡單的方案開始，複雜度只在你證明它有效之後才加上去。

## 為什麼這件事值得看

2024 agent framework 大爆發，每個月都有新框架，但 production 裡真正 work 的 pattern 其實就那幾個。Anthropic 作為模型 provider，有機會看到大量客戶的實作方式 — 這篇是他們總結出的 common patterns，不是理論推導。

## 什麼時候該用 Workflow，什麼時候該用 Agent

| | Workflow | Agent |
|---|---|---|
| 定義 | LLM 走預先定義的程式碼路徑 | LLM 動態決定下一步 |
| 適合場景 | 步驟可預測、拆解乾淨 | 步驟數不確定、無法硬編碼 |
| 主要代價 | latency 較低 | 成本高、錯誤可能累積 |
| 風險 | 靈活度不夠 | 自主性太高，需要 guardrail |
| 除錯難度 | 容易，每步可打點檢查 | 需要 sandbox 環境測試 |

文章的建議很務實：先優化單一 LLM call（加 retrieval、in-context examples），不夠再說。Workflow 下不去再上 Agent。

## 核心內容：五種 Production 驗證過的 Pattern

### 1. Prompt Chaining
任務拆成固定序列，每步 LLM call 吃上一步的輸出，中間可加檢查點（gate）。
**適合**：行銷文案 → 翻譯、寫大綱 → 審核 → 成文。
**核心 tradeoff**：用 latency 換準確度。

### 2. Routing
先分類，再導向不同的專用 prompt/tool。
**適合**：客服分流（退貨、技術、一般查詢各走各的）、簡單問題丟給便宜的模型。
**關鍵 insight**：不分流的話，單一 prompt 會被不同需求互相拉扯。

### 3. Parallelization
兩種變形：
- **Sectioning**：拆成獨立子任務平行處理（例如：回應 query 的同時做內容過濾）
- **Voting**：同一任務跑多次取共識（例如：程式碼安全審查）
**適合**：需要多角度判斷、或單純想加快速度。

### 4. Orchestrator-Workers
中央 LLM 動態拆任務、分派給 worker LLM、彙整結果。
**跟 Parallelization 的關鍵差別**：子任務不是預先定義的，由 orchestrator 依輸入決定。
**適合**：多檔案修改的 coding agent、多來源資訊搜集。

### 5. Evaluator-Optimizer
一個 LLM 生成，另一個 LLM 給回饋，迭代到滿意為止。
**適合**：文學翻譯（有 nuance 需要 refinement）、複雜搜尋（評估決定要不要再搜一輪）。
**前提**：LLM 給的回饋要確實能 improve 輸出。

### Agent（最上層）
就是 LLM 在一個 loop 裡持續使用工具、根據環境回饋調整、必要時暫停請示人類。
**關鍵實作建議**：Agent 本身不複雜，複雜的是工具設計。

## 一個讓工程師點頭的例子

Anthropic 做 SWE-bench agent 時，花最多時間的不是 overall prompt，而是**工具設計**。

一個具體的故事：agent 用相對路徑時會出錯，改成強制要求絕對路徑後就完美了。他們把這個類比成 HCI — 你花多少心力設計 Human-Computer Interface，就該花同等心力設計 **Agent-Computer Interface（ACI）**。

工具設計的具體建議：

- 給模型足夠的 token「思考」，不要讓它把自己寫進死胡同
- 格式接近模型在網路上常見的自然格式
- 避免 format overhead（不需要它算行數的 diff、不需要它 escape 的 JSON）
- 參數名稱和描述要像對 junior developer 寫 docstring
- Poka-yoke：把參數設計成不容易出錯的形狀

## 我的判斷

這篇文章最有價值的不是五種模式，而是那句「start with simple prompts, optimize with comprehensive evals, add complexity only when it demonstrably improves outcomes」。在 framework 滿天飛的 2024–2025，這句實際上是對行業過度工程化的直接 critique。

五種模式本身沒有神奇技巧，有在實作的大概都用過。但他們把「什麼時候用什麼」的判斷標準寫清楚了，這比 pattern catalog 更實用。

## 風險與限制

- 這五種 pattern 在實務上界線常常模糊。你的系統可能 routing 完就 prompt chaining，中間還夾一個 parallelization。文章也承認這點，說這些是 composable patterns 不是 prescriptive taxonomy。
- 文章沒有明確回答「workflow 和 agent 的切換點在哪」。我的看法是：你能不能寫出 error recovery 的 logic？能 → workflow，不能 → 你需要 agent 來處理意外。
- Framework 並非不能用，但要能看懂底層在幹嘛。文章建議先用 API 直接刻，理解 pattern 之後再用框架加速。
- 這些 pattern 的有效性取決於底層模型的能力。隨著模型進步，某些 pattern 可能變得多餘（例如 routing 可能被更強的單一模型取代）。

## 最後記住這句

> Start with simple prompts, optimize with comprehensive evals, and add multi-step agentic systems only when simpler solutions fall short.

## 來源

- [Building effective agents — Anthropic Engineering Blog](https://www.anthropic.com/engineering/building-effective-agents) (Dec 19, 2024)
