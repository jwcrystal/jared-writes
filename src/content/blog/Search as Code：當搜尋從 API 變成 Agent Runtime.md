---
title: Search as Code：當搜尋從 API 變成 Agent Runtime
description: >-
  Perplexity Search as Code（SaC）的概念架構整理：把搜尋從固定 API 變成一組可編程 primitive，讓 LLM
  用程式碼自己組出搜尋流程。
type: knowledge
status: evergreen
tags:
  - ai
  - agent
  - search
  - architecture
  - perplexity
  - code-generation
source: 'https://research.perplexity.ai/articles/rethinking-search-as-code-generation'
pubDate: 2026-06-11T00:00:00.000Z
updatedDate: 2026-06-11T00:00:00.000Z
---

# Search as Code：當搜尋從 API 變成 Agent Runtime

## 核心摘要

Search as Code（SaC）表面上在講搜尋，實際上是給 agent 時代的工具架構提出了新方向：**把搜尋從固定 API 變成一組可編程 primitive，讓 LLM 用程式碼自己組出當前任務需要的搜尋流程**。

傳統搜尋是黑盒 API，模型只能控制 query，接下來由搜尋系統的固定 pipeline 決定一切。SaC 則讓模型生成 Python 程式，在 sandbox 裡控制 retrieval、ranking、filtering、dedupe、驗證和中間狀態管理。

我的理解是，SaC 的重要之處不在「Perplexity 搜尋變強」，而是它把 agent infrastructure 的邊界往下移了——模型不只是工具的使用者，而是工具的程式設計師。

## 一句話理解

傳統搜尋問的是「這個 query 的 top results 是什麼」，SaC 問的是「這個任務需要怎樣的搜尋程序」。兩個問題看起來接近，但代表完全不同的系統設計思路。

## 傳統搜尋卡在哪裡

```
User asks question
   ↓
Model calls search(query)
   ↓
Search engine runs fixed pipeline
   ↓
Returns top results
   ↓
Model reads all results
   ↓
Model answers
```

這套模式對簡單問題很好用——查新聞、找事實、確認文件。但遇到研究型、多來源、多步驟、需要驗證的任務，就會開始卡住。

### 1. 上下文太粗

模型有時候只需要一個精準事實，但傳統搜尋會回一整包結果，包含正文、導航、廣告、重複資訊、看起來相關但其實會干擾判斷的內容。最後全部塞進模型上下文。問題不只是 token 變貴，而是 context noise 會讓模型推理變髒。

### 2. 模型只能控制 query

搜尋之後的排序、過濾、分組、驗證，通常都由搜尋系統固定處理。但 agent 很多時候已經知道自己想要什麼策略——例如應該優先查官方文件、排除新聞站、用 vendor 和年份分組、先抓候選再做嚴格驗證——如果工具只允許它傳 query，這些判斷就無法真正落地。

### 3. 多步搜尋太低效

複雜搜尋往往需要 fan-out、批量查詢、補搜、去重、正則過濾、跨來源比對。如果用多輪 tool call 完成，模型得一直呼叫工具、讀結果、再呼叫、再讀結果。這不只慢，也會把大量中間狀態塞進模型上下文。而許多中間狀態本來就不該給模型讀，交給程式處理就好。

## SaC 的整體架構

```
使用者任務
   ↓
LLM / Agent 控制層
   ↓ 生成程式碼
Sandbox 執行層
   ↓ 調用 SDK primitive
Agentic Search SDK
   ↓
Search Infrastructure
   ↓
外部資料來源
```

核心變化：模型不再是呼叫搜尋 API，而是**生成一段搜尋程式**，讓程式在 sandbox 裡執行，直接操控搜尋 SDK 提供的底層能力。

## 三層分工

