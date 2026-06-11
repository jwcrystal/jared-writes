---
title: Casbin 權限庫 — PERM 模型與進階規則
description: >-
  Casbin 權限庫的核心 PERM
  模型拆解（Policy/Effect/Request/Matchers），以及七種進階訪問控制規則的實戰範例：時間限制、資源屬性、IP
  限制、資源層級、多條件、敏感度、頻率限制。
type: knowledge
status: evergreen
tags:
  - casbin
  - authorization
  - rbac
  - acl
  - security
  - access-control
  - permissions
source: ''
related: []
pubDate: 2025-08-14T16:00:00.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# Casbin 權限庫 — PERM 模型與進階規則

## 核心摘要

Casbin 的設計哲學是**把權限模型和權限策略徹底分離**。你用一個 model.conf 定義「怎麼判斷」（PERM 四層），用一個 policy.csv 定義「誰能做什麼」。這層分離的後果是：同一套授權引擎可以從 ACL 切換到 RBAC 再切換到 ABAC，只改一行 matcher，不用改程式碼。理解 Casbin 不難——難的是把業務需求翻譯成正確的 PERM 結構。

## 一句話理解

**Casbin 的根本洞見：權限的本質是「sub + obj + act 的匹配規則」，Model 定義匹配邏輯，Policy 填入具體數據——兩者分開就什麼模型都能支援。**

## PERM 模型四層

```
[request_definition]   r = sub, obj, act     ← 誰想幹什麼
[policy_definition]    p = sub, obj, act     ← 誰被允許幹什麼
[policy_effect]        e = some(where(...))  ← 多條規則衝突時怎麼判
[matchers]             m = g(r.sub, p.sub).. ← 請求與策略如何匹配
```

| 層級 | 角色 | 一句話 |
|------|------|--------|
| Request | 捕獲請求結構 | 定義傳入的 sub/obj/act 格式 |
| Policy | 儲存規則 | 定義誰對什麼資源有什麼權限 |
| Effect | 衝突仲裁 | `some(allow)` = 任一通過即允許；`!some(deny)` = 無一拒絕即允許 |
| Matcher | 匹配邏輯 | `g()` 解析角色繼承，`==` 比對資源和操作 |

## RBAC 基礎（Matcher 的核心）

```ini
[matchers]
m = g(r.sub, p.sub) && r.obj == p.obj && r.act == p.act
```

`g(r.sub, p.sub)` 是 RBAC 的關鍵：它遞迴檢查請求者是否擁有策略中的角色。`g(alice, admin)` 讓 alice 繼承 admin 的所有權限。

## 七種進階規則

### 1. 時間限制
```ini
m = ... && time.Now().Hour() >= 9 && time.Now().Hour() < 18
```
限制只能在上班時間訪問。

### 2. 資源擁有權
```ini
m = ... && r.sub == p.owner
```
Policy 增加 owner 欄位：使用者只能訪問自己擁有的資源。適合多租戶資料隔離。

### 3. IP 白名單
```ini
m = ... && r.ip == p.allowed_ip
```
限制特定 IP 才能訪問。適合內部管理系統。

### 4. 資源層級
```ini
m = ... && strings.HasPrefix(r.obj, p.dir)
```
定義目錄級權限：`p, admin, /home/admin/, read` 允許訪問 `/home/admin/` 下所有資源。

### 5. 多條件組合
```ini
m = ... && r.department == p.department && r.role == p.role
```
結合部門和職級。HR 部門的 manager 才能訪問薪資資料。

### 6. 敏感度分級
```ini
m = ... && (r.sensitivity <= p.max_sensitivity || g(r.sub, "superuser"))
```
低敏感度資料人人可看，高敏感度需要 superuser 繞過。適合數據分級。

### 7. 請求頻率限制（自定義函數）
```go
func rateLimit(sub, obj, act string) bool {
    count := getRequestCount(key)
    return count < 10
}
```
```ini
m = ... && rateLimit(r.sub, r.obj, r.act)
```
Casbin 支援自定義 Go 函數注入 matcher，實現任意複雜邏輯。

## 我的判斷

- **Model vs Policy 分離是 Casbin 最被低估的設計**。這意味著你可以用同一套 Go 程式碼支撐 ACL、RBAC、ABAC 三種模型——切換模型只改 model.conf。
- **Matcher 是性能瓶頸也是靈活性來源**。每條請求都要跑一遍 matcher 表達式。複雜 matcher（自定義函數、多層 g() 遞迴）會顯著拖慢速度。實務上需要在靈活性和性能間取捨。
- **Casbin 不是銀彈**。對於極簡單的場景（只有 3 個角色、5 個資源），直接用 if-else 可能比引入 Casbin 更合適。Casbin 的價值體現在：角色層級深、權限規則複雜、模型可能頻繁變化。
- **Rust 版本可用但生態不如 Go**。如果你用 Rust 做後端，Casbin-RS 基本可用，但自定義函數和進階功能支援不如 Go 版完整。

## 最後記住這句

**Casbin 的學習曲線不是學語法（總共才 5 個段落），而是學會把「PM 口中的權限需求」翻譯成「sub + obj + act + 條件」的抽象模型。**
