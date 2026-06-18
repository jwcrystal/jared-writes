---
title: Anthropic 工程師的 6 個 Claude 提示詞
description: >-
  XDA 記者整理 Anthropic 工程師的 6 個實戰提示詞——不是教你「怎麼對 AI 下更好的指令」，而是讓 AI
  反過來引導你：考你理解、問你需求、幫你記憶。
type: publish
status: draft
tags:
  - claude
  - prompt-engineering
  - anthropic
  - claude-code
  - AI-tools
source: 'https://www.cw.com.tw/article/5141619'
publish_target: ''
published_url: ''
pubDate: 2026-06-17T16:30:00.000Z
updatedDate: 2026-06-17T17:00:00.000Z
---
如果你用 Claude Code 開發，大概遇過這些狀況：不知道它剛才改了什麼、規格寫不清楚就開工結果做白工、每次重複教它同樣的流程、session 一結束學到的東西全部 reset。

這些問題不一定是你不夠熟練。更常是——你一直在單向下指令，但 Claude 其實可以反過來引導你。

這篇整理 XDA 記者 Mahnoor Faisal 從 Anthropic 工程師 Thariq 和團隊成員挖出來的 6 個實戰提示詞。它們的共同點不是「把 prompt 寫得更精準」，而是**設計 feedback loop，讓 AI 反過來對你提問、教學、記憶**。

---

## 為什麼這件事值得看

多數人跟 AI 協作的方式還停留在「我下指令 → AI 執行 → 我驗收」。這在簡單任務上沒問題，但一旦任務變複雜（多步驟開發、跨 session 協作、團隊共享），單向指令的缺陷就很明顯：

- 你不知道 AI 做了什麼決策、為什麼那樣做
- 規格沒想清楚就開工，做到一半才發現方向不對
- 每次新 session 都要從零開始教
- 團隊成員之間無法共享有效的 prompt 和工作流程

這 6 個提示詞剛好對應這幾個痛點——不是什麼深奧的理論，就是貼在 Claude Code 裡直接能用的文字。

---

## 核心內容

### 學習與驗證類

#### 1. 讓 Claude Code 用大白話解釋運作流程

Thariq 為非技術背景的妹妹設計的提示詞。它把實際工作交給背景代理執行，同時啟動一個唯讀的「探索代理」用白話解釋原理。

```
這是我的提示詞：「【在這裡輸入你的任務需求】」

請幫我啟動一個非同步背景代理來執行這項工作，
並在它工作的過程中定期查看進度，然後幫我摘要目前發生了什麼事。

我完全沒有技術背景，所以請用最簡單的大白話為我做摘要。
請利用「探索代理」（Explore Agent）向我解釋另一個代理
正在處理的事情背後的運作原理，好讓我在過程中順便學習。
如果背景代理遇到任何錯誤，請立刻停下來告訴我，並引導我修復它。

請記住，我沒有任何技術背景，任何技術術語對我都沒有幫助。
```

**適合：** 帶新人、非技術協作者、想理解 Claude Code 決策邏輯的開發者。
**注意：** 需要 Claude Code 支援背景代理機制，非所有 AI 編輯器可用。

#### 2. 讓 Claude 一直考你，直到你真的學會

Anthropic 工程師 Suzanne 設計。Claude 一次只教一個概念，然後用 `AskUserQuestion` 出題考你，通過後才進入下一步。`/goal` 確保 session 在你真正理解前不會結束。

```
你是一位教學成效極高的睿智老師，你的目標是確保使用者
能夠深入理解這次工作階段中的所有內容。

請在每個步驟循序漸進地教學，不要等到最後再一次性說明所有內容。
在進入下一個階段之前，你必須先確認使用者已經完全掌握
目前階段的所有重點。

為了瞭解使用者目前的理解程度，請主動要求使用者
先用自己的話重新說明自己的理解。

請使用 AskUserQuestion 透過開放式問題或選擇題來測驗使用者，
務必不斷變換正確答案的位置，作答完成之前不要公布答案。

/goal 在你確定使用者已經證明自己瞭解清單上所有項目之前，
這個工作階段不應該結束。
```

**適合：** 學習新框架、Code Review 時確認理解、想避免「好像懂了但其實沒懂」的人。
**注意：** 學習節奏偏慢，不適合趕時間的場景。

---

### 規劃與產出類

#### 3. 動工之前，先讓 Claude 對你進行需求訪談

反轉傳統「你給需求 → AI 開工」的模式。Claude 讀你的 spec 草稿後連環追問邊緣案例、技術權衡、UI 決策，徹底問完才寫最終規格。

```
請閱讀這份@SPEC.md，使用 AskUserQuestionTool
詳細問我關於這裡面的任何事情，包括技術實作、UI & UX、
隱憂、權衡等。請確保提出的問題不是那種顯而易見的表面問題。

務必非常深入，持續不斷地問我，直到細節完全齊全為止，
再把最終的規格書（Spec）寫入檔案中。
```

**適合：** 需求模糊的專案初期、跨團隊溝通前的規格釐清。
**注意：** 問答過程可能需要 10–20 分鐘，適合排專門的規劃 session 來做。

