---
title: Live555 和 ZLMediaKit 比較
description: 兩個開源流媒體方案 Live555 與 ZLMediaKit 的功能、性能、協議支援與適用場景對比。
type: knowledge
status: evergreen
tags:
  - streaming
  - rtsp
  - webrtc
  - live555
  - zlmediakit
  - media-server
source: ''
related: []
pubDate: 2025-08-15T00:53:24.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# Live555 和 ZLMediaKit 比較

## 核心摘要

Live555 和 ZLMediaKit 都是 C++ 寫的開源流媒體解決方案，但定位完全不同。Live555 是一個**經典的 RTSP 流媒體庫**，適合學術研究和嵌入式設備，協議支援窄（RTSP/RTP）、部署複雜。ZLMediaKit 是**全協議流媒體服務框架**，同時支援 RTSP、RTMP、WebRTC、SRT、GB28181，效能更高、文件更好、授權更寬鬆（MIT），適合商業應用和大規模部署。選 Live555 是因為你被限制在 RTSP only 而且需要極度輕量，其他的都用 ZLMediaKit。

## 一句話理解

**Live555 = 20 年前的 RTSP 老兵，ZLMediaKit = 現代的 all-in-one 流媒體服務器。**

## 功能對比

| 特性 | Live555 | ZLMediaKit |
|------|---------|------------|
| 開發語言 | C++ | C++ |
| 協議支援 | RTSP, RTP, RTCP, SIP | RTSP, RTMP, SRT, HTTP-FLV, WebRTC, GB28181 |
| 性能 | 適合小規模應用 | 高性能，適合大規模 |
| 易用性 | 配置複雜，需要技術背景 | API 簡單，文檔豐富 |
| 授權 | LGPL | MIT |
| 擴展性 | 功能固定，擴展有限 | 模組化設計，易擴展自訂 |
| 社群 | 相對較小 | 活躍，持續更新 |

## 適用場景

| 場景 | 推薦 |
|------|------|
| RTSP only 嵌入式設備 | Live555 |
| 監控系統（GB28181） | ZLMediaKit |
| 直播平台（RTMP/HLS/WebRTC） | ZLMediaKit |
| 學術研究 / 協議學習 | Live555 |
| 商業產品 | ZLMediaKit（MIT，無 copyleft 限制） |

## 我的判斷

- 如果你的需求只是播 RTSP 流，Live555 可以做到，但 ZLMediaKit 也可以做到而且更容易。除非你的硬體資源極度受限（嵌入式 IoT），否則沒有理由選 Live555。
- ZLMediaKit 的 MIT 授權對商業產品是關鍵優勢。LGPL（Live555）要求修改後的程式碼開源，對閉源商業產品是合規風險。
- GB28181 協議支援是 ZLMediaKit 在中國市場的核心競爭力——這是中國安防監控的國家標準協議，Live555 完全沒有。
- WebRTC 支援是 ZLMediaKit 對現代應用場景的關鍵對齊：瀏覽器原生支援的超低延遲直播，Live555 做不到。

## 最後記住這句

**除非你被限制在 RTSP-only 的嵌入式環境，否則選 ZLMediaKit。它快、支援多協議、MIT 授權、有活躍社群——在 2025 年這就是流媒體開源方案的預設選擇。**
