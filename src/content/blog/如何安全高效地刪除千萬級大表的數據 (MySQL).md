---
title: 如何安全高效地刪除千萬級大表的數據 (MySQL)
description: MySQL 三種大表數據刪除方案的比較：分批刪除、新建表+重命名、分區表刪除。方案一通用於各 DB，方案二/三為 MySQL 特有語法。
type: knowledge
status: evergreen
tags:
  - mysql
  - database
  - optimization
  - dba
  - data-management
source: ''
related:
  - SQL優化的15個小技巧
  - 表設計的18條軍規
pubDate: 2025-11-04T02:30:53.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

> **注意：** 方案一的「分批刪除」思路通用於所有關聯式資料庫。方案二（`RENAME TABLE`）和方案三（`ALTER TABLE ... DROP PARTITION`）是 MySQL 特有語法，PostgreSQL 等需用不同語法（`ALTER TABLE ... RENAME TO`、`DROP TABLE IF EXISTS partition_name`）。

## 核心摘要

大表刪除的核心矛盾是：**單次 DELETE 越大，鎖競爭越激烈，主從延遲越嚴重**。解決方案有三條路，按適用場景排序：資料量不大用分批刪除（最安全），保留少量資料用新建表+原子切換（最乾淨），有分區就直接 drop partition（最快但要提前設計）。關鍵不是選哪個方案，而是**永遠不要一條 DELETE 刪幾百萬行**。

## 一句話理解

**DELETE 不是免費的 — 每一行刪除都是鎖、IO、主從同步的代價。把一個大 DELETE 拆成一千個小 DELETE，傷害分散了，系統就穩了。**

## 方案一：分批刪除（最通用）

```sql
DELETE FROM big_table WHERE created_at < '2023-01-01' LIMIT 1000;
-- sleep 0.1s，重複執行
```

- 每批 100-1000 條，每次之間休眠
- 用主鍵或時間欄位做游標，確保每批不重複掃描
- 業務高峰加大休眠間隔
- **優點**：不用停機，風險可控
- **缺點**：慢，可能需要數小時甚至數天

## 方案二：新建表 + 原子切換（最乾淨）

```
1. CREATE TABLE new_table LIKE old_table;
2. INSERT INTO new_table SELECT * FROM old_table WHERE keep_condition;
3. RENAME TABLE old_table TO old_table_bak, new_table TO old_table;
4. DROP TABLE old_table_bak;（確認無誤後）
```

- 適合「刪掉 90% 保留 10%」的場景
- 需要短暫停寫（rename 是原子的，瞬間完成）
- 需要額外磁盤空間（等於保留資料量）
- 有效消除碎片

## 方案三：分區表刪除（最快，需提前設計）

```sql
ALTER TABLE big_table DROP PARTITION p2023_q1;
```

- 本質是刪除檔案，毫秒級完成
- **前提**：建表時就設計了分區策略
- 事後補救成本極高（需重建表）

## 我的判斷

- **如果建表時沒設計分區，99% 的情況用方案一（分批刪除）**。方案二雖然快，但需要停寫和雙倍磁盤，線上環境風險更高。
- 分批刪除的核心參數：每批 500-2000 條、休眠 100-500ms。太密集等於沒分批，太稀疏刪不完。
- 真正重要的前置工作：**在刪除前確認 binlog 空間足夠**。大量 DELETE 產生的 binlog 可能比原資料還大。
- 如果用了雲資料庫（RDS 等），不要假設底層沒有類似限制 — 雲廠商的磁盤 IOPS 也是有上限的。

## 最後記住這句

**大表刪除前先問三個問題：能不能拆成小批？能不能用時間欄位做游標？binlog 空間夠不夠？三個都確認了再動手。**
