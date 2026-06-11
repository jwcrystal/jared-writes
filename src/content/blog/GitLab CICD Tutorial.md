---
title: GitLab CI/CD Tutorial
description: >-
  GitLab CI/CD 入門教學：從 .gitlab-ci.yml 的 stages/jobs 定義到 pipeline 執行，核心 keyword
  速查表。
type: knowledge
status: evergreen
tags:
  - gitlab
  - ci-cd
  - devops
  - pipeline
  - yaml
source: >-
  [Tutorial: Create and run your first GitLab CI/CD
  pipeline](https://docs.gitlab.com/ee/ci/quick_start/)
related: []
pubDate: 2025-08-15T00:48:13.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# GitLab CI/CD Tutorial

## 核心摘要

GitLab CI/CD 的核心是一個 `.gitlab-ci.yml` 檔案：你在專案根目錄定義好 stages 和 jobs，每次 push 時 GitLab Runner 自動執行。最簡單的 pipeline 只有三步：build → test → deploy。真正的複雜度來自於 keyword 的組合——`rules` 控制觸發條件、`artifacts` 傳遞產出、`needs` 定義依賴關係、`environment` 區分部署目標。

## 一句話理解

**一個 `.gitlab-ci.yml` + 一個 Runner = 你每次 push 就自動 build、test、deploy。**

## 最小 Pipeline

```yaml
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  script:
    - echo "Building..."
    - npm run build

test_job:
  stage: test
  script:
    - echo "Testing..."
    - npm test

deploy_job:
  stage: deploy
  only:
    - main
  script:
    - echo "Deploying..."
```

## 核心 Keyword 速查

| Keyword | 必要 | 說明 |
|---------|------|------|
| `image` | 否 | Docker image（預設 ruby） |
| `stages` | 否 | 定義全域的 stage 順序 |
| `stage` | 是 | Job 對應哪個 stage |
| `script` | 是 | 執行的 shell 命令 |
| `only`/`except` | 否 | 舊版 branch 觸發條件 |
| `rules` | 否 | 新版彈性觸發條件（推薦取代 only） |
| `artifacts` | 否 | Job 產出的檔案，傳給後續 job |
| `needs` | 否 | 指定依賴的 job，實現 DAG pipeline |
| `cache` | 否 | 跨 job 的快取目錄 |
| `environment` | 否 | 定義部署環境（staging/production） |
| `extends` | 否 | 重用 YAML 配置片段 |
| `include` | 否 | 引入外部 YAML 檔案 |
| `when` | 否 | 控制 job 執行時機（manual/on_failure 等） |
| `retry` | 否 | 失敗自動重試次數 |

## 我的判斷

- GitLab CI 的學習曲線比 GitHub Actions 陡，但功能更完整。最大的差異是 GitLab CI 有內建的 Container Registry、Environment 管理、DAG pipeline（`needs` 關鍵字），而 GitHub Actions 的 marketplace 生態更豐富。
- `rules` 取代 `only`/`except` 是 GitLab 近年的重要改進。如果你還在使用 `only`，建議遷移到 `rules`，語法更直觀、功能更強。
- Runner 是整個 CI 系統的瓶頸。如果你用 Shared Runner（GitLab.com 提供的），排隊時間不可控。關鍵專案建議自架 Runner。
- `.gitlab-ci.yml` 的 YAML 可以透過 `include` 拆分成多個檔案，避免單一檔案膨脹到上千行。

## 最後記住這句

**`.gitlab-ci.yml` 的核心是 stages + jobs + script。其他 key 都是為了更精細地控制「什麼時候跑、跑什麼環境、產出傳到哪裡」。**
