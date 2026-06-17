---
title: ROS2 開發者必懂：DDS QoS 配置的實戰取捨
description: DDS 是 ROS2 底層的通訊引擎。這篇用實戰場景拆解 DDS 的 QoS 設計取捨，幫你避開最常見的延遲陷阱和啟動順序問題。
type: publish
status: draft
tags:
  - dds
  - ros2
  - middleware
  - qos
  - communication
  - architecture
source:
  - OMG DDS 1.4 Spec
  - docs.ros.org
  - design.ros2.org
  - github.com/eclipse-cyclonedds
  - fast-dds.docs.eprosima.com
publish_target: ''
published_url: ''
pubDate: 2026-06-16T07:00:00.000Z
updatedDate: 2026-06-16T07:00:00.000Z
---
# ROS2 開發者：DDS QoS 配置的實戰取捨

一個機器人工程師花了三天除錯。

系統在實驗室跑得好好的，一上產線，LiDAR 數據偶爾飆到 200ms 延遲。查了網路、CPU、記憶體，全部正常。重啟有時候好，有時候不好。最後發現兇手是一行 QoS 設定——他在 100Hz 的感測器 topic 上用了 RELIABLE。

歷史緩衝區滿了，寫入端阻塞，整條管線跟著卡。

這不是個案。ROS2 從 ROS1 換到 DDS 通訊層之後，把配置的權力交給了開發者，但大多數文件只告訴你「有 QoS 可以用」，沒講清楚每個選項的代價。結果就是：**大部分 ROS2 開發者遇到的「莫名延遲」和「偶爾連不上」，根源都是 QoS 配置不當。**

這篇不講 DDS 的 21 種策略。只講你真正需要的三組，以及它們在四種場景下怎麼選。

---

## 先理解一件事：ROS2 底下跑的是 DDS

```
┌─────────────────────┐
│   ROS2 Application   │  ← rclcpp / rclpy
├─────────────────────┤
│   RMW 抽象層         │  ← 可更換底層 DDS 實現
├─────────────────────┤
│   DDS 實現           │  ← Cyclone DDS / Fast DDS / RTI Connext
├─────────────────────┤
│   傳輸層              │  ← UDP / TCP / Shared Memory
└─────────────────────┘
```

RMW 是 ROS2 的關鍵設計——上層代碼跟底層 DDS 解耦，任何 DDS 產品只要實現 RMW 介面就能塞進去。這也是為什麼 ROS2 同時支援 Cyclone DDS、Fast DDS、RTI Connext 多種實現。

DDS 本身是一個 OMG 標準，核心概念是**無中心化的、以數據為中心的發布-訂閱模型**。節點之間透過 UDP 多播自動發現彼此，不需要 ROS Master 那種中心化服務。這解決了 ROS1 的單點故障問題，但也帶來了新的複雜度。

---

## 三組 QoS，解決 90% 的問題

### RELIABILITY：能送就送，還是一定要送到？

```
BEST_EFFORT  ── 能送就送，丟了不管
RELIABLE     ── 一定要送到，送不到就重傳
```

**BEST_EFFORT 不是比較差的選項。它是高頻場景的正確選擇。**

LiDAR、Camera、IMU 這些感測器，丟一幀沒關係，但阻塞會讓整條管線延遲爆炸。用 RELIABLE 的話，歷史緩衝區很快填滿，寫入端開始阻塞——而且這個問題不是每次都出現，只在 buffer 滿的時候觸發，很難復現。

控制指令和重要狀態才用 RELIABLE。一定要送到，送不到就該報錯。

### DURABILITY：晚加入的節點怎麼辦？

```
VOLATILE          ── 不保留歷史，晚加入就拿不到
TRANSIENT_LOCAL   ── 保留最後一份數據給新來的人
```

**正確的 DURABILITY 配置讓你的系統對啟動順序免疫。**

地圖伺服器先啟動，導航節點後啟動——如果沒有 TRANSIENT_LOCAL，導航節點永遠拿不到地圖。唯一的解法是保證啟動順序，但這種依賴不會寫在任何文件裡。

地圖、靜態參數、URDF 模型用 TRANSIENT_LOCAL。即時感測數據用 VOLATILE——上一幀的數據對新節點沒有意義。

### DEADLINE：遲到跟丟失沒兩樣

```
DEADLINE = 50ms  →  50ms 內沒收到，觸發 DeadlineMissed 回調
```

**沒有 DEADLINE 監控的控制迴路是盲飛。**

RELIABLE 確保「送到」，DEADLINE 確保「在時間內送到」。對於控制迴路來說，遲到的指令跟丟失沒有分別。50ms 內沒收到控制指令，你的機器人可能已經撞牆了，但你的程式還以為一切正常。

---

## 四種場景，四種配法

**感測器（LiDAR / Camera / IMU）**：BEST_EFFORT + VOLATILE。丟幀可以，延遲不行。

```cpp
rclcpp::QoS(10).best_effort().durability_volatile();
```

**控制指令**：RELIABLE + DEADLINE。一定要到，而且要在時間內到。

```cpp
rclcpp::QoS(10).reliable().deadline(std::chrono::milliseconds(50));
```

**靜態數據（地圖 / 參數 / 模型）**：RELIABLE + TRANSIENT_LOCAL。後啟動的節點必須拿到。

```cpp
rclcpp::QoS(1).reliable().transient_local();
```

**同機高頻傳輸**：透過 DDS XML 配置啟用 Shared Memory，零拷貝通訊。車載電腦多進程共享感測器數據時特別有用。

---

## 跨機器連不上？先查這個

DDS 預設用 UDP 多播（224.0.0.0/24），只在同一廣播域內有效。跨子網需要配置 Discovery Server 或 Fast DDS 的靜態發現機制。

**跨機器通訊不穩時，先檢查網路環境，不要急著怪防火牆。**

另一個常見問題：Domain ID 是實體隔離（不同 ID 完全不通），Partition 是邏輯隔離（同 Domain 內分組）。多機器人系統中，用 Domain ID 做物理隔離，Partition 做邏輯分組。

---

## DDS 實現怎麼選？

| 實現 | 特點 | 適合 |
|-----|------|------|
| Cyclone DDS | 輕量、ROS2 默認 | 通用開發、資源受限環境 |
| Fast DDS | 功能豐富、配置彈性大 | 需要 Discovery Server、複雜拓撲 |
| RTI Connext | 效能頂級、完整技術支援 | 安全認證、工業/汽車量產 |

**開發和生產用同一種實作。** 如果你在 CI 用 Cyclone、生產跑 Fast DDS，你遲早會遇到只在其中一邊出現的問題。

---

## 如果你只記得一件事

QoS 不是「怎麼配比較進階」的問題。它是你的系統設計的一部分——感測器用 BEST_EFFORT，控制指令用 RELIABLE + DEADLINE，靜態數據用 TRANSIENT_LOCAL。

剩下的都是細節。

> 如果你想看更完整的 DDS 架構、QoS 策略、DDS 實現差異，以及 ROS2 中的典型應用場景，我另外整理了一份延伸版筆記：[[ROS2 開發者：DDS QoS 配置的實戰取捨]]。

---

## 來源

- OMG DDS 1.4 規格
- ROS 2 Documentation: About QoS Settings（docs.ros.org）
- Eclipse Cyclone DDS 官方文件（github.com/eclipse-cyclonedds）
- eProsima Fast DDS 文件（fast-dds.docs.eprosima.com）
- ROS 2 Design: ROS 2 on DDS（design.ros2.org）
