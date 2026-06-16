---
title: System Design Interview by Alex Xu
description: Alex Xu 系統設計面試書的讀後整理，含 RESHA 框架、書籍結構、八個經典系統案例與學習方法建議。
type: publish
status: draft
tags:
  - system-design
  - interview
  - architecture
  - learning
source: ''
related: []
pubDate: 2026-02-26T08:16:13.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

這本書是系統設計面試的事實標準教材，16 章涵蓋從單機擴展到百萬用戶的完整路徑，以及 8 個經典系統設計案例。Alex Xu 最大的貢獻不是內容本身，而是把分散式系統的知識整理成一個面試可用的、可重複的框架（RESHA）— 讓你在 45 分鐘內有結構地展示設計能力，而不是想到什麼說什麼。

> 系統設計面試不是考你知不知道答案，是考你會不會用正確的框架逐步推導出合理的架構。

## 這篇在解決什麼問題

大多數工程師的系統設計知識是碎片化的：知道 Load Balancer、知道 Cache、知道 Message Queue，但在面試時不知道從哪裡開始、第一步該問什麼問題、怎麼組織 45 分鐘的架構討論。

## 書籍結構

### Phase 1: 基礎（Ch 1-3）
- **Ch 1**: 從單機到百萬用戶的擴展路徑（LB → DB Replication → Cache → CDN → Stateless → Multi-DC）
- **Ch 2**: 容量估算（QPS、Storage、Bandwidth 的 back-of-the-envelope）
- **Ch 3**: RESHA 面試框架

### Phase 2: 核心技術（Ch 4-7）
Rate Limiter、Consistent Hashing、Key-Value Store、Unique ID Generator — 這些是分散式系統的「積木」。

### Phase 3: 經典系統（Ch 8-15）
URL Shortener、Web Crawler、Notification System、News Feed、Chat System、Autocomplete、YouTube、Google Drive — 每個案例都覆蓋一種不同的核心技術主題。

## RESHA 框架

這是整本書最重要的 takeaway，一個可以套用到任何系統設計題的結構：

| 步驟 | 內容 | 時間 |
|------|------|------|
| **R**equirements | 釐清功能需求（要做什麼）和非功能需求（QPS、latency、availability） | 5 min |
| **E**stimation | 粗估流量和儲存規模 | 5 min |
| **S**ystem | 畫出高層架構圖 | 10 min |
| **H**igh-level deep dive | 深入一兩個核心組件的設計細節 | 20 min |
| **A**dditional | 討論瓶頸、trade-off、擴展方案 | 5 min |

## 八個經典系統的核心技術點

| 系統 | 關鍵技術 |
|------|----------|
| URL Shortener | Hash + Base62、Collision resolution |
| Web Crawler | BFS、URL Frontier、Politeness、DNS cache |
| Notification | Message Queue、Push/Email/SMS channels |
| News Feed | Fan-out（Push vs Pull）、Timeline |
| Chat | WebSocket、Connection Manager、Group message |
| Autocomplete | Trie + Top K、Frequency update |
| YouTube | Transcoding pipeline、CDN、Adaptive bitrate |
| Google Drive | Delta sync、Conflict resolution、Block-level dedup |

## 建議學習方法

### 1. 主動式閱讀
每章讀完後，蓋上書：自己畫出架構圖、解釋每個組件的職責、說出 bottleneck 在哪裡、提出可能的優化方案。

### 2. 建立知識圖譜
每個系統設計都是「樂高積木」的組合：Load Balancer（高可用）+ Cache（低延遲）+ Database Replication（數據安全）+ Message Queue（解耦）+ CDN（全球分發）。

### 3. 模擬面試練習
設定 45 分鐘計時器：5 min 澄清需求 → 5 min 定義 API 和估算 → 10 min 畫高層架構 → 20 min 深入核心問題 → 5 min 討論 bottleneck。

### 4. 建立個人筆記庫
每個系統一頁，包含核心功能、架構圖、關鍵技術決策、Trade-offs。

## 高效學習建議

1. **不要只讀，要畫** — 架構圖是系統設計的核心語言
2. **關注 Trade-offs** — 沒有完美方案，只有適合的取捨
3. **理解「為什麼」** — 每個技術選擇背後都有原因
4. **從簡單開始** — 先解決核心問題，再優化
5. **練習溝通** — 面試重點是過程，不是答案

## 閱讀建議

- 這本書適合需要準備系統設計面試的人（L4-L6），但不適合零基礎 — 至少要先理解基本的網路、資料庫、快取概念。
- Ch 6（Key-Value Store）是全書最重要的章節：它把 CAP theorem、partition、replication、consistency、failure detection 全部串在一起。如果全書只能讀一章，讀這章。
- RESHA 框架的價值不完全在面試 — 這就是一套通用的系統設計方法論。任何新的技術提案如果走一遍這個流程，會少踩很多坑。
- 不需要逐章讀完：先讀 Ch 1-3 建立框架，然後跳到你最不熟悉的系統（通常是 Chat 或 YouTube），而不是從頭讀到尾。
- 章節閱讀順序建議：Ch 1-3 → Ch 6（Key-Value Store，最核心）→ Ch 8（URL Shortener，最簡單入門）→ Ch 11（News Feed，最經典的 push vs pull trade-off）→ Ch 14（YouTube，最複雜的案例，放最後吃）。
- 面試時最常犯的三個錯誤：(1) 需求階段沒問清楚就直接畫圖；(2) 只講 happy path 不討論 trade-off；(3) 只畫方塊不講流量 — 沒有 QPS 和 storage 估算的設計圖是純猜測。
- 書裡的數字（QPS 估算、latency reference）應該背下來 — 它們是在面試中建立可信度的基本工具。

## 總結

**用 RESHA 框架組織你的思考，而不是想到什麼說什麼。面試官看的是過程，不是最終答案。**
