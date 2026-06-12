---
title: 什麼是 Docker？
description: Docker 容器化核心概念解析：Image vs Container、Dockerfile 建構流程、與 VM 的差異，以及基本操作速查。
type: knowledge
status: evergreen
tags:
  - docker
  - container
  - devops
  - infrastructure
source: ''
related: []
pubDate: 2025-08-15T15:06:05.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

## 核心摘要

Docker 把應用程式和它的所有依賴（library、設定檔、runtime）打包進一個輕量容器，確保「在我機器上能跑」這句話不會再出現。跟 VM 的差別在於：VM 虛擬硬體，容器只隔離 process——所以啟動快、佔資源少、可以在一台機器上跑上百個容器。

## 一句話理解

**Docker 是應用的標準化包裝箱：Image 是說明書，Container 是開箱後的執行狀態。**

## 核心概念

| 概念 | 解釋 | 類比 |
|------|------|------|
| **Image（鏡像）** | 唯讀模板，包含應用 + 環境 | 安裝包 |
| **Container（容器）** | Image 的執行實例 | 執行中的程式 |
| **Dockerfile** | 定義 Image 如何構建的腳本 | 建構藍圖 |
| **Volume（儲存卷）** | 容器和主機之間的持久化目錄 | 外接硬碟 |
| **Network** | 容器之間預設用橋接網路互連 | 內部區域網路 |

## 容器 vs 虛擬機

VM 每個實例都跑一個完整 OS kernel，佔用 GB 級資源。容器共用 host kernel，只隔離 process、network、filesystem——啟動時間從分鐘降到秒，同規格機器可以跑的實例數量差一個數量級。

## 基本操作流程

```
docker pull nginx          # 拉取 Image
docker run -d -p 8080:80 nginx  # 啟動 Container，port 8080 映射到容器 80
docker ps                  # 查看執行中的容器
docker stop <id>           # 停止容器
docker rm <id>             # 刪除容器
docker build -t my-app .   # 從 Dockerfile 構建自定義 Image
docker exec -it <id> bash  # 進入容器內部
```

## Dockerfile 最小範例

```dockerfile
FROM node:20-alpine           # 基底 Image
WORKDIR /app                  # 工作目錄
COPY package.json .           # 先複製依賴檔（利用 layer cache）
RUN npm install
COPY . .                      # 再複製程式碼
EXPOSE 3000
CMD ["node", "server.js"]
```

重點：`COPY package.json` 和 `COPY . .` 分兩步，讓 node_modules 可以被 cache，改程式碼時不用重新 npm install。

## 我的判斷

- Docker 的價值不在「能跑容器」，而是在開發/測試/部署之間**消除環境差異**。同一份 Dockerfile，在 MacBook 和 AWS ECS 上行為一致。
- 新手最常踩的坑：忘記 Volume，容器刪掉後資料也消失。任何有狀態的服務（DB、Redis）都要掛 Volume。
- Docker Compose 是多容器應用的下一步，但先搞懂單容器再學，不然 debug 會很痛苦。
- 2025 年的趨勢是 Docker 正在從開發環境標配變成 AI/ML 工作流標配（GPU passthrough、模型 serving）。

## 最後記住這句

**Image 是 immutable 的藍圖，Container 是它的執行身分。搞清楚這層關係，Docker 的開發/部署模型就通了一半。**
