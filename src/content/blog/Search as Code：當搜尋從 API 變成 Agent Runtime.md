---
title: Search as Code：當搜尋從 API 變成 Agent Runtime
description: >-
  Perplexity 提出的 Search as Code（SaC）不是讓搜尋變聰明，而是讓 LLM 用程式碼自己組出搜尋流程。這對 agent
  時代的工具架構有深遠影響。
type: publish
status: draft
tags:
  - ai
  - agent
  - search
  - architecture
  - perplexity
source: 'https://research.perplexity.ai/articles/rethinking-search-as-code-generation'
related: []
pubDate: 2026-06-11T00:00:00.000Z
updatedDate: 2026-06-11T00:00:00.000Z
---

大多數人看到 Perplexity 發表 Search as Code，直覺反應是「哦，搜尋又變強了」。但 SaC 真正重要的是它重新定義了 agent 和工具之間的關係 — **不是讓模型呼叫更好的 API，而是讓模型自己寫程式來組合工具**。

---

## SaC 在解決什麼問題？

傳統搜尋的工作流程長這樣：

```
使用者提問
    ↓
模型呼叫 search(query)
    ↓
搜尋引擎跑固定 pipeline
    ↓
回傳 top results
    ↓
模型讀完所有結果
    ↓
模型回答
```

這對簡單查詢（「今天天氣」「比特幣價格」）運作良好。但遇到需要多來源比對、跨語言驗證、分組彙整的研究型任務，三個問題會浮現：

**1. 上下文噪音**：模型只需要一個精準事實，但搜尋引擎回傳整包結果 — 正文、導航、廣告、重複內容 — 全部塞進模型上下文。不只是 token 成本，更嚴重的是雜訊讓推理品質下降。

**2. 模型只能控制 query**：排序、過濾、分組、驗證全由搜尋系統固定處理。但 agent 往往知道更聰明的策略 — 優先查官方文件、排除新聞站、按年份分組 — 如果只能傳 query，這些判斷無法落地。

**3. 多步搜尋太低效**：複雜任務需要 fan-out、批量查詢、去重、正則過濾、跨來源比對。用多輪 tool call 做的話，模型得一直呼叫工具 → 讀結果 → 再呼叫 → 再讀結果，大量中間狀態塞進上下文，而這些狀態本來就不該給模型讀。

---

## SaC 的解法：讓模型寫搜尋程式

SaC 的核心思路是把搜尋拆成一組 **可編程 primitive**，讓 LLM 生成 Python 程式碼，在 sandbox 裡控制整個搜尋流程：

```
傳統：Model → search(query) → 固定 pipeline → results → Model 讀取
SaC：  Model → 生成 Python 程式碼 → sandbox 執行 → 
       控制 retrieval + ranking + filtering + dedupe + 驗證 → 只回傳需要的結果
```

關鍵差異：中間狀態留在 sandbox（程式 runtime），不進模型上下文。模型只需要看到最終的乾淨結果。

---

## 三層分工

Perplexity 的 SaC 架構可以理解為三層：

| 層級 | 角色 | 做什麼 |
|------|------|--------|
| **Model** | 策略層 | 分析任務、決定搜尋策略、生成程式碼 |
| **Sandbox** | 執行層 | 跑程式、處理並行、過濾、去重、聚合 |
| **SDK** | 能力層 | 提供可組合的 search primitives（retrieve、rank、filter、verify） |

舉例：一個需要「比較三款手機在五個國家的售價」的查詢——

- 傳統搜尋：呼叫一次 search，回傳一堆混在一起的結果，模型自己慢慢讀
- SaC：模型生成程式，對每個國家各發一次查詢、用正則提取價格、按型號分組、輸出比較表

---

## 為什麼這件事對 agent 開發有影響

SaC 的啟示不只是「搜尋變強」，而是 **agent 和工具的邊界應該下移**。目前主流模式是「模型呼叫工具」，SaC 展示的是「模型編程工具」。

幾個值得注意的趨勢：

- **中間計算不該進上下文**：排序、過濾、彙整交給程式 runtime，模型只讀最終結果
- **工具不該是固定 API**：給模型一組可組合的 primitive，讓它自己決定怎麼組
- **驗證應該可程式化**：不是「搜尋完就結束」，而是可以用程式再跑一輪驗證邏輯

這跟 Function Calling 或 MCP（Model Context Protocol）並不衝突，而是在它們之上加了一層 programmable 的維度。MCP 定義了「有哪些工具」，SaC 展示的是「這些工具可以怎麼被組合」。

---

## 適用場景與限制

**SaC 適合**：
- 多來源、多步驟的研究型查詢
- 需要結構化輸出的任務（表格、比較、彙整）
- 需要中間過濾和驗證的場景

**目前限制**：
- 對簡單查詢（找一個事實）沒有明顯優勢
- 需要 sandbox 執行環境，增加基礎設施複雜度
- 模型生成的程式碼可能有 bug，需要 error handling

---

## 來源

- [Perplexity Research: Rethinking Search as Code Generation](https://research.perplexity.ai/articles/rethinking-search-as-code-generation)
