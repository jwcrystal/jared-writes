---
title: LLM 模型使用比較
description: 依安全隱私、性價比、推理能力、平台便利度四個維度對 2025 年主流 LLM 進行綜合排序。
type: knowledge
status: evergreen
tags:
  - llm
  - comparison
  - ranking
  - security
  - api
source: ''
related:
  - LLM 模型使用比較 含平臺方案
pubDate: 2025-09-11T06:13:33.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# LLM 模型使用比較

## 核心摘要

這篇從四個維度（安全隱私 → 性價比 → 推理能力 → 平台便利）對 2025 年主流 LLM 進行排序。Claude 在安全隱私和推理能力上領先但最貴；DeepSeek 和 Gemini Flash 是性價比雙雄；GLM 4.5 和 Qwen3 Coder 是值得關注的新勢力。如果你有明確的優先級（例如安全 > 成本），直接看排序。如果你對各維度沒有特別偏好，DeepSeek V3 + Gemini Flash 是目前最均衡的組合。

## 一句話理解

**看重安全選 Claude、看重成本選 DeepSeek/Gemini、兩者都要折衷選 DeepSeek。**

## 四維度排序

| 排名 | 安全隱私 | 性價比 | 推理能力 | 平台便利 |
|------|---------|--------|---------|---------|
| 1 | Claude (API 不進訓練) | DeepSeek (接近免費) | Claude (審查/推理) | OpenRouter (一鍵接入) |
| 2 | Google (企業 API 免留存) | Gemini Flash ($0.10/0.40) | GPT-4o/GPT-5 | ChatGPT/OAI 生態 |
| 3 | DeepSeek (開源可自建) | GLM 4.5 (極高 CP) | DeepSeek V3.1 | Google Vertex |
| 4 | GPT-4o (可關訓練) | Qwen3 (開源) | GLM 4.5 | z.ai (即開即用) |

## 各模型一句話評價

| 模型 | 一句話 |
|------|--------|
| Claude Sonnet 4 | 最安全、最會推理、最貴 |
| Gemini 2.5 Flash | CP 值之王，1M context + 多模態 |
| DeepSeek V3.1 | 中文最強、最便宜、有時不穩定 |
| GPT-4o | 生態最成熟、多功能、中等價位 |
| GLM 4.5 Air | 性價比黑馬，code 能力進步快 |
| Qwen3 Coder | 開源可控，適合自建和隱私需求 |
| Grok Code Fast 1 | Code 快但沒特別便宜 |
| Kimi K2 | 中文 code 新秀，值得關注 |

## 我的判斷

- 這個排序假設四維度權重相等，但實際上每個人的權重不同。對個人開發者來說「性價比 > 平台便利 > 推理能力 > 安全隱私」才合理——對應的推薦就是 DeepSeek V3。
- Claude 的「安全隱私」優勢對企業客戶有意義，對個人開發者來說 DeepSeek 開源自建提供的是更高層次的安全（資料完全不出你的機器）。
- Gemini Flash 被歸類在 Google 生態下，但透過 OpenRouter 也可以輕鬆使用，平台便利性不是問題。
- 這個比較表的時效性很強——LLM 定價幾乎每個月都在變。建議把這當作 2025 Q3 的快照，每季更新一次。

## 最後記住這句

**對個人開發者：DeepSeek V3（日常）+ Gemini Flash（長文/搜尋）+ Claude（安全敏感場景）。三個模型，月費不到 $10。**
