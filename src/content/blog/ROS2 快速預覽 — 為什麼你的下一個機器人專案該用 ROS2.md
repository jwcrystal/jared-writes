---
title: ROS2 快速預覽 — 為什麼你的下一個機器人專案該用 ROS2
description: >-
  面向團隊的 ROS2 技術推廣文章。從 ROS1 的結構性限制出發，說明 ROS2
  在架構、通訊、安全與跨平台上的根本改進，並提供團隊導入的評估框架與兩週上手路徑。
type: publish
status: draft
tags:
  - ros2
  - robotics
  - middleware
  - architecture
  - team-sharing
source:
  - docs.ros.org
  - design.ros2.org
  - ubuntu.com/tutorials/getting-started-with-ros-2
  - Science Robotics (2022)
related: []
pubDate: 2026-06-11T16:00:00.000Z
updatedDate: 2026-06-11T16:00:00.000Z
---
  - "Science Robotics (2022) - ROS 2: Design, architecture, and uses in the wild"
---

# ROS2 快速預覽 — 為什麼你的下一個機器人專案該用 ROS2

## 一句話總結

ROS2 是用工業級 DDS 標準重新設計的去中心化機器人框架 — 它保留了 ROS1 的成功心智模型，同時解決了安全性、即時性、跨平台和分散式部署的根本問題。

---

## 從一個問題開始：ROS1 為什麼需要被重寫？

ROS1 是機器人領域最成功的開源框架之一，全球數千個實驗室用它做研究。但它誕生於 2007 年，設計時有一個明確的前提：**這是給單一機器人、單一電腦、研究室環境用的**。

當機器人開始走進工廠、倉庫、醫院和道路上時，幾件事變得無法迴避：

| ROS1 的限制 | 為什麼在生產環境是問題 |
|---|---|
| 集中式 ROS Master | 單點故障，多機器人協作時一掛全掛 |
| 自定義 TCP 通訊 | 無 QoS 保證、無加密、無法穿越複雜網路 |
| 無內建安全機制 | 任何人連上網路就能收發任意 topic |
| 僅支援 Linux | 無法在 Windows/Mac 開發或在其他平台部署 |
| 無即時性保證 | 控制迴路無法保證延遲上限 |
| Nodelet API 獨立 | 進程內通訊和跨進程通訊是兩套寫法 |

這些不是 bug，是設計取捨。ROS1 選擇了彈性，犧牲了生產級需求。ROS2 的任務就是在保留彈性的前提下，補上這些缺口。

---

## ROS2 做對了什麼：三項架構級變革

### 變革一：DDS 取代自定義傳輸層

這是 ROS2 最根本的變化。ROS1 用自己發明的 TCPROS/UDPROS 協議做節點間通訊，ROS2 改用 OMG 國際標準的 **Data Distribution Service（DDS）**。

DDS 不是 ROS 生態的東西 — 它是一個已經在航空、國防、醫療、電網等領域驗證了二十年的工業級 pub/sub 標準。這意味著 ROS2 一出生就繼承了：

- **QoS 策略**：可靠傳輸 vs 盡力傳輸、截止時間、存活檢測、歷史資料保留 — 全部可配置
- **自動發現**：節點啟動後自動找到網路上的其他節點，不需要中央註冊中心
- **安全框架**：DDS-Security 規範提供認證、加密、存取控制
- **多供應商支援**：Fast-DDS、CycloneDDS、RTI Connext 可互換

### 變革二：消滅 ROS Master

ROS1 的架構中，所有節點啟動後必須向唯一的 `roscore`（含 ROS Master）註冊。Master 掛了，整個系統無法通訊。

ROS2 完全去中心化。節點透過 DDS 內建的發現協議（SPDP/SEDP）直接找到彼此，不需要任何中央程序。這對多機器人協作、網路分區容錯、動態加入/離開等場景是決定性的改進。

### 變革三：原生安全與即時能力

ROS1 的 topic 是明文的，任何知道 IP 的人都可以訂閱或發布。ROS2 透過 DDS-Security 提供：

