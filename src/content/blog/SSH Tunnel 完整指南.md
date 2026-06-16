---
title: SSH Tunnel 完整指南：三種模式一次掌握
description: >-
  SSH Tunnel
  三種模式（Local/Remote/Dynamic）的完整教學：每種模式的資料流圖、指令、適用場景與安全注意事項。適合需要遠端開發、滲透測試或 DevOps
  排錯的工程師。
type: publish
status: draft
tags:
  - ssh
  - networking
  - security
  - devops
  - tutorial
source: ''
related: []
pubDate: 2026-03-15T16:00:00.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

SSH Tunnel 是遠端開發和 DevOps 排錯的底層技能。多數人只會 `ssh -L`（打內網），但 `-R`（反向暴露服務）和 `-D`（SOCKS 代理）才是真正讓一個 SSH 解決所有連線問題的關鍵。

這篇用三張圖把三種模式講清楚。

---

## 這三個問題，SSH Tunnel 都能解

- 內網只有跳板機能連，但你本機要打內網的資料庫
- 你本機跑了一個開發中的服務，想讓遠端同事或客戶看，但沒有公網 IP
- 你在咖啡廳用公開 WiFi，不想讓別人看到你的流量

三種 tunnel 模式，分別對應上面三個場景。

---

## Local Port Forwarding（-L）：訪問遠端內網

```
你的電腦                 SSH Server              遠端內網服務
┌─────────────┐         ┌─────────────┐         ┌────────────┐
│ localhost   │ SSH     │ (跳板機)     │ ──────► │ :3306      │
│ :3306       │ Tunnel  │              │         │ (MySQL)    │
└─────────────┘ ════════┘              │         └────────────┘
```

**用途**：從本機透過跳板機訪問內網服務

**指令**：
```bash
ssh -L 3306:db.internal:3306 user@jump-server.com
```

**資料流**：你的應用 → localhost:3306 → SSH Client 加密 → SSH Server 解密 → 轉發到目標

**典型場景**：
- 本機開發時連線到 staging 環境的資料庫
- 透過跳板機訪問內網的 Redis、Elasticsearch、Kubernetes API Server

---

## Remote Port Forwarding（-R）：暴露本機服務

```
         外部使用者           公網 SSH Server         你的電腦
        ┌─────────┐         ┌───────────┐          ┌──────────┐
        │ 瀏覽器  │ ──────► │ :8080     │ ════════ │ :3000    │
        └─────────┘         └───────────┘ Tunnel   │ 本地服務 │
                                                    └──────────┘
```

**用途**：讓外部使用者透過公網 SSH Server 訪問你本機的服務

**指令**：
```bash
ssh -R 8080:localhost:3000 user@public-server.com
```

**資料流**：外部使用者 → public-server:8080 → SSH Server 接收 → 透過 tunnel 轉發 → 你的 localhost:3000

**典型場景**：
- 給客戶 demo 本機開發的 web 應用（不需要部署）
- 暫時暴露本機 API 給 webhook 測試（如 Stripe、LINE Bot）
- 讓同事遠端協作查看你本機的服務

**注意**：預設情況下 SSH Server 只監聽 localhost，外部無法訪問。需要在 SSH Server 端設定 `GatewayPorts yes`（`/etc/ssh/sshd_config`）才能讓外部 IP 訪問。

---

## Dynamic Port Forwarding（-D）：全域 SOCKS 代理

```
你的電腦                     SSH Server                整個網路
┌──────────────────┐       ┌───────────┐
│ App1 → :1080     │ SSH   │           │ ──────► Internet
│ App2 → :1080     │Tunnel │           │ ──────► 內網資源
│ Browser → :1080  │══════►│           │ ──────► 任意目標
└──────────────────┘       └───────────┘
```

**用途**：在本機建立一個 SOCKS5 代理，所有支援 SOCKS 的應用都可以透過 SSH Server 上網

**指令**：
```bash
ssh -D 1080 user@remote-server.com
```

**資料流**：應用 → localhost:1080 (SOCKS5) → SSH Client 加密 → SSH Server 解密 → 轉發到目標

**典型場景**：
- 咖啡廳公共 WiFi 加密所有流量（防竊聽）
- 讓瀏覽器透過遠端伺服器上網（繞過地區限制或公司防火牆）
- 讓終端工具（curl、git）走代理

**瀏覽器設定**：在系統或瀏覽器的 Proxy 設定中，選擇 SOCKS5 Proxy，地址 `localhost`，port `1080`。

---

## 三種模式速查

| 模式 | 指令 | 方向 | 典型場景 |
|------|------|------|----------|
| Local (`-L`) | `ssh -L 本機port:目標host:目標port` | 出去 | 訪問內網服務 |
| Remote (`-R`) | `ssh -R 遠端port:本機host:本機port` | 進來 | 暴露本機服務 |
| Dynamic (`-D`) | `ssh -D 本機port` | 代理 | 全域加密代理 |

---

## 常用技巧

### 背景執行
```bash
ssh -fNL 3306:db.internal:3306 user@jump-server.com
```
`-f` 背景執行，`-N` 不執行遠端指令（只建立 tunnel）。

### 自動重連（autossh）
```bash
autossh -M 0 -fNL 3306:db.internal:3306 user@jump-server.com
```
`autossh` 會監控 tunnel 狀態，斷線自動重連。`-M 0` 關閉監控 port（用 SSH 內建 keepalive 替代）。

### SSH Config 簡化指令

`~/.ssh/config`：
```
Host jump
    HostName jump-server.com
    User admin
    LocalForward 3306 db.internal:3306
    LocalForward 6379 redis.internal:6379
```

之後只需 `ssh jump`，多條 tunnel 一次建立。

### 跳板機串聯（Multi-hop Tunnel）
```bash
ssh -L 3306:final-db:3306 -J user@jump1,user@jump2 user@final-host
```
`-J`（ProxyJump）讓 SSH 自動經過中間跳板機。

---

## 安全注意事項

- **最小權限**：tunnel 只需要 shell 權限，不要給 sudo
- **限制綁定**：Remote Forwarding 預設只綁定 localhost，避免暴露給公網
- **使用金鑰認證**：禁用密碼登入，避免暴力破解
- **限制使用者**：在 `sshd_config` 中用 `AllowUsers` 或 `Match User` 限制 tunnel 權限
- **監控 tunnel**：定期檢查 `ss -tlnp | grep ssh` 確認哪些 port 被轉發

---

## 來源

- `man ssh`
- OpenSSH 官方文件
