---
title: CNCF IAM Whitepaper 整理
description: >-
  CNCF 發佈的 K8s 環境 IAM 白皮書重點整理：兩套參考架構（Basic/Advanced Pattern）、OIDC + PKCE + MFA
  人類身份驗證、SPIFFE Workload 身份、P*P 授權架構。
type: knowledge
status: evergreen
tags:
  - kubernetes
  - security
  - iam
  - authentication
  - authorization
  - oidc
  - oauth
  - spiffe
  - zero-trust
source: CNCF TAG Security and Compliance
related: []
pubDate: 2026-06-09T00:00:00.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---


> CNCF TAG Security and Compliance 發佈於 2026-06，39 頁。
> 提供 Kubernetes 環境中認證（Authentication）與授權（Authorization）的實務指引，提出兩套參考架構（Basic / Advanced Pattern）。

---

## 文件概覽

| 項目 | 內容 |
|------|------|
| **標題** | Identity and Access Management Whitepaper |
| **發佈單位** | CNCF TAG Security and Compliance |
| **頁數** | 39 頁 |
| **目標讀者** | 雲原生架構師、應用開發者、IAM 入門者 |
| **引用標準** | OAuth 2.0, OIDC, NIST SP 800-63, NIST SP 800-162, AuthZEN 1.0, SPIFFE, FAPI |

---

## 核心主旨

以 RFC 2119 的 MUST / SHOULD / MAY 語言，為 K8s 環境定義 IAM 實作要求：

- **人類身份** → OIDC Authorization Code Flow + PKCE + MFA
- **Workload 身份** → SPIFFE SVID（Advanced Pattern）
- **授權** → P*P 架構（PDP/PEP）+ ABAC/ReBAC

---

## 為什麼 IAM 在雲原生至關重要

1. **動態擴縮** — 容器生命週期僅數秒，須自動化權限管理
2. **邊界消失** — 多雲/多區域部署，零信任成為新安全邊界
3. **服務間通訊** — 微服務須 workload-to-workload 認證
4. **政策即代碼** — IAM 整合 CI/CD，shift-left 安全檢查

---

## 關鍵詞彙

| 術語 | 說明 |
|------|------|
| **PDP / PEP / PIP / PAP** | NIST SP 800-162 授權架構角色：決策、執行、資訊、管理 |
| **SVID** | SPIFFE Verifiable Identity Document，X.509 或 JWT 格式 |
| **Trust Domain** | SPIFFE 信任根邊界，1 cluster = 1 trust domain |
| **ABAC / ReBAC** | 屬性 vs 關係為基礎的授權模型，取代傳統 RBAC |
| **FAPI** | OpenID Foundation 高安全 OAuth/OIDC Profile |
| **AuthZEN** | OpenID Foundation 定義的 PEP–PDP 標準化 API 1.0 |

---

## 兩種 Use Case

| Use Case | 描述 | 典型場景 |
|----------|------|----------|
| **Stateful Workload** | 管理 session，瀏覽器透過 cookie 存取 | BFF 模式的 SPA、傳統 Web 應用 |
| **Stateless Workload** | API client 帶 access token 存取 | REST API、微服務後端 |

---

## 兩種 Pattern 比較

| 面向 | Basic Pattern | Advanced Pattern |
|------|---------------|------------------|
| **信任模型** | Cluster 邊界 = 信任邊界 | 每個 workload 各自為信任邊界（零信任） |
| **適用場景** | 非敏感資料、內部網路 | 敏感資料、公開服務 |
| **TLS** | 僅 cluster 邊界強制 | 所有元件間強制 |
| **mTLS** | 非強制 | 強制（SPIFFE SVID） |
| **MFA** | 非強制 | 強制（最低 AAL2） |
| **授權委派** | 邊界 workload 強制 | 所有 workload 強制 |
| **Token 傳遞** | 外部→內部可選 | 外部→內部強制 + mTLS |
| **威脅模型** | 外部威脅 | 內部威脅（橫向移動、權限提升）+ 外部威脅 |

---

### Basic Pattern 流程