| 層級 | 角色 | 負責的事 | 為什麼重要 |
|---|---|---|---|
| **Model** | 控制層 | 拆任務、決定搜尋策略、判斷來源可信度、決定補搜策略 | 讓搜尋策略能依任務動態調整 |
| **Sandbox** | 執行層 | 執行模型生成的 Python 程式，處理並行、retry、過濾、去重、聚合 | 把 deterministic 的工作交給程式，不浪費模型上下文 |
| **Agentic Search SDK** | 能力層 | 提供 retrieve、rank、filter、dedupe、fetch、parse、render 等 primitive | 讓模型不只呼叫搜尋，而是能組合搜尋流程 |

這個分工是 SaC 最值得記的地方。LLM 適合判斷要找什麼證據、什麼才算可信；但批量搜尋、去重、正則過濾、欄位驗證這類工作，更適合交給程式 runtime。

### Model：搜尋流程的設計者

模型要決定的事：

- 任務要拆成哪些子問題
- 每個子問題要查什麼
- 哪些來源可信，哪些要排除
- 是否需要並行搜尋
- 結果如何過濾、排序、驗證
- 找不到時怎麼補搜
- 最後哪些 evidence 值得回到模型上下文

這裡的模型不是「搜尋結果的讀者」，而是「搜尋流程的設計者」。

### Sandbox：deterministic 工作的歸宿

模型生成的程式在 sandbox 裡處理批量搜尋、並行請求、retry、正則過濾、去重、排序聚合、中間結果保存、結果驗證。這些工作交給程式比用 token 推理更便宜也更穩定。

這裡的價值是把大量中間操作留在 runtime 裡處理，最後只把真正有用的 evidence 帶回模型。

### Agentic Search SDK：搜尋積木

Perplexity 把搜尋 stack 拆成更細的 primitive，而不是直接包成一個 `search()`：

| Primitive | 作用 |
|---|---|
| `retrieve` | 取得候選文件 |
| `rank` | 排序 |
| `filter` | 過濾 |
| `dedupe` | 去重 |
| `fetch` | 抓取頁面 |
| `parse` | 解析內容 |
| `render` | 整理成模型可讀格式 |

高階 API（`search()`）仍然存在，簡單任務繼續用它。但複雜任務可以直接繞過高階 API，組合底層 primitive。

## 執行流程

```
User gives task
   ↓
Model analyzes task
   ↓
Model generates Python search program
   ↓
Sandbox executes program
   ↓
Program calls Search SDK primitives
   ↓
Program filters / ranks / dedupes / verifies
   ↓
Only compact final evidence returns to model
   ↓
Model answers
```

拆開看是八步：

1. **理解任務**，判斷是否需要多來源、多步驟、多驗證
2. **制定策略**，決定來源優先級、排除條件、query variants、驗證標準
3. **生成程式碼**，把策略寫成可執行流程
4. **在 sandbox 執行**，處理批量查詢、補搜、去重與過濾
5. **調用 SDK primitive**，不只是 `search()`，而是控制 retrieve、rank、fetch、parse、filter
6. **保存中間狀態**，例如 candidates、verified results、failed cases
7. **回傳精簡結果**，只把已驗證 evidence、引用、缺失項帶回模型
8. **生成答案**，模型基於乾淨資料回答

第七步是關鍵。SaC 不是把所有中間垃圾都丟回模型，而是讓程式先把候選資料處理完，只把真正有用的 evidence 帶回上下文。

## 中間狀態管理的取捨

Perplexity 比較了兩種 sandbox 狀態保存方式：

| 方式 | 優點 | 問題 |
|---|---|---|
| **REPL** | 變數跨輪留在記憶，方便、省 token | 長任務變混亂的 Jupyter notebook |
| **Filesystem + 序列化** | 狀態清楚、可追蹤 | 稍麻煩，需要顯式讀寫 |

他們選了 filesystem。原因是長任務裡，顯式狀態比隱式狀態更可靠。這個判斷對 agent 設計很重要：長任務不一定追求最省事，**可追蹤比方便更重要**。

## 案例：CVE 驗證

