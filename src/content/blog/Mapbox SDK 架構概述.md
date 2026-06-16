---
title: Mapbox Navigation SDK 架構概述
description: Mapbox Navigation SDK 的組件架構、Observer 模式、TripSession 狀態機及核心流程（初始化→導航→結束）的解析。
type: publish
status: draft
tags:
  - mapbox
  - navigation
  - android
  - sdk
  - architecture
source: ''
related: []
pubDate: 2023-12-31T16:00:00.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

Mapbox Navigation SDK 是一套 Android 導航庫，核心設計圍繞著觀察者模式 + 狀態機：`MapboxNavigation` 是中央入口，透過 `TripSession` 管理 FreeDrive / ActiveGuidance / Idle 三個狀態的切換，應用層只需註冊對應的 Observer 就能接收位置、路線、進度、事件等更新。元件的設計讓導航邏輯和 UI 完全解耦，同時內建 HistoryRecorder 和 Telemetry 支援偵錯和數據回報。

> MapboxNavigation 是導演，TripSession 是場記，各路 Observer 是演員 — 你只需要告訴導演拍什麼（requestRoutes），剩下的 SDK 自動排程。

## 整體架構

```
應用層
  │
  ▼
MapboxNavigationApp (單例入口)
  │
  ▼
MapboxNavigation ──┬── TripSession (狀態管理)
                    ├── LocationObserver (位置更新)
                    ├── RoutesObserver (路線更新)
                    ├── RouteProgressObserver (進度更新)
                    ├── OffRouteObserver (偏航檢測)
                    ├── HistoryRecorder (歷史記錄)
                    ├── RerouteController (重路由)
                    ├── TelemetryWrapper (數據上報)
                    └── NavigationNotificationService (通知)
```

## 主要元件

| 元件 | 職責 | 關鍵方法 |
|------|------|----------|
| `MapboxNavigationApp` | 單例入口，初始化 SDK | `setup()`, `current()` |
| `MapboxNavigation` | 核心導航引擎 | `startTripSession()`, `requestRoutes()`, `setNavigationRoutes()` |
| `TripSession` | 管理導航會話狀態 | FreeDrive → ActiveGuidance → Idle |
| `HistoryRecorder` | 記錄導航過程事件 | `startRecording()`, `stopRecording()` |
| `RerouteController` | 處理偏航後的自動重路由 | 自動觸發 |
| `TelemetryWrapper` | 事件和回饋上報 | `postCustomEvent()`, `postUserFeedback()` |

## 核心流程

### 初始化 → 導航 → 結束

```
setup() → startTripSession() → [FreeDrive 模式]
                                    │
                          requestRoutes() + setNavigationRoutes()
                                    │
                                    ▼
                          [ActiveGuidance 模式]
                                    │
                          各路 Observer 持續回調
                          位置 → 進度 → 偏航 → 重路由
                                    │
                          stopTripSession()
                                    │
                                    ▼
                              [Idle]
```

### Observer 事件的觸發鏈

| 事件 | Observer | 觸發時機 |
|------|----------|----------|
| 新位置 | `LocationObserver` | GPS 更新 |
| 路線變更 | `RoutesObserver` | 新路線設定或重路由 |
| 導航進度 | `RouteProgressObserver` | 位置沿路線前進 |
| 偏離路線 | `OffRouteObserver` | 位置偏離路線超過閾值 |

## 設計取捨

- **觀察者模式 vs callback**：SDK 選擇 Observer pattern 而非單一 callback，讓多個 UI 元件可以各自獨立訂閱同一事件（例如同時更新地圖、語音提示、距離顯示）。
- **單例 vs 多實例**：`MapboxNavigationApp` 是單例，簡化生命周期管理。代價是同一 app 無法同時跑兩條導航。
- **HistoryRecorder 的存在**：內建重播機制讓 QA 可以用歷史檔案復現 bug，這對地圖/導航類產品非常重要 — 現場問題通常難以在辦公室重現。

## 設計要點

- Observer 模式是這個 SDK 最漂亮的設計：導航引擎不關心 UI，任何 View 都可以自己訂閱需要的事件。但這也是新手最難上手的地方 — 你必須理解哪些 Observer 會依序觸發，否則 UI 狀態機的邏輯會寫亂。
- `TripSession` 的狀態轉換（FreeDrive → ActiveGuidance → Idle）是隱式的，SDK 文件對這塊的說明偏少。實際開發中很容易在「路線設定但還沒進入 ActiveGuidance」這個中間狀態踩坑。
- HistoryRecorder + Replay 是目前少見的內建功能，開發導航產品的話這個可以省掉大量 QA 時間。

## 總結

**先搞清楚 MapboxNavigation → TripSession → Observer 這個三層結構，再把導航流程畫出來，SDK 的 API 就會從「一堆 callback」變成「一條清楚的事件鏈」。**