- **認證**：只有持有憑證的節點能加入通訊域
- **加密**：傳輸層加密，topic 內容不可被竊聽
- **存取控制**：細粒度控制哪個節點能讀/寫哪個 topic

同時，ROS2 的 `rclcpp` 層支援即時排程器（static single-threaded executor），搭配 RTOS kernel 可以實現確定性延遲的控制迴路。

---

## ROS1 vs ROS2：一張表看懂

| 面向      | ROS1 (Noetic)      | ROS2 (Jazzy)                |
| ------- | ------------------ | --------------------------- |
| 通訊層     | 自定義 TCPROS         | **DDS 標準**                  |
| 發現機制    | 集中式 Master         | **去中心化對等發現**                |
| 安全性     | 無                  | 認證 + 加密 + 存取控制              |
| 即時性     | 不支援                | 可搭配 RTOS 實現                 |
| 多節點同進程  | ❌                  | ✅ 元件式組合                     |
| 跨平台     | Linux              | **Linux / macOS / Windows** |
| Launch  | XML                | **Python**                  |
| 生命週期    | 無                  | 四態狀態機                       |
| 建置系統    | catkin             | **ament + colcon**          |
| Actions | 第三方 actionlib      | **原生支援**                    |
| 目前狀態    | **已 EOL（2025/05）** | 活躍開發中                       |

---

## 核心概念：五個你必須知道的名詞

ROS2 保留了 ROS1 的概念詞彙，但每個都變得更乾淨：

```
Node（節點）       → 基本計算單元，一個節點做一件事
Topic（主題）      → 非同步 pub/sub，單向資料流（感測器資料）
Service（服務）    → 同步 req/res，即時查詢（獲取地圖）
Action（動作）     → 非同步目標導向，含進度回饋與取消（導航任務）
Parameter（參數）  → 節點級配置，變更時推送通知
```

選擇通訊模式的簡單規則：
- 連續資料流（雷射、里程計）→ **Topic**
- 一次性查詢（獲取地圖、設定參數）→ **Service**
- 長時間任務（導航、抓取、充電）→ **Action**

---

## 五層分層架構

ROS2 的架構比 ROS1 更模組化，每一層都可以獨立替換：

```
┌─────────────────────────────────┐
│  Application（你的機器人程式）     │ ← Layer 5
├─────────────────────────────────┤
│  rclcpp (C++)  │  rclpy (Python) │ ← Layer 4: Client Libraries
├─────────────────────────────────┤
│         rcl（純 C 核心）          │ ← Layer 3: Core Infrastructure
├─────────────────────────────────┤
│    rmw（中介軟體抽象介面）         │ ← Layer 3: 可插拔介面
├─────────────────────────────────┤
│  Fast-DDS │ CycloneDDS │ Zenoh  │ ← Layer 2: Middleware 實現
├─────────────────────────────────┤
│     ament / colcon / rosdep      │ ← Layer 1: Build System
└─────────────────────────────────┘
```

`rmw`（ROS Middleware Interface）是整個設計的關鍵抽象層。你可以切換底層 DDS 實現而不改一行應用程式碼。

---

## 團隊導入評估

### 什麼情況下該用 ROS2

- 新專案從零開始
- 需要多機器人通訊
- 有安全性或即時性要求
- 需要在 Windows/macOS 上開發
- ROS1 專案已到重構階段

### 什麼情況下可以緩一緩

- ROS1 專案穩定運行且無遷移需求
- 依賴的周邊套件（特定硬體驅動、舊演算法庫）只有 ROS1 版本
- 團隊對 ROS1 非常熟悉且專案週期短

### 遷移路徑

如果現有 ROS1 專案需要遷移，官方提供了 `ros1_bridge` 作為過渡方案，允許 ROS1 和 ROS2 節點在同一個系統中共存通訊，可以逐步替換。

---

## 從零到第一個節點：兩週上手路徑

### 第 1-2 天：安裝 + 概念驗證

