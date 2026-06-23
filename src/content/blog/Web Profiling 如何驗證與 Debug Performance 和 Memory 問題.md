---
title: ' Web Profiling：如何驗證與 Debug Performance / Memory 問題'
type: publish
status: draft
tags:
  - web-performance
  - profiling
  - frontend
  - debugging
description: >-
  這篇整理 Web Profiling 中 Performance 與 Memory 問題的驗證流程，重點是用量測、trace 與 before/after
  對照取代直覺式優化。
source:
  - Chrome DevTools
  - web.dev Web Vitals
  - MDN Performance API
related: []
pubDate: 2026-06-23T00:00:00.000Z
updatedDate: 2026-06-23T00:00:00.000Z
---

如果你做過前端效能優化，大概會遇到一種很常見的情況：頁面「感覺很慢」，但真正問起來，慢在哪裡卻說不清楚。

是首屏慢？互動慢？滾動卡？API 慢？還是頁面用久了越來越卡？這些問題表面上都叫 performance issue，但背後可能是完全不同的瓶頸。

Web profiling 要解決的不是「套用更多優化技巧」，而是把模糊的慢，拆成可以被量測、定位、修正、驗證的問題。

這篇重點回答三個問題：

- Performance 問題應該怎麼量測與定位？
- Memory leak 要怎麼判斷，而不是看到 heap 上升就誤判？
- Lab data、field data、DevTools trace 各自應該放在 workflow 的哪裡？

## 核心摘要

Web profiling 的核心流程是：**Measure → Identify → Fix → Verify → Guard**。先建立 baseline，再找出真正瓶頸，修正後用同一套方法重新量測，最後加上監控或 budget 防止回歸。

Performance 和 memory 要分開看，但不能完全切開。記憶體膨脹會增加 GC 壓力，GC pause 會卡住 main thread，最後可能反映成 INP 變差、互動延遲或 Long Task 增加。

這裡真正重要的是：不要只看 Lighthouse 分數，也不要只靠「本機感覺」。Lighthouse、DevTools、WebPageTest、CrUX、RUM 各自回答不同問題，混在一起看才有判斷力。

## 一句話理解

> Performance profiling 看的是「使用者在哪裡被迫等待」；memory profiling 看的是「哪些東西該被釋放卻還活著」。

## Performance Profiling 的基本流程

```text
Measure → Identify → Fix → Verify → Guard
量測     定位瓶頸    修正   再量測    防回歸
```

| 階段 | 重點 | 常用工具 |
|---|---|---|
| Measure | 建立 baseline | Lighthouse、WebPageTest、RUM、CrUX |
| Identify | 找真正瓶頸 | Chrome DevTools Performance / Network |
| Fix | 只修已被證明的瓶頸 | code splitting、image optimization、cache、減少 long task |
| Verify | 比較 before / after | 同環境、同流程、同指標 |
| Guard | 防止下次退化 | performance budget、CI、production monitoring |

### Performance Profiling 主要工具

| 工具 | 適合用來看什麼 | 補充 |
|---|---|---|
| Chrome DevTools Performance | main thread、long task、layout、paint、GC | 最適合定位單次操作的瓶頸 |
| Chrome DevTools Network | TTFB、waterfall、資源阻塞、請求串行 | 首屏慢通常要先看這裡 |
| Lighthouse | lab baseline、CI 回歸檢查、快速稽核 | 適合看趨勢，不適合單獨代表真實體驗 |
| WebPageTest | 多地區、多設備、多網路條件測試 | 適合驗證真實網路條件下的載入體驗 |
| CrUX / RUM | 真實使用者體驗 | 適合驗證 production 是否真的改善 |
| React DevTools Profiler | React re-render、commit time、component bottleneck | 只在懷疑 React render 成本時使用 |

實際 debug 時，可以把這個流程拆得更具體一點：

```text
1. 先定義問題
   - 首屏慢？
   - 點擊卡？
   - 滾動掉幀？
   - 某頁切換慢？

2. 建立 baseline
   - Lighthouse 跑多次取中位數
   - DevTools Performance 錄 trace
   - 如果已經有 production 資料，先看 RUM / CrUX

3. 定位瓶頸
   - Network 慢 → 看 TTFB、waterfall、render-blocking resource
   - JS 慢 → 看 long task、flame chart
   - Render 慢 → 看 layout、paint、compositing
   - React 慢 → 看 re-render、commit time

4. 修正單一瓶頸

5. 再量測
   - 不要只靠感覺
   - 比較 before / after 數字
```

最容易犯的錯，是跳過前兩步直接進入 Fix。比如看到 React component 很多就加 `memo`，看到 bundle 大就改 import，看到圖片大就壓縮圖片。這些做法可能有效，但如果沒有 trace，就不知道它是不是當前真正瓶頸。

## Core Web Vitals 要看什麼

| 指標 | 意義 | 好的範圍 |
|---|---|---|
| LCP | 最大內容何時出現，通常對應首屏體感 | ≤ 2.5s |
| INP | 使用者互動到畫面回應的延遲 | ≤ 200ms |
| CLS | 畫面是否發生非預期跳動 | ≤ 0.1 |
| TTFB | server / network 回第一個 byte 的時間 | 越低越好 |
| Long Task | main thread 是否被單一任務卡太久 | > 50ms 就要注意 |

有兩個觀念需要特別更新：

- 現在互動指標主要看 **INP**，不是 FID。
- TBT 是 lab 環境常用來推估 main thread blocking 的線索，但它不是 field Core Web Vital。

## Performance Debug 可以怎麼切