#### 4. 把開發計畫做成 HTML 網頁

Thariq 認為 Markdown 超過 100 行就沒人想讀了，全部改用 HTML 輸出——真正的圖表、語法突顯的程式碼、可點擊的控制項，部署後丟連結就能分享。

```
請在一個 HTML 檔案中建立一份詳盡的實作計畫。
請務必在裡面製作一些原型（Mock-ups）、展示數據流（Data Flow），
加入我可能需要審查的重要程式碼片段。
請確保內容很容易閱讀、消化。
```

**適合：** 需要跟非技術 stakeholders 溝通的規劃文件、取代靜態簡報。
**注意：** HTML 檔案需要托管或部署才能分享連結；純個人筆記用 Markdown 反而更輕量。

---

### 自動化與記憶類

#### 5. 把重複性任務固化成「技能」

用一句提示詞讓 Claude 自動建立可攜帶的「技能」檔案，以後用快捷鍵就能觸發整串流程（如跑 linter → 跑測試 → 寫 commit）。

```
請為這個專案建立一個 [/ship] 技能，
用來執行 [執行 linter 語法檢查和測試，然後草擬一份 commit 訊息]。
```

**適合：** 團隊共享的工作流程、每次開發循環都要做的重複步驟。
**注意：** 技能是 Claude Code 專屬功能，跨平台移植需另尋方案。

#### 6. 自動捕捉對話該記住的事

Session 結束前讓 Claude 自動摘要重點，建議寫入 `CLAUDE.md`——下次啟動時自動讀取，保持跨 session 的專案記憶。

```
摘要我們這個 Session 做了什麼，建議有哪些內容應該新增到 CLAUDE.md 中。
```

**適合：** 長期維護的專案、多人協作環境。
**注意：** 需要定期清理 `CLAUDE.md`，否則會累積過時資訊。

---

## 六招適用場景總覽

| #   | 招式           | 主要解決問題      | 適合誰                   | 限制             |
| --- | ------------ | ----------- | --------------------- | -------------- |
| 1   | 大白話背景代理      | 不理解 AI 在做什麼 | 非技術背景、初學者             | 需背景代理支援        |
| 2   | 考試直到學會       | 似懂非懂        | 學習者、需要 Code Review 的人 | 節奏慢            |
| 3   | AI 需求訪談      | 規格模糊、做到一半翻車 | PM、開發者                | 需 10-20 分鐘專門時間 |
| 4   | HTML 計畫書     | 長文件沒人讀      | 需跨角色溝通的團隊             | 需托管才能分享        |
| 5   | 技能固化         | 重複勞動、步驟不一致  | 團隊開發者                 | Claude Code 限定 |
| 6   | 跨 session 記憶 | 每次重來、無法累積   | 長期專案、多人協作             | 需定期清理記憶檔案      |


---

## 風險與限制

- **生態鎖定：** 多數提示詞依賴 Claude Code 特有的工具（`AskUserQuestionTool`、背景代理、技能系統），移植到 Cursor、Windsurf 或其他 AI 編輯器可能需要大幅調整
- **學習成本：** 第三招的需求訪談和第二招的考試機制，初期使用時會明顯拉長 session 時間，需要習慣「先花時間省時間」的節奏
- **資訊過期：** 第六招的 `CLAUDE.md` 如果不定期審視和清理，反而會變成專案的雜訊來源
- **團隊適配：** 第五招的技能可攜帶，但前提是團隊統一使用 Claude Code；混合工具鏈的團隊共享難度較高

## 最後記住這句

最好的 prompt 不是「把指令寫到完美」，而是設計一個讓 AI 反過來引導你的流程——考你、問你、教你的 AI，比乖乖聽話的 AI 有用得多。

## 來源

- **XDA 原文**：Mahnoor Faisal, *[I borrowed Claude prompts from Anthropic engineers and immediately stopped wasting time on bad ones](https://www.xda-developers.com/i-borrowed-claude-prompts-from-anthropic-engineers/)*, Jun 15, 2026
- **中文編譯**：天下雜誌, *[偷學Anthropic工程師！6個好用的Claude提示詞](https://www.cw.com.tw/article/5141619)*, Jun 2026
- **Thariq Shihipar**：Anthropic Claude Code 團隊工程師，個人網站 [thariq.io](https://www.thariq.io/)，X [@trq212](https://x.com/trq212)
- **Suzanne**：Anthropic 工程師，Thariq 的同事，第 2 招 prompt 的原作者
- **Thariq「HTML is the new markdown」**：X 貼文 (May 8, 2026) 與範例畫廊 [thariqs.github.io/html-effectiveness](https://thariqs.github.io/html-effectiveness)；相關 podcast 收錄於 [How I AI](https://www.chatprd.ai/how-i-ai/claude-code-anthropic-thariq-shihipar-on-replacing-markdown-with-html)
- **Anthropic 官方提示詞庫**：第 5 招（技能）與第 6 招（CLAUDE.md 記憶）的 prompt 來源
