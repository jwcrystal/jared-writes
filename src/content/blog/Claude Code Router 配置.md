---
title: Claude Code Router 配置
description: Claude Code Router 的模型分流配置策略：按任務類型選擇最佳 model，兼顧成本與品質，包含 ZDR 和零停機容錯方案。
type: publish
status: draft
tags:
  - claude-code
  - router
  - openrouter
  - llm
  - cost-optimization
source: ''
related: []
pubDate: 2025-09-02T02:47:53.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

Claude Code Router 讓你根據任務類型（預設、背景、推理、長上下文、搜尋）把請求分流到不同的 LLM model 和 provider。核心價值在最優化成本與品質的 trade-off — 預設用性價比高的 Grok Code Fast 1，背景任務用超便宜的 GPT-OSS 20B，高推理切到 Mistral Medium，長上下文交給 Gemini Flash。

**不是用一個最好的 model 做所有事，而是把每個任務送給最適合它的 model — 同時省錢。**

## 它解決什麼問題

- 一個 model 不可能在所有任務上都是最佳選擇（有些擅長 coding、有些 context 超大、有些超便宜適合簡單任務）
- 手動切換 model 很煩，而且容易忘記
- 某個 provider 掛掉或限流時整個工作流停擺

## 實際配置

### 基本 Router 配置

```json
{
  "Router": {
    "default": "openrouter,x-ai/grok-code-fast-1",
    "background": "openrouter,openai/gpt-oss-20b",
    "think": "openrouter,mistralai/mistral-medium-3.1",
    "longContext": "openrouter,google/gemini-2.5-flash",
    "longContextThreshold": 60000,
    "webSearch": "gemini,gemini-2.0-flash"
  }
}
```

### 各任務推薦

| 用途 | 首選 Model | 輸入/輸出 ($/1M tokens) | Context |
|------|-----------|------------------------|---------|
| default | Grok Code Fast 1 | $0.20 / $1.50 | 256K |
| background | GPT-OSS 20B | $0.04 / $0.15 | 131K |
| think | Mistral Medium 3.1 | $0.40 / $2 | 131K |
| longContext | Gemini 2.5 Flash | $0.30 / $2.50 | 1M |
| webSearch | Gemini 2.5 Flash | $0.30 / $2.50 | 1M |

成本的差距是巨大的：把一個簡單的檔案讀取任務送給 Claude Sonnet（$15/M output）vs 送給 GPT-OSS（$0.15/M output），價差 100 倍。

## ZDR 模式（Zero Data Retention）

如果你對隱私有要求，可以啟用 ZDR，請求只會路由到支援零資料留存的 endpoint：

| 用途 | ZDR 推薦 | 理由 |
|------|---------|------|
| default | DeepSeek R1 0528（Together/Google） | CP 值最高 |
| background | GPT-OSS 20B（Together） | 超低價 |
| think | Claude Sonnet 4（Google） | 推理品質 |
| longContext | Gemini 2.5 Flash Lite | 1M context + ZDR |

## 零停機容錯（Zero Downtime Router）

每組路由建議至少配置 2 個 provider 做 fallback：

```
"default": "deepseek,deepseek-chat;qwen,qwen3-coder"
```

## 分析與建議

- Router 的核心 ROI 來自 background 和 longContext 的降本。這些任務佔大部分 token 消耗但不需要最強 model。把 background 從 Sonnet 換成 GPT-OSS 可能省 90% 的成本。
- ZDR 模式雖然 model 選項較少，但支援的 model 品質並不差 — DeepSeek R1 和 Gemini Flash 在日常使用中完全夠用。
- 最容易踩的坑：fallback 沒設好。某個 model 突然 quota 滿了或 deprecate 時，沒有 secondary model 就整組卡死。
- Router 的配置不是設一次就不用管的 — model 定價一直在變，每個月至少要 check 一次推薦組合。

## 總結

**default 找性價比、background 找最便宜、think 找推理最強、longContext 找 context 最長 — 把錢花在刀口上。**
