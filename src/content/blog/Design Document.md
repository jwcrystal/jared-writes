---
title: 權限管理系統後端設計 — Design Document
description: >-
  一個基於 Rust (Axum + SQLx + Casbin + PostgreSQL) 的權限管理後端加固設計，涵蓋 middleware、DB
  schema、LDAP 整合、OpenAPI 規範。
type: knowledge
status: evergreen
tags:
  - permission
  - backend
  - rust
  - axum
  - postgresql
  - casbin
  - ldap
  - architecture
source: ''
related: []
pubDate: 2025-09-10T07:28:35.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# 權限管理系統後端設計文檔

## 核心摘要

這是一份 Rust 後端（Axum + SQLx + Casbin + PostgreSQL）的權限管理系統設計文檔，重點在**加固既有架構**：把 JWT + permission middleware 統一到 Router 層，正規化 DB schema（role_permissions、permission_groups），統一登入入口為 `/api/v1/auth/login`，並將 LDAP 整合升級為啟動檢查 + 登入 fallback + 定時群組同步的完整方案。

## 一句話理解

**把 middleware、schema、auth flow、LDAP、OpenAPI 全部對齊到同一份規格，讓安全邊界可被測試和審計。**

## 架構

```
Router (Axum)
  │
  ├── Public: /health, /login, /refresh, /api-docs
  │
  └── Protected (JWT + Permission)
      ├── JWT Auth Middleware
      ├── Permission Check Middleware
      └── Handlers → Services → Repositories → PostgreSQL
                         │
                         ├── RedisCache (optional, graceful degrade)
                         └── LDAP Client
```

## 核心設計決策

| 面向 | 決策 | 原因 |
|------|------|------|
| Middleware 分層 | JWT → Permission → Handler | 安全檢查先於業務邏輯，失敗快速返回 401/403 |
| 權限正規化 | `roles.permissions` JSON → `role_permissions` 關聯表 | 可以 query、可以建 index、可以做 cascade delete |
| 登入入口 | 統一到 `/api/v1/auth/login` | 舊的 `/api/v1/users/login` 標記 deprecated |
| LDAP 容錯 | 連線失敗 fallback 到 local auth | 不讓 LDAP 故障阻斷所有登入 |
| Cache 降級 | Redis 失敗時讀 DB | permission check 不能因為 cache 掛掉就全掛 |

## DB Schema 變更

三張新表：

- **role_permissions**：role ↔ permission 的正規化關聯，取代 JSON blob
- **permission_groups**：按功能分組的權限群組（slug 做穩定標識）
- **permission_group_permissions**：群組 ↔ 權限的關聯

## LDAP 整合方案

| 階段 | 行為 |
|------|------|
| 啟動時 | 載入 active tenants 的 LDAP config，測試連通性。失敗 → WARN 繼續 |
| 登入時 | 嘗試 LDAP bind；連線失敗 → fallback 到 local credential |
| 定時同步 | 每 N 分鐘 sync user groups → role assignments（idempotent upsert） |
| 手動觸發 | `POST /api/v1/ldap/sync`（需要 `system:admin`） |

## 安全與相容性規則

- API 路徑前綴固定 `/api/v1/**`
- 標準化 response envelope：`{ success, message, data?, error? }`
- 錯誤碼：401 (Unauthorized)、403 (Forbidden)、409 (Conflict)、501 (Not Implemented)
- Deprecation 窗口：舊 endpoint 標 deprecated 一個版本後移除
- 權限刪除有引用時返回 409；admin 可走 force-cascade（含 audit log）

## 我的判斷

- 這份設計文檔的亮點是**安全模型的清晰度**：public route / protected route / admin route 三層分離，middleware chain 一目了然。
- `role_permissions` 正規化是最重要的 schema 變更。JSON blob 看起來方便，但當你需要查「哪些 role 有這個 permission」時，JSON query 效能和可維護性都很差。
- LDAP 的 fallback 設計很務實：不要讓外部依賴變成單點故障。但 fallback 本身也引入了一個安全考量——local auth 和 LDAP auth 必須保持密碼一致，否則切換時可能出現權限不一致。
- 這份文件假設了一個已經存在的 codebase，所以重點在 migration path（backfill、deprecation 窗口、force-cascade），而不是從零設計。這在實務上很常見。

## 最後記住這句

**安全模型的核心不是技術選型，而是在 Router 層清楚地畫出三條邊界：誰可以進來（JWT）、進來了能做什麼（Permission）、哪些端點不需要檢查（Public）。**
