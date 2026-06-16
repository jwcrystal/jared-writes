---
title: Kotlin Coroutines — lifecycleScope 與 suspend 函數
description: >-
  Kotlin 協程在 Android 中的核心用法：lifecycleScope.launch(Dispatchers.IO) 的非同步執行模式，以及
  suspend 函數的暫停與恢復機制。
type: publish
status: draft
tags:
  - kotlin
  - coroutines
  - android
  - async
  - lifecycle
source: ''
related: []
pubDate: 2024-10-15T05:31:12.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# Kotlin Coroutines — lifecycleScope 與 suspend

Kotlin 協程在 Android 開發中有兩個核心機制需要掌握：`lifecycleScope.launch(Dispatchers.IO)` 和 `suspend` 函數。前者解決的是在哪個執行緒跑、何時自動取消（配合 Activity/Fragment 生命週期）。後者解決的是非同步程式碼寫起來像同步（暫停不阻塞主執行緒）。

> **Dispatchers.IO 決定在哪跑，lifecycleScope 決定何時停，suspend 決定怎麼寫起來像同步。**

## lifecycleScope.launch(Dispatchers.IO)

```kotlin
lifecycleScope.launch(Dispatchers.IO) {
    val result = makeNetworkRequest()        // 在 IO 執行緒執行
    withContext(Dispatchers.Main) {
        textView.text = result               // 切回 Main 更新 UI
    }
}
```

三個關鍵組件：

| 組件 | 作用 |
|------|------|
| `lifecycleScope` | 綁定 Activity/Fragment 生命週期，銷毀時自動取消協程 |
| `launch` | 建立並啟動協程，返回 Job 物件 |
| `Dispatchers.IO` | 指定在 IO 執行緒池執行 |

### 有加和沒加 Dispatchers.IO 的差別

| | `launch(Dispatchers.IO)` | `launch()` (預設 Main) |
|------|--------------------------|----------------------|
| 執行緒 | IO 執行緒池 | 主執行緒 |
| 阻塞 UI | 不會 | 會，可能 ANR |
| 適用場景 | 網路、檔案 I/O | 輕量計算 |

不加 `Dispatchers.IO` 的話協程雖然是非同步的，但仍然在主執行緒執行 — 長時間操作一樣會卡 UI。

## suspend 函數

```kotlin
suspend fun fetchData(): String {
    delay(2000)  // 暫停 2 秒，不阻塞執行緒
    return "result"
}
```

關鍵特性：
- 只能在協程或其他 suspend 函數中呼叫
- `delay()` 是 suspend 版本，暫停協程但不阻塞執行緒 — 和 `Thread.sleep()` 完全不同
- 寫起來像同步程式碼，但執行時可被暫停讓出執行緒給其他協程

## 分析與建議

- `lifecycleScope.launch(Dispatchers.IO)` + `withContext(Dispatchers.Main)` 是 Android 非同步操作的最佳實踐組合。它同時解決了三個問題：執行緒管理、生命週期安全、記憶體洩漏。
- 最常見的坑是忘記切換回 Main 更新 UI。協程在 IO 執行緒跑完後，如果直接操作 UI 元件，會拋出 `CalledFromWrongThreadException`。
- `lifecycleScope` 比 `GlobalScope` 安全千萬倍。永遠不要用 `GlobalScope` — 協程不會被自動取消，記憶體洩漏的溫床。
- suspend 函數的核心價值不是「非同步」，而是讓非同步程式碼長得像同步。這大幅降低了回調地獄和狀態管理的複雜度。

## 總結

**`lifecycleScope.launch(Dispatchers.IO)` 決定協程的生死和位置，`suspend` 讓你用同步的寫法處理非同步邏輯。兩個加在一起，Android 的非同步開發從「回調地獄」變成「看起來像順序執行」。**