| 症狀 | 優先看哪裡 | 可能原因 |
|---|---|---|
| 首屏慢 | Network waterfall、LCP attribution | TTFB 高、圖片過大、CSS/JS render blocking |
| 點擊卡 | Performance trace、Long Task | JS 執行太久、同步任務太重、React re-render |
| 滾動 / 動畫掉幀 | Rendering、Layout、Paint | layout thrashing、paint 過重、DOM 太大 |
| 頁面切換慢 | Network、component profiler | API waterfall、client render 太重 |
| 偶發卡頓 | Performance trace 裡的 GC / long task | 記憶體壓力、allocation 太頻繁 |

我的理解是，最實用的切法不是「前端慢 / 後端慢」，而是先問：使用者等待的是資料、JavaScript、render，還是 memory / GC？

## Memory Profiling 不要只看 Heap 上升

Memory debug 最容易誤判。看到 heap 上升，不一定代表 memory leak。瀏覽器可能延後 GC，框架也可能有 cache warmup。

比較可靠的模式是：

```text
正常：
操作 → heap 上升 → GC → 回落或進入穩定平台

可疑：
重複操作 → heap 上升 → GC 後仍持續上升 → 無法回到穩定平台
```

## Memory Debug SOP

```text
1. 讓頁面進入穩定狀態
2. 拍第一份 Heap Snapshot
3. 重複執行可疑操作 5-10 次
4. 手動觸發 GC
5. 拍第二份 Heap Snapshot
6. 用 Comparison view 看哪些物件新增後沒有釋放
7. 看 Retainers chain，找到是誰還引用著它
8. 修復後用同樣流程再跑一次
```

### Memory Profiling 主要工具

| 工具 | 用途 |
|---|---|
| Heap Snapshot | 看 retained object 和 retainer chain |
| Allocation instrumentation | 看操作期間分配了哪些物件，開銷較高 |
| Allocation sampling | 低開銷找 allocation hot spot |
| Performance Panel | 看 GC 是否造成卡頓 |
| Chrome Task Manager | 粗略觀察 tab memory / CPU |

這裡容易踩的坑是，只看 shallow size。真正重要的是 **retained size**，因為它代表「如果這個物件被釋放，連帶能釋放多少記憶體」。

## 常見 Memory Leak 類型

| 類型 | 特徵 | 常見原因 |
|---|---|---|
| Detached DOM tree | DOM 已移除，但 JS 還引用它 | closure、全域變數、listener |
| Event listener leak | listener 持續累積 | unmount 時沒有 remove |
| Timer leak | interval / timeout 還在跑 | 沒有 clearInterval / clearTimeout |
| Subscription leak | socket、observable、store listener 沒退訂 | cleanup 缺失 |
| Cache 無上限 | Map / Set 持續變大 | 沒有 TTL 或 size limit |
| Closure leak | 大物件被 callback 捕獲 | 外層 scope 被意外保留 |

## Lab Data 和 Field Data 要分開看

| 類型 | 代表工具 | 優點 | 限制 |
|---|---|---|---|
| Lab / Synthetic | Lighthouse、DevTools、WebPageTest | 可重現、方便 debug | 不一定代表真實使用者 |
| Field / RUM | CrUX、web-vitals、APM | 反映真實裝置與網路 | 難直接定位底層原因 |

Lighthouse 分數適合當「可重複的測試環境」，但不能單獨當成真實體驗結論。真實使用者的設備、網路、CPU、瀏覽器背景負載都不同，最後還是要用 RUM 或 CrUX 驗證。

## 我的判斷

效能優化最有價值的能力，不是背很多技巧，而是能把問題切準。沒有 baseline 的優化，很容易變成「做了很多事，但不知道哪個有效」。

如果要讓團隊長期受益，我會優先建立三件事：固定的 profiling SOP、performance budget，以及 production RUM。這三個東西比一次性的優化更重要。

## 風險與限制

- DevTools trace 很強，但也容易誤讀；單次錄製不代表所有使用者情境。
- Lighthouse 分數受環境影響，適合看趨勢，不適合當唯一判斷。
- `performance.memory` 只在 Chromium 類瀏覽器較可用，不能當成通用 production memory API。
- Memory leak 需要看多輪操作與 GC 後的 retained memory，不能只看 heap 是否上升。

## 最後記住這句

> Web profiling 不是尋找最佳化技巧，而是用 trace 證明瓶頸在哪裡，再用同一套量測方法證明它真的被修掉。

## 來源

- Chrome DevTools — Performance Panel Overview  
  https://developer.chrome.com/docs/devtools/performance/overview
- Chrome DevTools — Analyze Runtime Performance  
  https://developer.chrome.com/docs/devtools/performance
- Chrome DevTools — Fix Memory Problems  
  https://developer.chrome.com/docs/devtools/memory-problems
- Chrome DevTools — Memory Panel Overview  
  https://developer.chrome.com/docs/devtools/memory
- web.dev — Web Vitals  
  https://web.dev/articles/vitals
- web.dev — Getting started with measuring Web Vitals  
  https://web.dev/articles/vitals-measurement-getting-started
- web.dev — Best practices for measuring Web Vitals in the field  
  https://web.dev/articles/vitals-field-measurement-best-practices
- web.dev — Debug performance in the field  
  https://web.dev/articles/debug-performance-in-the-field
- web.dev — Core Web Vitals workflows with Google tools  
  https://web.dev/articles/vitals-tools
- MDN — Performance API  
  https://developer.mozilla.org/en-US/docs/Web/API/Performance_API
- WebPageTest Documentation  
  https://docs.webpagetest.org/
