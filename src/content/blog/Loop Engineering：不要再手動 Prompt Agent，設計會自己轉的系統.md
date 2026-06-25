---
title: Loop Engineering：不要再手動 Prompt Agent，設計會自己轉的系統
description: >-
  Loop Engineering 不是把 prompt 寫得更漂亮，而是設計一套會自己發現任務、交付、驗證、保存狀態並定期重跑的 agent
  系統。真正的關鍵不是自動化本身，而是把 evaluator、狀態檔、預算上限與人工檢查點放進 loop 裡。
type: publish
status: draft
tags:
  - ai
  - agent
  - loop-engineering
  - automation
  - ai-coding
source: '[[../../20-Knowledge/AI/Loop Engineering：設計會自己 Prompt Agent 的系統]]'
related: []
pubDate: 2026-06-24T16:00:00.000Z
updatedDate: 2026-06-24T16:00:00.000Z
---

如果你已經開始用 coding agent，大概會遇到一個很微妙的問題：agent 可以幫你寫 code、改 bug、跑測試，但每一輪還是要你坐在那裡告訴它下一步做什麼。

它很會做事，但不會自己形成一個穩定流程。它完成一件事就停下來，等你下一個 prompt。久了之後，你會發現真正卡住的不是 agent 能不能做，而是你一直被迫當那個「手動啟動下一輪」的人。

Loop Engineering 要處理的就是這個問題。

它不是新的 prompt 技巧，也不是叫你把指令寫得更長。更準確地說，Loop Engineering 是把自己從「手動 prompt agent 的人」移開，改成設計一套會自己 prompt agent 的系統。

這篇重點回答三個問題：

- Loop Engineering 和 Prompt / Context / Harness Engineering 差在哪裡？
- 一個真的 loop 需要哪些組成？
- 為什麼最重要的不是自動執行，而是能不能拒絕錯誤輸出？

## 核心摘要

Loop Engineering 的核心不是「讓 AI 多寫一點 code」，而是把 agent 工作流設計成一個會自己轉的系統：定期醒來、發現任務、交給 agent、驗證結果、保存狀態，然後進入下一輪。

這件事真正改變的是人的位置。以前人坐在 loop 裡面，一次次 prompt agent；現在人站到 loop 外面，設計 loop 怎麼運轉、什麼時候停、誰有權說不行。

但這也帶來一個風險：如果沒有驗證機制，loop 只是讓 agent 更快地自我批准。自動化本身不難，難的是設計一個能拒絕錯誤結果的系統。

## Loop Engineering 是哪一層

可以把這幾個 AI Engineering 名詞看成一個往上疊的 stack：

| 層級 | 關心什麼 | 核心問題 |
|---|---|---|
| Prompt Engineering | 一次 prompt | 我要怎麼跟模型說 |
| Context Engineering | 一次上下文視窗 | 哪些資料該放進來，哪些該清掉 |
| Harness Engineering | 一次 agent run | 給 agent 哪些工具、權限、完成條件 |
| Loop Engineering | 多輪自動運轉 | 怎麼讓 agent 自己一輪輪跑下去 |

Prompt 是一句話，Context 是一個視窗，Harness 是一次任務，Loop 是一個會重複運轉的系統。

這也是為什麼 Loop Engineering 不是取代前面幾層，而是建立在它們之上。沒有好的 prompt、context 和 harness，loop 只會把原本的小錯誤放大成跨多輪的錯誤。

## 一個 Loop 至少要有五個動作

一個完整 loop 不是單純排程執行一段 prompt。它至少包含五個動作：

| 動作 | 它做什麼 | 例子 |
|---|---|---|
| Discovery | 自己找這輪要做什麼 | 讀 CI failure、issue、recent commits |
| Handoff | 把任務交給 agent | 每個 finding 開一個 worktree |
| Verification | 驗證結果是否可靠 | 另一個 reviewer agent 跑測試、挑錯 |
| Persistence | 把狀態寫到外部 | 寫入 markdown、Linear、PR、state file |
| Scheduling | 下一輪什麼時候再跑 | 每天早上自動執行 |

這裡最容易被低估的是 Persistence。很多 agent workflow 看起來很聰明，但結果只存在 chat 裡。一旦 conversation 被清掉，下一輪就什麼都不記得。

所以 loop 的記憶不能只放在 context window。它要寫到 repo、state file、issue board 或 PR 裡。Agent 會忘記，但外部狀態不會。

## 六個實作零件

如果把五個動作落成實作，大概會對應到六個零件：

| 零件 | 作用 |
|---|---|
| Automation | 定時或事件觸發 loop |
| Worktree | 讓多個 agent 在不同目錄並行工作 |
| Skill | 把專案知識寫成可重複使用的規則 |
| Connector | 連接 Jira、Slack、DB、API、GitHub 等外部系統 |
| Sub-agent | 拆出 generator 和 evaluator |
| Memory | 用檔案或 board 保存跨輪狀態 |

