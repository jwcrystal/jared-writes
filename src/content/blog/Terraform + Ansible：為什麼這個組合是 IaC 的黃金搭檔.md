---
title: Terraform + Ansible：為什麼這個組合是 IaC 的黃金搭檔
description: Terraform（基礎設施佈建）與 Ansible（配置管理）結合，實現跨 AWS/GCP 等雲端平台的一鍵自動化部署流程。
type: publish
status: draft
tags:
  - terraform
  - ansible
  - devops
  - iaas
  - cloud
  - automation
source: ''
publish_target: ''
published_url: ''
related: []
pubDate: 2025-08-15T00:56:13.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

## 為什麼這件事值得看

IaC 工具很多，但大多數人只學一個：要嘛全用 Terraform（連機器上的軟體配置都塞進去），要嘛全用 Ansible（連機器建立都自己管）。兩者單用都有盲區——Terraform 不善於管理機器內的軟體狀態，Ansible 不善於管理雲端資源的生命週期。這篇講的不是「怎麼用」，而是「為什麼 Terraform + Ansible 的組合比單用任何一個都合理」。

## 核心摘要

Terraform 和 Ansible 是 DevOps 工具鏈裡最經典的組合：**Terraform 管基礎設施（機器、網路、IAM），Ansible 管機器上的軟體（套件、服務、配置）**。核心流程是把 Terraform 輸出的 IP 動態餵給 Ansible inventory，實現從 `terraform apply` 到服務上線的全自動化。多平台部署（AWS + GCP）的關鍵不在於 Terraform 本身支援多 provider，而在於如何用 Ansible 的條件判斷（`when`）處理不同 OS 和平台的差異。

## 一句話理解

**Terraform 決定機器的存在，Ansible 決定機器上跑什麼。串起來就是一鍵部署。**

## 流程

```
terraform init → terraform apply → 輸出 IP
                                       │
                                       ▼
                               generate_inventory.sh
                               (轉換成 Ansible inventory.yml)
                                       │
                                       ▼
                          ansible-playbook -i inventory.yml deploy.yml
                                       │
                                       ▼
                              Nginx 在多平台上線
```

| 步驟 | 工具 | 產出 |
|------|------|------|
| 1. 定義基礎設施 | Terraform (`main.tf`) | AWS EC2 + GCP VM |
| 2. 生成 Inventory | Shell script | `inventory.yml` |
| 3. 配置服務 | Ansible playbook | Nginx 安裝 + 啟動 |
| 4. 一鍵串聯 | `deploy.sh` | 全自動 |

## 關鍵設計

**多平台差異處理** 是 Ansible 的強項，不是 Terraform 的：

```yaml
# Ansible: 根據 OS 自動選擇套件管理器
- name: Update cache (Debian/Ubuntu)
  apt:
    update_cache: yes
  when: ansible_os_family == "Debian"
```

Terraform 的強項是同一個 HCL 語法管多個 provider（AWS、GCP、Azure），但 provider 之間的語法差異本身就是學習成本。

## 注意事項

| 面向 | 關鍵點 |
|------|--------|
| **安全性** | API key 絕不硬編碼，用 Vault / Secrets Manager |
| **冪等性** | 整個部署流程必須可重複執行（Terraform state + Ansible 本身就是冪等的） |
| **版本控制** | `.tf` 和 playbook 都要進 Git，CI/CD 從 Git 觸發 |
| **藍綠部署** | 生產環境不直接 `apply`，用 rolling update 或 blue-green |
| **成本控制** | Terraform state 記錄了所有資源，定期 review 閒置機器 |

## 模組化建議

- Terraform：拆成 `modules/aws_instance` 和 `modules/gcp_instance`，用變數控制差異
- Ansible：封裝成 roles（如 `roles/nginx`），playbook 只做組合
- CI/CD：GitHub Actions / Jenkins 呼叫 `deploy.sh`，推送即部署

## 我的判斷

- Terraform + Ansible 組合的優勢是**分工明確**：Terraform 管 state（資源的期望狀態），Ansible 管 configuration drift（機器上實際裝了什麼）。兩者沒有重疊，也不會打架。
- 如果你只用單一雲端平台，CloudFormation / ARM templates 可能夠用。但跨雲或多平台的需求一旦出現，Terraform 幾乎是唯一解。
- 多平台部署的真正難點不是工具鏈，而是**平台差異的抽象層**：網路、IAM、機器規格在不同 provider 的命名和行為都不同，需要花時間寫好模組。

## 最後記住這句

**Terraform 管資源的存在，Ansible 管資源的狀態。把 Terraform 的 output 自動餵給 Ansible inventory，整條部署鏈就閉環了。**
