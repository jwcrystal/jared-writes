---
title: Terraform + Ansible 多雲部署指南
description: >-
  Terraform 和 Ansible 組合實現多雲自動化部署的完整流程：Terraform 負責佈建基礎設施，Ansible 負責配置應用，透過動態
  inventory 橋接。含安全性、可靠性、成本控制注意事項。
type: knowledge
status: evergreen
tags:
  - terraform
  - ansible
  - iac
  - devops
  - multi-cloud
  - automation
  - deployment
source: ''
related: []
pubDate: 2025-08-14T16:00:00.000Z
updatedDate: 2026-06-09T16:00:00.000Z
---

# Terraform + Ansible 多雲部署指南

## 核心摘要

Terraform 和 Ansible 各自解決 IaC 的不同階段：**Terraform 管基礎設施的「有沒有」（有沒有這台機器、這個網路），Ansible 管基礎設施的「對不對」（軟體裝好了嗎、配置正確嗎）**。兩者串聯的關鍵是動態 inventory：Terraform 輸出資源 IP，Ansible 讀取 inventory 去配置它們。這個組合的威力在於：同一套流程可以同時部署 AWS 和 GCP 的機器，不換工具。

## 一句話理解

**Terraform 說「我要兩台機器，一台在 AWS，一台在 GCP」；Ansible 說「不管你在哪個雲，我幫你裝 Nginx」。**

## 整體流程

```
Terraform → 輸出 IP → 生成 Inventory → Ansible → 應用運行
   (基礎設施)         (橋接)          (配置管理)
```

## 核心步驟

### 1. Terraform：多雲基礎設施

```hcl
provider "aws" { region = "us-east-1" }
resource "aws_instance" "aws_server" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

provider "google" { project = "my-gcp-project" }
resource "google_compute_instance" "gcp_server" {
  name = "gcp-webserver"
  machine_type = "e2-micro"
}

output "aws_ip" { value = aws_instance.aws_server.public_ip }
output "gcp_ip" { value = google_compute_instance.gcp_server...nat_ip }
```

關鍵：`output` 把資源 IP 匯出，這是以後 Ansible 知道要去哪台機器的唯一橋樑。

### 2. 動態 Inventory：Terraform → Ansible

```bash
terraform output -json > outputs.json
AWS_IP=$(jq -r '.aws_ip.value' outputs.json)
GCP_IP=$(jq -r '.gcp_ip.value' outputs.json)
# 生成 inventory.yml
```

不做這步，Ansible 不知道 Terraform 創了什麼機器。

### 3. Ansible：跨平台配置

```yaml
- name: Install Nginx on all servers
  hosts: all
  tasks:
    - name: Install Nginx
      package: name=nginx state=present
```

不管 AWS 跑 Ubuntu 還是 GCP 跑 Debian，`package` 模組自動適配套件管理器。

### 4. 一鍵部署

```bash
terraform apply -auto-approve
bash generate_inventory.sh
ansible-playbook -i inventory.yml deploy.yml
```

## 注意事項四象限

| 面向 | 重點 |
|------|------|
| **安全** | 憑證放 Vault/Secrets Manager，永不進程式碼；IAM 最小權限 |
| **可靠** | IaC 進 Git（可回滾）；藍綠部署；監控告警 |
| **維護** | 模組化（reusable Terraform modules + Ansible roles）；自動化測試 |
| **成本** | 選對 instance type；自動擴展；監控帳單 |

## 我的判斷

- **Terraform + Ansible 是 IaC 黃金組合，但很多人用反**。Terraform 不該拿來裝軟體（它的 provisioner 是玩具），Ansible 不該拿來建機器（它沒有 state management）。各司其職才是正道。
- 動態 inventory 是組合中最脆弱的一環。如果 Terraform output 格式變了、jq 解析錯了、inventory 沒更新——Ansible 要嘛連到舊機器，要嘛連不到。實務上建議用 Terraform 的 `local_file` resource 或 `templatefile` 直接生成 inventory，減少 shell 腳本依賴。
- 這套模式對小型部署很好，但到了 50+ 機器、跨 3 個雲、多個環境時，建議引入 Packer（預先烤好 AMI/Image）和 Terraform Cloud/Workspace，減少 Ansible 的配置時間。

## 最後記住這句

**Terraform 負責「宣告世界應該長怎樣」，Ansible 負責「確保每台機器都長那樣」。兩者分清楚，IaC 就成功一半。**