這裡的「Skill」很關鍵。排程裡不應該塞一整坨不會維護的 prompt，而應該觸發一個可版本化、可更新的 skill。這樣專案規則、判斷標準、踩坑經驗才不會每次重新解釋。

## 最重要的設計：不要讓 Agent 評審自己

Loop Engineering 最核心的設計，不是 scheduling，而是 verification。

一個 agent 寫完 code 之後，如果再問同一個 agent「你覺得這樣可以嗎？」它很容易回答可以。不是因為它偷懶，而是因為它的上下文裡已經充滿了剛剛那套寫法的理由。

比較可靠的設計是把 generator 和 evaluator 分開：

| 角色          | 任務                               |
| ----------- | -------------------------------- |
| Generator   | 負責產生方案、寫 code、開 PR               |
| Evaluator   | 負責懷疑、執行測試、點 UI、截圖、找錯             |
| Fresh judge | 用新的模型或獨立條件判斷 stop condition 是否達成 |

Evaluator 的預設立場應該是懷疑，而不是稱讚。它不應該只讀 code 說「看起來可以」，而要真的行動：跑測試、打開頁面、點按鈕、檢查 DOM、看 screenshot。

換句話說，好的 evaluator 判斷的是「實際跑起來有沒有對」，不是「作者的意圖看起來合不合理」。

## 五種最常見的壞 Loop

Loop 出問題時，通常不是神秘錯誤，而是少了某個基本動作：

| 失敗型態 | 少了哪一步 | 問題 |
|---|---|---|
| Nodding Loop | Verification | agent 永遠自我批准 |
| Amnesiac Loop | Persistence | 每輪都忘記之前做過什麼 |
| Manual Loop | Scheduling | 還是要人手動啟動 |
| Blind Loop | Discovery | 人還是每天幫它挑任務 |
| Tangled Loop | Handoff | 多個 agent 改同一份 working tree，互相打架 |

這張表其實可以當成檢查表。你要問的不是「這個 loop 看起來酷不酷」，而是：它有沒有真的發現任務？有沒有獨立驗證？有沒有狀態檔？有沒有自動排程？有沒有隔離並行工作？

少一個，就會變成某種形式的假 loop。

## 風險與限制

Loop 會讓 generation 變得非常便宜，但它不會讓 judgment 自動變好。這也是這類系統最危險的地方。

主要風險有四個：

| 風險 | 意思 |
|---|---|
| Verification debt | 看似通過但其實沒被真正驗證的產出累積 |
| Comprehension rot | codebase 長大，但人的理解沒有同步更新 |
| Cognitive surrender | 人開始懶得判斷，全部交給 loop |
| Token blowout | loop 重試、派生 agent、跑整晚，成本失控 |

這四個風險會互相放大。產出越多，越沒時間看；越沒看，越不理解；越不理解，越依賴 loop；越依賴 loop，越容易讓它在你沒注意時跑過頭。

所以成熟的 loop 一定要有幾個硬限制：獨立 evaluator、狀態檔、預算上限、最大重試次數，以及至少一個人工 review checkpoint。

## 我的判斷

我覺得 Loop Engineering 真正值得重視的地方，不是它讓 agent 更自動，而是它逼工程師重新定義自己的工作位置。

當 code、plan、PR、fix 都變得很便宜，工程師的價值會更集中在判斷：什麼值得做、什麼不能合、哪裡必須停、哪個結果只是看起來合理。

所以我不會把 loop 理解成「把工程師替換掉」。更準確地說，它是把工程師從機械執行裡抽出來，逼你把判斷力寫進系統設計裡。

## 適合 / 不適合的使用場景

| 場景 | 是否適合 | 原因 |
|---|---|---|
| 每日 CI / issue triage | 適合 | 有固定資料源，容易排程，也容易產出狀態檔 |
| 小型重複性 bugfix | 適合 | 任務邊界清楚，適合 worktree + evaluator |
| 大型架構決策 | 不適合全自動 | judgment 密度太高，需要人主導 |
| 測試覆蓋不足的 codebase | 高風險 | evaluator 缺少可靠驗證基礎 |
| 成本敏感但沒 budget cap 的環境 | 不適合 | token blowout 風險太高 |

比較安全的開始方式，是先做一個很小的 loop：每天讀 CI / issue，整理可行動 finding，寫到 state file，不自動 merge。等 evaluator 真的抓過錯，再擴大並行度。

## 最後記住這句

Build the loop, but stay the engineer.

**設計 loop 是為了把重複工作交出去，不是把判斷力也交出去**。
真正好的 loop，不是跑得最勤，而是知道什麼時候該停、該拒絕、該等人看。

## 來源

- [Loop Engineering: The Anthropic Playbook for Designing Systems That Prompt Your Agents](https://drive.google.com/file/d/1qzKI4DKnyHRpXK1J3ATPqwaqLc0iNu-M/view)
