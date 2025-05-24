Path: novascope/docs/ns-architecture-design-20250524.md

# NovaScope 项目架构设计 (ns-architecture-design-20250524.md)

**项目名称**: NovaScope
**文档版本**: 1.2 (更新时间戳和路径)
**创建日期**: 2025年5月22日
**最后更新**: 2025年5月24日 20:51 (UTC+8)

## 1. 引言

### 1.1 项目目标
NovaScope 项目旨在创建一个高效、低成本、易于维护的 Web 应用，用于每日展示美国国家航空航天局 (NASA) 的每日天文图片 (APOD) 及其相关信息，并计划逐步扩展以实践更多 NASA 的开放 API。

### 1.2 文档目的
本文档详细描述 NovaScope 项目的系统架构、关键组件、技术选型、数据流以及设计原则，为项目的开发、部署和后续迭代提供指导。

## 2. 核心设计原则与决策

* **Serverless 优先**: 最大限度利用无服务器计算资源 (GCP Cloud Functions, Cloudflare Workers) 以降低运维成本和实现弹性伸缩。
* **成本优化**: 优先选择具有慷慨免费套餐和低运营成本的云服务。
* **基础设施即代码 (IaC)**: 使用 Terraform统一管理和版本化所有云基础设施资源。
* **语言选型**:
    * GCP Cloud Functions: **Go**。
    * Cloudflare Worker: **TypeScript**。
* **数据存储**:
    * 媒体文件: Cloudflare R2 Storage (`ns-r2-nasa-media`)，内部按API模块使用对象键前缀（如 `apod/`）组织。
    * 元数据: GCP Firestore (Native Mode)，为每个NASA API模块使用独立的顶级集合 (例如 `ns-fs-apod-metadata`)。
* **命名约定**: 遵循项目已定义的 `ns-naming-conventions-20250524.md` 文档。
* **代码组织**: Monorepo 结构。
* **文档化**: 在 `docs/` 目录下维护统一的项目文档 (扁平结构)。
* **GCS 存储桶策略**: 使用一个统一的 GCS 存储桶 (`ns-gcs-unified-sigma-outcome`)，由 Terraform 创建和管理，用于存放 Terraform 状态 (路径前缀 `tfstate/novascope/`) 和函数源码包 (路径前缀 `sources/functions/`)。

## 3. 系统架构概述 (文字描述)

NovaScope 系统采用前后端分离的无服务器架构，部署在 Cloudflare 和 Google Cloud Platform (GCP) 上。

* **用户端 (Browser)**: 用户通过浏览器访问由 Cloudflare Worker 提供的网页。
* **Cloudflare (边缘层)**:
    * **Cloudflare Worker (`ns`)**: 作为应用的前端和边缘逻辑处理器 (TypeScript)。负责接收用户请求，向 GCP 后端请求元数据，构建媒体文件URL，动态生成 HTML。
    * **Cloudflare R2 Storage (`ns-r2-nasa-media`)**: 存储所有 NASA API 的媒体文件，内部按 API 模块使用对象键前缀区分。
    * **Cloudflare CDN**: 自动缓存 R2 中的图片及 Worker 响应。
    * **Worker Secrets**: 用于安全存储调用 GCP 后端所需的共享密钥等。
* **Google Cloud Platform (GCP - 后端层)**:
    * **Cloud Function (`ns-func-fetch-<api_module>`)**: 针对每个 NASA API 模块的数据获取函数 (Go)，例如 `ns-func-fetch-apod`。由 Cloud Scheduler + Pub/Sub 触发。负责从对应 NASA API 获取数据，媒体存 R2，元数据存 Firestore。
    * **Cloud Function (`ns-func-get-metadata`)**: (计划中) HTTP 触发的API函数 (Go)，负责从 Firestore 查询指定模块的元数据，供 Worker 调用。
    * **GCP Firestore**: 为每个 NASA API 模块使用独立顶级集合存储元数据 (例如 `ns-fs-apod-metadata`)。
    * **GCP Cloud Scheduler**: 为每个需要定时获取的 `ns-func-fetch-<api_module>` 函数配置相应的调度作业 (例如 `ns-sched-daily-apod-fetch`)。
    * **GCP Pub/Sub**: 作为 Scheduler 和 Fetch Functions 之间的事件总线 (例如 `ns-ps-daily-apod-trigger`)。
    * **GCP Secret Manager**: 存储 NASA API 密钥、R2 访问凭证、共享密钥等。
    * **GCP Cloud Storage (`ns-gcs-unified-sigma-outcome`)**: 统一存储桶，用于 Terraform 远程状态和所有 Cloud Functions 的源码包。
* **外部服务**:
    * **NASA APIs**: 项目的原始数据来源。

## 4. 组件详解 
(此部分内容与上一版文字描述基本一致，细节将根据每个模块的实现进行填充，此处省略以保持简洁，具体请参考上一版详细的组件描述)

### 4.1 前端/边缘层 (Cloudflare)
    * Cloudflare Worker (`ns`)
    * Cloudflare R2 Storage (`ns-r2-nasa-media`)
    * Cloudflare CDN
    * Worker Secrets

### 4.2 后端逻辑层 (GCP)
    * Cloud Function (`ns-func-fetch-apod`)
    * Cloud Function (`ns-func-get-metadata` - 计划中)

### 4.3 数据存储层 (GCP)
    * GCP Firestore (例如集合 `ns-fs-apod-metadata`)

### 4.4 调度与自动化层 (GCP)
    * GCP Cloud Scheduler (`ns-sched-daily-apod-fetch`)
    * GCP Pub/Sub Topic (`ns-ps-daily-apod-trigger`)

### 4.5 密钥管理
    * GCP Secret Manager (各类 `ns-sm-*` 密钥)
    * Cloudflare Worker Secrets

### 4.6 基础设施即代码 (Terraform)
    * 使用 GCS 统一存储桶 (`ns-gcs-unified-sigma-outcome`) 作为后端。

### 4.7 外部服务
    * NASA APOD API (及未来其他 NASA API)

## 5. 数据流 (APOD 模块示例)
(此部分内容与上一版基本一致，此处省略，具体请参考上一版详细的数据流描述)

### 5.1 用户访问 APOD 页面 (未来通过 Worker `ns` 和 `ns-func-get-metadata`)
### 5.2 每日数据获取与缓存 (`ns-func-fetch-apod` 流程)

## 6. 安全考量
(此部分内容与上一版基本一致，此处省略，具体请参考上一版详细的安全考量)

## 7. 可伸缩性与性能
(此部分内容与上一版基本一致，此处省略，具体请参考上一版详细的说明)

## 8. 成本考量
(此部分内容与上一版基本一致，此处省略，具体请参考上一版详细的说明)

## 9. 命名约定参考
本项目所有资源的命名遵循 `docs/ns-naming-conventions-20250524.md` 文档中定义的规范。

## 10. 未来可能的增强方向 (可选)
(此部分内容与上一版基本一致，此处省略)

---