文章用 CVE vendor advisory 任務當案例：

- 找出 2023–2025 年的高嚴重 CVE
- 每個 CVE 必須引用 vendor 自己的 advisory
- 指出產品名稱和 fix version
- fix version 必須明確對應該 CVE

這個任務難在不能只找 NVD 或新聞站，必須找到 vendor 官方 advisory，而且確認 advisory 裡的產品、CVE、fix version 確實綁在一起。

SaC 的做法是把規則寫進搜尋流程：

- 只接受 vendor 官方 advisory
- 排除 NVD、MITRE、CVE Details、新聞站、第三方資料庫
- 對 vendor-year 組合做補搜和 backfill
- 用程式驗證 CVE、產品、fix version 的綁定關係
- 去重並排除 aggregator URL

文章給出的結果：

| 指標 | 結果 |
|---|---|
| 準確率 | 100% |
| Token 使用量 | 288.7K → 42.9K |
| Token 減少 | 85.1% |

這個數字要保留一點懷疑，畢竟是 Perplexity 自家研究。但省 token 的邏輯是可信的——它不是讓模型更會總結，而是**不讓不該進上下文的東西進去**。

## Benchmark 表現

| Benchmark | SaC 表現 |
|---|---|
| DSQA | 第一 |
| BrowseComp | 第一 |
| HLE | 幾乎與 OpenAI 並列 |
| WideSearch | 第一 |
| WANDR | 第一，且大幅領先（約第二名 2.5 倍） |

當作方向性的強信號合理，但不會完全視為中立結論。benchmark 設計和任務分布都會影響結果。

## 我的判斷

SaC 最重要的不是 Perplexity 搜尋變強，而是它展示了 agent infrastructure 的一種新方向：

以前我們習慣把能力包成高階工具。這對簡單任務方便，但複雜任務會卡——模型明明知道要做什麼，工具卻只允許它按幾個固定按鈕。SaC 把能力拆成更細的 primitive，讓模型自己組裝。

這個思路背後的假設是：frontier model 已經有能力生成可執行程式，也有能力根據任務設計流程。既然如此，系統就不該只給一個固定搜尋入口，而該給一組可編程能力。

## 風險與限制

### 安全風險

模型生成程式碼並執行，sandbox 必須非常硬。只要邊界不清楚，這不是搜尋架構，是事故預備區。

### 可觀測性風險

agent 自組的搜尋流程比固定 pipeline 更難 debug。結果錯了，要追是哪個 query、哪個 filter、哪個驗證條件出問題，需要更好的 tracing。

### SDK 粒度風險

primitive 太低階，模型用起來累；太高階，又退回傳統 API。這個粒度很難拿捏，而且不同任務可能需要不同粒度。

### 模型能力依賴

SaC 假設模型能穩定寫出可執行、可維護、可驗證的程式。frontier model 可能可以，但不是所有模型都能穩定做到。模型降級時，這個架構的退化速度可能比傳統 RAG 更快。

## 延伸：這不只是搜尋

SaC 背後的架構變化可以總結成三層協作：

- **LLM** 負責判斷和策略
- **程式 runtime** 負責執行和資料處理
- **外部系統** 負責 I/O

搜尋只是第一個自然的場景——因為搜尋本來就有大量 I/O、大量不確定性、大量需要驗證的資訊。但同樣的思路可以延伸到資料分析、程式碼理解、安全掃描、商業研究、法務文件比對。

固定工具太死，純 token 推理太貴，中間用程式 runtime 接起來似乎是對的方向。

## 最後記住這句

Search as Code 把搜尋從「答案 API」變成「agent 可以操作的資訊作業系統」。如果傳統搜尋是給人看的 SERP，AI-first search 是給模型讀的高密度 context，那 SaC 就是給 agent 操控的搜尋 runtime。

未來很多 agent 能力，應該都會從「呼叫工具」走向「用程式組裝工具」。
