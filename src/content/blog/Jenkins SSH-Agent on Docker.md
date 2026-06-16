---
title: Jenkins SSH-Agent on Docker
description: >-
  用 Docker 建立 Ubuntu-based Jenkins SSH Agent 的 Dockerfile 與 entrypoint 腳本，讓
  Jenkins 可以透過 SSH 連接節點執行 CI job。
type: publish
status: draft
tags:
  - jenkins
  - docker
  - ssh
  - ci-cd
  - devops
source: ''
related:
  - GitLab CI/CD Tutorial
pubDate: 2024-09-04T08:16:06.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

Jenkins 的 SSH Agent 讓 Master 可以透過 SSH 連接到遠端機器執行 CI job。如果你需要 Ubuntu 環境的 agent（預設只有 Debian-based），可以用 Docker 自建：寫一個 Dockerfile（Ubuntu 20.04 + OpenJDK 17 + SSH server），透過 `JENKINS_AGENT_SSH_PUBKEY` 環境變數注入公鑰，Jenkins 會自動把 `remoting.jar` 複製到 agent 並建立連線。

> **用 Docker 自建 Jenkins SSH Agent = Ubuntu 基底 + SSH server + Jenkins 公鑰，Master 自動打通這條 SSH 通道。**

## 核心設計

### Dockerfile 關鍵步驟

| 步驟 | 說明 |
|------|------|
| `FROM ubuntu:20.04` | 選擇 Ubuntu（而非預設的 Debian） |
| `apt install openssh-server openjdk-17-jdk git` | SSH + Java + Git |
| `useradd jenkins` + sudo 無密碼 | Jenkins 以 jenkins 用戶執行 |
| `mkdir ~/.ssh` | 準備接收公鑰 |
| `sed pam_loginuid.so` | 避免 SSH 連線後立即斷開 |

### Entrypoint 腳本

```bash
#!/bin/bash
# 從環境變數注入公鑰到 authorized_keys
if [ ! -z "$JENKINS_AGENT_SSH_PUBKEY" ]; then
    echo "$JENKINS_AGENT_SSH_PUBKEY" > /home/jenkins/.ssh/authorized_keys
    chmod 600 /home/jenkins/.ssh/authorized_keys
fi
exec "$@"
```

### 連線流程

```
Jenkins Master
    │
    │ SSH connect (with JENKINS_AGENT_SSH_PUBKEY)
    ▼
Docker Container (SSH Agent)
    │
    │ Jenkins copies remoting.jar to agent
    ▼
Agent process: java -jar remoting.jar
    │
    ▼
Agent connected and online
```

## 分析與建議

- 這個方案最巧妙的地方是公鑰透過環境變數注入而不是寫死在 Dockerfile 裡。這讓同一個 image 可以被多個 Jenkins 實例使用，只要換 `JENKINS_AGENT_SSH_PUBKEY` 就行。
- `sed pam_loginuid.so` 那一行是經典的 SSH Docker 坑 — 不加這行，連上 SSH 後會立刻被踢掉。這個設定幾乎是每個 SSH Docker image 的標配。
- 如果追求更現代的方案，可以考慮 Jenkins 的 Swarm Agent 或 Kubernetes plugin — 直接用動態 Pod 跑 agent，不需要自己維護 SSH server。但對於傳統 VM-based 的 Jenkins 部署，SSH Agent 仍然是最簡單的方案。

## 總結

**自建 Jenkins Agent 的三個關鍵：SSH server、Java runtime、公鑰注入。透過環境變數管理公鑰，讓同一個 image 可以一鍵部署多個 agent。**
