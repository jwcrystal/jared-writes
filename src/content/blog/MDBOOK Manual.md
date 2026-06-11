---
title: MDBOOK Manual
description: >-
  MDBOOK 的 SUMMARY.md 檔案格式說明：如何定義書本章節結構、層級、路徑，以及 Prefix/Suffix/Part/Draft
  等元素的用法。
type: knowledge
status: evergreen
tags:
  - mdbook
  - rust
  - documentation
  - markdown
  - writing
source: ''
related: []
pubDate: 2024-01-20T04:47:25.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# MDBOOK Manual

## 核心摘要

mdBook 是 Rust 生態的文檔生成工具，核心機制是透過 `SUMMARY.md` 定義整本書的章節結構。這個檔案決定了書的目錄、順序、層級——沒有它書就編不出來。格式本質上是一個 Markdown 的巢狀列表，支援 Prefix Chapter、Numbered Chapter、Part Title、Suffix Chapter、Draft Chapter 和 Separator 六種元素。

## 一句話理解

**SUMMARY.md 就是一本書的骨架——寫好它，mdBook 自動生成目錄和所有章節的導航。**

## SUMMARY.md 結構

### 基本格式

```markdown
# Summary

[Introduction](./Introduction.md)

# Part Title

- [Chapter 1](./ch1.md)
- [Chapter 2](./ch2.md)
    - [Section 2.1](./ch2-1.md)
    - [Section 2.2](./ch2-2.md)

---

- [Appendix](./appendix.md)
```

### 六種元素

| 元素 | 語法 | 用途 |
|------|------|------|
| Title | `# Summary` | 必須，檔案開頭 |
| Prefix Chapter | `[Title](path.md)` | 在章節編號之前的獨立頁面 |
| Part Title | `# Part Title` | 章節分組標題 |
| Numbered Chapter | `- [Title](path.md)` | 有編號的章節（支援巢狀） |
| Suffix Chapter | `[Title](path.md)` (無 `-`) | 在所有章節之後 |
| Draft Chapter | `- [Title]()` | 未完成的章節（無路徑） |
| Separator | `---` | 章節之間的分隔線 |

### 建議的目錄組織

```
# Summary
- [Introduction](./Introduction.md)

# User Guide
- [Install](./guide/install.md)

# Reference Guide
- [Command Line Tool](./cli/README.md)
  - [init](./cli/init.md)
  - [build](./cli/build.md)
```

原則是**一個分類一個資料夾**，維持結構清晰。

## 我的判斷

- mdBook 是 Rust 生態中最好用的文檔工具之一。和 GitBook、Docusaurus 相比，它最輕量（不需要 npm、不需要 Node.js），靜態產出，部署成本極低。
- SUMMARY.md 的設計非常務實——把結構定義和內容寫作完全分離。你只需要在這個檔案裡決定章節順序，每個章節的 .md 檔案各自獨立維護。
- Draft Chapter（空路徑）是一個被低估的功能：可以先規劃好全書結構，章節先留空，之後逐步補內容。這對於寫大型文件的規劃階段非常有用。

## 最後記住這句

**SUMMARY.md 決定結構，每個 .md 決定內容。先畫骨架再填肉，mdBook 幫你把一切黏在一起。**