**Use Case 1 (Stateful)：**
1. 瀏覽器 → workload #1（cookie，無 token）
2. Workload #1 發起 OIDC authorization code flow → 取得 ID token + access token
3. Workload #1 (PEP) → PDP 詢問授權決策
4. 可選：workload #1 → workload #2（可帶 access token）

**Use Case 2 (Stateless)：**
1. API client 發起 OIDC flow → 取得 external access token
2. API client → workload #1（帶 external token）
3. Workload #1 (PEP) → PDP
4. 可選：exchange 成 internal token → workload #2

### Advanced Pattern 流程

**核心差異：** 多了 SPIFFE SVID 發放與 mTLS 通道

1. **Setup：** SPIFFE Signing Authority 透過 Workload Endpoint 發 SVID 給每個 workload
2. Workload 間呼叫**強制 internal access token + mTLS**
3. **雙主體授權：** workload identity 來自 SVID，user identity 來自 internal token
4. 所有 internal API 都須經 PDP 授權

---

## 關鍵 Requirements

### Common（所有模式適用）

| # | 要求 | 等級 |
|---|------|------|
| 1 | Cluster 外通訊 TLS | MUST |
| 2 | 元件應冗餘 | SHOULD |
| 3 | 認證須人機互動 | MUST |
| 4 | 多因素認證 | SHOULD（Basic）/ MUST（Advanced） |
| 5 | 身分聯合 FAL2+ | MUST |
| 6 | 僅支援 authorization code flow | MUST |
| 7 | PKCE with S256 | MUST |
| 8 | 授權達 function / object / property 層級 | MUST |
| 9 | 採用 NIST P*P 架構 | MUST |

### OIDC OP Requirements

- 每個 trust domain 僅一個邏輯 OIDC OP（MUST）
- 支援對應 AAL 的認證方式（MUST）
- 安全 token 發放：ID token 簽章 / access token 短生命期 / refresh token 生命週期控制（MUST）
- 提供 OIDC Discovery / Authorization / Token / UserInfo 端點（MUST）
- Advanced 模式須支援 sender-constrained token（DPoP 或 mTLS）（MUST）

### PDP Requirements

- 不可從 cluster 外部網路訪問（MUST）
- 記錄所有授權決策（MUST）
- 提供標準化 API（如 AuthZEN 1.0）（SHOULD）
- 採用 ABAC 或 ReBAC（SHOULD）
- Advanced 模式：PEP→PDP 須用 SVID 認證（MUST）

### SPIFFE Signing Authority（僅 Advanced）

- 每個 trust domain 一個（MUST）
- 發放 SVID + 管理 trust bundle（MUST）
- 安全金鑰管理 + 自動 SVID 輪換（MUST）

### SPIFFE Workload Endpoint（僅 Advanced）

- 安全傳遞 SVID（Workload API / CSI Driver / Envoy SDS 等）（MUST）
- 處理 SVID 輪換更新（MUST）
- 分發 trust bundle（MUST）

---

## 隱私原則

- **資料最小化：** `sub` claim 使用不透明 ID，避免 PII
- **目的限制：** 身份資訊僅用於認證、授權、稽核
- **被遺忘權：** 不透明 ID 可支援使用者刪除請求
- **暴露限制：** Token、log、policy inputs 應最小化暴露

---

## 參考資源

- **CNCF IAM Whitepaper PDF** — [Identity and Access Management Whitepaper](https://www.cncf.io/wp-content/uploads/2026/06/Identity-and-Access-Management-Whitepaper.pdf)（CNCF TAG Security and Compliance, 2026）
- [Microsoft Learn - IAM Core Concepts](https://learn.microsoft.com/en-us/entra/fundamentals/identity-fundamental-concepts)
- [Auth0 - Cloud IAM Guide](https://auth0.com/learn/cloud-identity-access-management)
- NIST SP 800-63 Rev.4 — Digital Identity Guidelines
- NIST SP 800-162 — Attribute Based Access Control (ABAC)
- [AuthZEN 1.0](https://openid.github.io/authzen/) — PEP-PDP 標準介面
- [SPIFFE](https://spiffe.io/) — CNCF Graduated Project
- [FAPI 2.0](https://openid.net/specs/fapi-security-profile-2_0-final.html) — Financial-grade API Security Profile
- RFC 9700 — Best Current Practice for OAuth 2.0 Security