```bash
# Ubuntu 24.04 + ROS2 Jazzy
sudo apt install ros-jazzy-desktop
source /opt/ros/jazzy/setup.bash

# 啟動 turtlesim 模擬器，用 CLI 探索
ros2 run turtlesim turtlesim_node
ros2 node list
ros2 topic echo /turtle1/pose
```

### 第 3-5 天：第一個 ROS2 套件

```python
# my_pkg/my_pkg/talker.py
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class Talker(Node):
    def __init__(self):
        super().__init__('talker')
        self.pub = self.create_publisher(String, 'chatter', 10)
        self.timer = self.create_timer(0.5, self.callback)

    def callback(self):
        msg = String(data='Hello ROS2!')
        self.pub.publish(msg)
        self.get_logger().info(f'Published: {msg.data}')

def main():
    rclpy.init()
    rclpy.spin(Talker())

if __name__ == '__main__':
    main()
```

```bash
colcon build --packages-select my_pkg
source install/setup.bash
ros2 run my_pkg talker
```

### 第 6-10 天：Service + Action + Launch

- Service Server/Client 實現同步請求
- Action Server/Client 處理非同步長時間任務
- Python Launch 檔案統籌多節點啟動

### 第 10-14 天：TF2 + Gazebo + rosbag

- TF2：座標轉換系統，機器人模型骨架
- Gazebo：物理模擬環境
- rosbag：資料錄製與回放，除錯和重現問題的核心工具

---

## 給團隊的七條實戰建議

1. **新專案直接用 ROS2，不要考慮 ROS1** — ROS1 Noetic 已於 2025 年 5 月 EOL
2. **Python 寫原型，C++ 寫關鍵路徑** — 兩者 API 高度對稱，團隊不需要二選一
3. **固定發行版，不要追 Rolling** — LTS 版本（Jazzy ↔ Ubuntu 24.04）是團隊開發的穩定基底
4. **DDS 預設值就夠用** — 不需要在專案初期切換 middleware 或調 QoS
5. **把 `ros2` CLI 變成肌肉記憶** — `node list`、`topic echo`、`service call` 是最快的除錯手段
6. **`ros2 doctor` 排錯第一站** — 環境問題一鍵診斷
7. **初學者繞開進階主題** — 即時核心、自定義 middleware、DDS 深度調參留給需要它們的場景

---

## 常見顧慮與回應

**Q: ROS2 穩定了嗎？**
A: 核心框架（rcl、rmw、rclcpp、rclpy）已經非常穩定。周邊生態（Navigation2、MoveIt2）仍在快速迭代，但已可用於生產。

**Q: 學習曲線會比 ROS1 陡嗎？**
A: 核心概念不變，API 更現代、更一致。對新手來說 ROS2 反而更好學 — OOP 強制節點結構、Python launch 比 XML 直覺、CLI 工具更完善。

**Q: 團隊裡有用 macOS/Windows 的同事怎麼辦？**
A: ROS2 原生支援三大平台，這在 ROS1 時代是做不到的。macOS 開發者可以直接參與，Windows 上也能跑核心功能。

**Q: 效能比 ROS1 好嗎？**
A: 取決於場景。DDS 引入一定開銷，但在高 throughput 場景下，ROS2 的零拷貝傳輸（shared memory + loaned messages）反而能顯著優於 ROS1 的 TCP 序列化。

---

## 來源

- [ROS2 官方教學文件](https://docs.ros.org/en/rolling/Tutorials.html)
- [ROS2 Design 文件](https://design.ros2.org) — 每個架構決策的設計理由
- [Ubuntu: Getting Started with ROS2](https://ubuntu.com/tutorials/getting-started-with-ros-2)
- [Science Robotics (2022): ROS 2: Design, architecture, and uses in the wild](https://www.science.org/doi/10.1126/scirobotics.abm6074)
- [ROS2 Architecture DeepWiki](https://deepwiki.com/ros2/ros2/2.2-ros-2-system-architecture)
