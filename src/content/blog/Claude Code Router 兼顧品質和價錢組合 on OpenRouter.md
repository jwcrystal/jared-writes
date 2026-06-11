---
title: Claude Code Router 兼顧品質和價錢組合 on OpenRouter
description: >-
  Claude Code Router 在不強制 ZDR 和強制 ZDR 兩種場景下的 OpenRouter
  模型推薦組合，按任務類型（default/background/think/longContext）選擇最佳模型。
type: publish
status: draft
tags:
  - claude-code
  - router
  - openrouter
  - llm
  - zdr
  - cost-optimization
source: ''
publish_target: ''
published_url: ''
related:
  - Claude Code Router 配置
pubDate: 2025-09-02T05:36:03.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# Claude Code Router 模型組合（Quality + Cost）

## 核心摘要

這篇是對 [[Claude Code Router 配置]] 的補充——從「不強制 ZDR」和「強制 ZDR」兩種場景出發，給出 2025 下半年的最優模型組合。核心結論：不強制 ZDR 時 DeepSeek V3.1 + Gemini Flash Lite 是最佳價效組合；強制 ZDR 時 DeepSeek R1 + Qwen3 + Gemini Flash Lite 是推薦三本柱。

## 一句話理解

**同一套 Router 框架，ZDR 模式的模型選擇略窄但品質不降太多，真正的代價是 think（推理）場景沒了便宜的 Mistral。**

## 推薦組合

### 不強制 ZDR（追求最佳性價比）

| 用途 | 模型 | 價格 (in/out, $/1M) | 理由 |
|------|------|---------------------|------|
| default | DeepSeek V3.1 | $0.20 / $0.80 | 綜合品質替代 GPT-4 |
| background | GPT-OSS 20B | $0.04 / $0.15 | 超低價備援 |
| think | Claude 3.5 Sonnet / Mistral Medium 3.1 | $3/$15 or $0.40/$2 | 頂級推理 / 平價推理二選一 |
| longContext | Gemini 2.5 Flash Lite | $0.10 / $0.40 | 1M context，無對手 |
| webSearch | Gemini 2.5 Flash Lite | $0.10 / $0.40 | 最快 + 最便宜 |

### 強制 ZDR

| 用途 | 模型 | 價格 | 理由 |
|------|------|------|------|
| default | DeepSeek R1 0528 (Together) | $0.135 / $0.40 | 支援 ZDR 的日常主力 |
| default 備援 | Qwen3 32B (Groq) | $0.029 / $0.059 | 極速 + ZDR，幾乎免費 |
| background | GPT-OSS 20B | $0.05 / $0.20 | 低成本備援 |
| think | Claude Sonnet 4 (Google) | $3 / $15 | ZDR 下推理首選 |
| longContext | Gemini 2.5 Flash Lite | $0.10 / $0.40 | ZDR + 1M context |
| webSearch | Gemini 2.5 Flash Lite | $0.10 / $0.40 | 同上 |

## 我的判斷

- ZDR 模式最大的犧牲不是品質，而是**推理場景的平價選項消失了**。不強制 ZDR 時可以用 $0.40/$2 的 Mistral 取代 $3/$15 的 Claude；但 ZDR 下 Mistral 不被支援，只能付 Claude 的全價。
- Qwen3 32B on Groq 在 ZDR 模式下是個寶藏：$0.029/$0.059 幾乎是免費的速度王者，適合當作 default 的備援。
- 這篇和 [[Claude Code Router 配置]] 最大的差異是：配置篇講的是 Router 怎麼設、各用途怎麼選；這篇講的是 2025 下半年的具體推薦清單。兩篇互補，不是重複。

## 最後記住這句

**ZDR 模式下的核心損失是推理場景少了平價選項。其他場景（default/longContext/webSearch）用 DeepSeek + Gemini 組合足以覆蓋。**
