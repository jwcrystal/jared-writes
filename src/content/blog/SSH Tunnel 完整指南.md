---
title: SSH Tunnel：所有遠端開發的底層技能
description: SSH Tunnel 三種模式（Local/Remote/Dynamic）的架構解析與實務指南，涵蓋指令、場景、安全考量與自動重連方案。
type: knowledge
status: evergreen
tags:
  - ssh
  - networking
  - security
  - devops
source: ''
related: []
pubDate: 2026-03-15T16:00:00.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# SSH Tunnel：所有遠端開發的底層技能

## 為什麼這件事值得看

SSH Tunnel 是遠端開發、滲透測試、DevOps 排錯的共用底層技能。大部分人只會 `-L`（打內網），但 `-R`（反向暴露本機服務）和 `-D`（全域 SOCKS 代理）才是真正讓你「一個 SSH 解決所有連線問題」的關鍵。這篇不是教你 SSH 指令，是教你把三種 tunnel 變成肌肉記憶。

## 核心摘要

SSH Tunnel 不只是「用 SSH 連線」，而是在應用層和網路層之間插入一條加密通道，讓你的流量繞過防火牆、穿越 NAT、或反向暴露本機服務。三種模式對應三種經典場景：Local（訪問內網）、Remote（分享本機服務）、Dynamic（全域代理）。把這三張圖記住，實務上 90% 的 tunneling 需求就解決了。

## 一句話理解

**-L 是走出去，-R 是讓人走進來，-D 是走到哪都行。**

## 背景 / 問題

三種常見困境都需要 SSH Tunnel：

- 內網只有跳板機能連線，但你本機要打內網的 DB
- 你本機跑了一個開發中的服務，想讓 remote 同事或客戶看
- 你在咖啡廳用公開 WiFi，不想讓別人看到你的流量

## 三種隧道類型

### Local Port Forwarding（-L）

```
你的電腦                 SSH Server              遠端內網服務
┌─────────────┐         ┌─────────────┐         ┌────────────┐
│ localhost   │ SSH     │ (跳板機)     │ ──────► │ :3306      │
│ :3306       │ Tunnel  │              │         │ (MySQL)    │
└─────────────┘ ════════┘              │         └────────────┘
```

**用途**: 從本機透過跳板機訪問內網服務
**指令**: `ssh -L 3306:db.internal:3306 user@jump-server.com`
**資料流**: 你的應用 → localhost:3306 → SSH Client 加密 → SSH Server 解密 → 轉發到目標

### Remote Port Forwarding（-R）

```
         外部使用者           公網 SSH Server         你的電腦
        ┌─────────┐         ┌───────────┐          ┌──────────┐
        │ 瀏覽器  │ ──────► │ :8080     │ ════════ │ :3000    │
        └─────────┘         └───────────┘ Tunnel   │ 本地服務 │
                                                    └──────────┘
```

**用途**: 讓外部使用者透過你的 SSH Server 訪問你本機的服務
**指令**: `ssh -R 8080:localhost:3000 user@my-vps.com`
**必要設定**: SSH Server 的 `sshd_config` 需要 `GatewayPorts yes`

### Dynamic Port Forwarding（-D）

```
       你的電腦                   SSH Server              任意目標
    ┌───────────┐             ┌───────────┐           ┌────────┐
    │ 瀏覽器    │ SOCKS5      │            │ ────────► │ 網站 A │
    │ :1080     │ ═══════════ │            │ ────────► │ 網站 B │
    └───────────┘ Tunnel      └───────────┘           └────────┘
```

**用途**: 建立 SOCKS5 代理，所有流量經 SSH Server 轉發
**指令**: `ssh -D 1080 user@my-vps.com`
**特色**: 不需要指定目標，瀏覽器或其他應用設定 SOCKS5 代理即可

## 三種模式對比

| 特性 | Local (-L) | Remote (-R) | Dynamic (-D) |
|------|-----------|-------------|--------------|
| 方向 | 你 → 遠端服務 | 外部 → 你的服務 | 你 → 任意目標 |
| 用途 | 訪問內網服務 | 分享本地服務 | 全域代理 |
| 目標數量 | 單一 | 單一 | 任意 |
| 最常見場景 | 連內網 DB | Demo 本地開發 | 安全上網 |

## 實務場景

| 場景 | 指令 |
|------|------|
| 安全打內網 MySQL | `ssh -L 3306:db.internal:3306 user@jump` |
| 臨時 demo 給客戶看 | `ssh -R 8888:localhost:3000 user@cloud-vm` |
| 咖啡廳安全上網 | `ssh -D 1080 -C user@home-server` |
| 一次轉發多個 port | `ssh -L 3306:db:3306 -L 6379:redis:6379 -L 8080:web:80` |

## 進階：保持連線穩定

**SSH Config** (`~/.ssh/config`):
```ssh-config
Host tunnel
    HostName ssh-server.com
    User myuser
    LocalForward 3306 db.internal:3306
    ServerAliveInterval 60
    ExitOnForwardFailure yes
```

**autossh 自動重連**:
```bash
autossh -M 0 -f -N -L 3306:db.internal:3306 user@server.com
```

## 安全注意

| 風險 | 措施 |
|------|------|
| 未授權訪問轉發 port | SSH Server 設定 `GatewayPorts no` |
| 閒置連線暴露 | 設 `ClientAliveInterval` + 心跳 |
| 轉發範圍過大 | 只開必要的 port，不要一股腦全部轉發 |

## 我的判斷

- `-L` 和 `-D` 是日常最常用的兩種。`-R` 的使用場景較窄但遇到時很救命
- 很多人不知道 `~/.ssh/config` 可以把重複的 tunnel 設定固化，大幅降低出錯率
- autossh 是 tunnel 的標配，tunnel 斷了沒人通知你，第二天才發現連不上會很痛
- `-D` 的 SOCKS 代理是穿越各種網路限制的最後一招，記得加 `-C` 壓縮

## 最後記住這句

**把 tunnel 設定寫進 `~/.ssh/config`，配合 autossh，一個指令完成連線 + 轉發 + 自動重連。別每次都手打一大串。**

---

## 原始參考

### 常用參數

| 參數 | 說明 |
|------|------|
| `-L` | Local port forwarding |
| `-R` | Remote port forwarding |
| `-D` | Dynamic (SOCKS proxy) |
| `-N` | 不執行遠端命令 |
| `-f` | 背景執行 |
| `-C` | 啟用壓縮 |
| `-g` | 允許遠端主機連接到轉發 port |

### 延伸

```bash
# SSH Jump Host（多層跳板）
ssh -J user@jump1,user@jump2 user@final
```
