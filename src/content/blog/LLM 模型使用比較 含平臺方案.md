---
title: LLM 模型使用比較（含平臺方案）
description: 主流 LLM API 的價格、平台方案（個人/團隊/企業）及使用場景對比，按性價比排序。
type: knowledge
status: evergreen
tags:
  - llm
  - api
  - pricing
  - comparison
  - openrouter
source: ''
related:
  - LLM 模型使用比較
pubDate: 2025-09-11T06:16:11.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

## 核心摘要

這篇從 API 定價 + 平台付費方案兩個維度比較 2025 年主流的 LLM 選項。如果只看 API token 成本：Gemini Flash ≈ DeepSeek < GLM 4.5 < Qwen3 < GPT-4o < Grok < Claude。但加上平台生態和付費方案之後，排序會變——OpenAI 的 ChatGPT Plus ($20/月) 提供了一定額度的 API 使用量，實際上對個人開發者比直接付 API 更划算。

## 一句話理解

**最便宜的 API 是 Gemini Flash 和 DeepSeek；最划算的套餐組合是 ChatGPT Plus。**

## 主流模型定價對比

| 模型 | 平台 | API 輸入 ($/1M) | API 輸出 ($/1M) | 付費方案 | 適合 |
|------|------|----------------|----------------|----------|------|
| Gemini 2.0 Flash | Google | $0.10 | $0.40 | Gemini Advanced $22/月 | 多模態、長文、最便宜 |
| DeepSeek V3 | DeepSeek | $0.50 | $1.10 | 按量付費 | 中文、編碼、低成本 |
| GLM 4.5 Air | z.ai | $0.60 | $2.50-5 | 點數包 | 極高 CP、code |
| Qwen3 Coder | 阿里/OR | $1.50 | $5.00 | 官方 API 包 | 開源、自建、高隱私 |
| GPT-4o | OpenAI | $2.50 | $10.00 | ChatGPT Plus $20/月 | 最主流生態 |
| Grok Code Fast 1 | xAI | $2.00 | $8.00 | X 平台套餐 | Code 速度快 |
| Claude 3.5 Sonnet | Anthropic | $3.00 | $15.00 | Claude Pro $20/月 | 安全、推理最強 |

## 按場景推薦

| 場景 | 首選 | 理由 |
|------|------|------|
| 日常開發 coding | DeepSeek V3 | 中文好、便宜、品質夠 |
| 長文處理 / 搜尋 | Gemini Flash | 1M context，CP 最高 |
| 高安全 / 企業合規 | Claude Sonnet | API 不進訓練，隱私最強 |
| 個人開發全包 | ChatGPT Plus + API | 生態最完整，$20 月費含 API 額度 |
| 開源 / 自建 | Qwen3 Coder | 可本地部署，資料不外流 |

## 我的判斷

- **ChatGPT Plus 被低估了**：$20/月不只是用 ChatGPT，還有一定量的 API token 配額。對個人開發者來說，這比單獨付 API 更划算。
- Gemini Flash 是目前真正的性價比王者——1M context、多模態、$0.10/0.40 的價格幾乎沒有對手。唯一的缺點是中文品質偶爾不穩定。
- 如果只在乎 API 成本和中文能力，DeepSeek + Gemini Flash 覆蓋 80% 的場景。Claude 只有在安全合規是硬需求時才 justify 它的價格。

## 最後記住這句

**付月費再搭 API 是個人開發者最划算的路徑。ChatGPT Plus + Gemini Flash API 組合，一個月不到 $30 覆蓋所有日常 AI 需求。**
