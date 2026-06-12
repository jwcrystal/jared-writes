---
title: Stack Auth：開源身份認證方案評測
description: >-
  Stack Auth 的系統架構圖：基於 Next.js 的 Dashboard + Backend + PostgreSQL，整合
  OAuth、Email、Webhook 服務的開源認證方案。
type: knowledge
status: evergreen
tags:
  - stack-auth
  - authentication
  - nextjs
  - oauth
  - architecture
source: ''
related: []
pubDate: 2024-08-27T01:42:06.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

## 為什麼這件事值得看

2025 年做 side project，auth 方案有三條路：Clerk / Auth0（付費 SaaS，省心但貴）、Supabase Auth（跟 Supabase 捆綁）、Stack Auth（開源自託管，資料在你手上）。如果你不想被 vendor lock-in、又想有現成方案不用從零寫——Stack Auth 是第三條路裡最值得看的選擇。

## 核心摘要

Stack Auth 是一個開源的身份認證系統，基於 Next.js 構建。架構分為 Dashboard（管理介面）、Backend API、PostgreSQL 資料庫、Email Service 和 Webhook Service 五個核心組件。透過 shared packages（Stack UI、Stack Shared、Stack Emails）統一前端元件和後端工具。外部整合 OAuth providers 和 Svix webhook 平台。

## 一句話理解

**Stack Auth = Next.js Dashboard + API + PostgreSQL + OAuth + Email 模板，一個打包好的開源 auth 解決方案。**

## 架構圖

```
User / Admin
    │
    ▼
Dashboard (Next.js) ──→ Backend API (Next.js)
    │                        │
    │                        ├──→ PostgreSQL
    │                        ├──→ Email Service (Inbucket)
    │                        ├──→ Webhook Service → Svix
    │                        └──→ External OAuth Providers
    │
    └──→ Shared Packages
         ├── Stack UI (React Components)
         ├── Stack Shared (Utilities)
         └── Stack Emails (Email Templates)
```

## 我的判斷

- Stack Auth 適合「不想從零寫 auth，但又不想被 Auth0/Clerk 鎖定」的場景。開源 + 自託管意味著你擁有自己的用戶資料。
- 架構上 Dashboard 直接連 DB 和 Email Service 是一個需要留意的地方（原圖標註為 "To be removed"），這意味著他們正在把這些依賴移到 Backend API。
- 和 Clerk、Auth0 等 SaaS auth 方案比，Stack Auth 的優勢是開源和可控，劣勢是你需要自己維護基礎設施。

## 最後記住這句

**Stack Auth 是 auth 方案的「開源自託管」選項——你擁有資料，但你也要自己管伺服器。**
