---
title: MySQL 架構基礎
description: MySQL 核心架構四層模型（連接層、服務層、儲存引擎層、檔案系統層）、B+ 樹索引原理、以及 InnoDB 的事務機制概述。
type: knowledge
status: evergreen
tags:
  - mysql
  - database
  - architecture
  - btree
  - innodb
source: ''
related:
  - 常用業務存儲系統
  - 表設計的18條軍規
pubDate: 2024-06-21T08:58:20.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

## 核心摘要

MySQL 的架構分四層：**連接層**管連線和認證，**服務層**做解析、優化和執行，**儲存引擎層**負責實際資料的讀寫（InnoDB 是預設王者），**檔案系統層**把資料落地到磁盤。理解這四層的分工，就理解了為什麼一條 SQL 從客戶端送到 MySQL 後要經過這麼多步驟——以及為什麼說 MySQL 的性能瓶頸通常在儲存引擎層。

## 一句話理解

**一條 SQL 的旅程：連接 → 解析 → 優化 → 執行 → InnoDB 讀寫 → 磁盤。優化發生在服務層，瓶頸在儲存引擎層，持久性靠 redo log。**

## 四層架構

| 層級 | 功能 | 關鍵元件 |
|------|------|----------|
| 連接層 | 客戶端連接管理、身份驗證 | Connection Pool |
| 服務層 | SQL 解析、查詢優化、執行計畫 | Parser, Optimizer, Query Cache（已廢棄） |
| 儲存引擎層 | 資料實際儲存與檢索 | InnoDB（預設）, MyISAM, Memory |
| 檔案系統層 | 將資料寫入磁盤 | redo log, undo log, data files |

## B+ 樹索引

MySQL InnoDB 的索引底層是 B+ 樹，核心特性：
- 所有資料存在葉子節點，內部節點只存鍵值
- 葉子節點透過雙向鏈表串聯，支援高效範圍查詢（`BETWEEN`, `>`, `<`）
- 主鍵索引（聚簇索引）的葉子節點直接存整行資料
- 二級索引的葉子節點存主鍵值，查詢需回表

InnoDB 強烈建議用自增主鍵：無序插入會導致 B+ 樹大量頁分裂，寫入性能急降。

## InnoDB 核心機制

| 機制 | 作用 |
|------|------|
| redo log | 保證事務持久性（crash recovery），實體層面的「做了什麼修改」 |
| undo log | 支援事務回滾和 MVCC，記錄「修改前的值」 |
| MVCC | 多版本並發控制，實現非鎖定讀（Snapshot Read），避免讀寫互斥 |

## 我的判斷

- **InnoDB 是唯一的選擇**。MyISAM 沒有行級鎖、沒有事務、crash 後需要手動修復。除非有極特殊的全文檢索需求（現在也都用 ES 了），否則不要離開 InnoDB。
- **B+ 樹的設計決定了 MySQL 的性能上限**。理解葉子節點的雙向鏈表就能理解為什麼範圍查詢快、為什麼自增主鍵重要、為什麼 `LIMIT 100000,10` 很慢（因為要遍歷鏈表跳過前 10 萬條）。
- **redo log 和 binlog 的差異是很多人搞混的**：redo log 是 InnoDB 層的，binlog 是 MySQL Server 層的。crash recovery 靠 redo log，主從複製靠 binlog。

## 最後記住這句

**MySQL 的性能不是調出來的，是設計出來的——索引設計、主鍵選擇、查詢寫法，這三個決定了 90% 的性能差距。**
