# NovaScope 项目架构设计文档 (ns-architecture-design-20250523.md)

**项目名称**: NovaScope
**文档版本**: 1.1 (移除了图表，更新时间)
**创建日期**: 2025年5月22日
**最后更新**: 2025年5月23日 09:23 (UTC+8)

## 1. 引言

### 1.1 项目目标
NovaScope 项目旨在创建一个高效、低成本、易于维护的 Web 应用，用于每日展示美国国家航空航天局 (NASA) 的每日天文图片 (APOD) 及其相关信息。

### 1.2 文档目的
本文档详细描述 NovaScope 项目的系统架构、关键组件、技术选型、数据流以及设计原则，为项目的开发、部署和后续迭代提供指导。

---
## 2. 核心设计原则与决策

* **Serverless 优先**: 最大限度利用无服务器计算资源 (GCP Cloud Functions, Cloudflare Workers) 以降低运维成本和实现弹性伸缩。
* **成本优化**: 优先选择具有慷慨免费套餐和低运营成本的云服务。
* **基础设施即代码 (IaC)**: 使用 Terraform统一管理和版本化所有云基础设施资源。
* **语言选型**:
    * GCP Cloud Functions: **Go** (追求高性能和高效率)。
    * Cloudflare Worker: **TypeScript** (利用 V8 性能和类型安全)。
* **数据存储**:
    * 图片对象: Cloudflare R2 Storage。
    * 图片元数据: GCP Firestore。
* **命名约定**: 遵循项目已定义的 `ns-naming-conventions-20250522.md` 文档，核心前缀为 `ns-`。
* **代码组织**: 采用 Monorepo 结构，集中管理所有项目代码。
* **文档化**: 在 `docs/` 目录下维护统一的项目文档 (扁平结构)。

---
## 3. 系统架构概述 (文字描述)

NovaScope 系统采用前后端分离的无服务器架构，部署在 Cloudflare 和 Google Cloud Platform (GCP) 上。

* **用户端 (Browser)**: 用户通过浏览器访问由 Cloudflare Worker 提供的网页。
* **Cloudflare (边缘层)**:
    * **Cloudflare Worker (`ns-worker-apod-frontend`)**: 作为应用的前端和边缘逻辑处理器，使用 TypeScript 编写。它负责接收用户请求，向 GCP 后端请求 APOD 元数据，构建包含图片和信息的 HTML 页面，并将其返回给用户。
    * **Cloudflare R2 Storage (`ns-r2-apod-images`)**: 存储从 NASA 下载的 APOD 图片。
    * **Cloudflare CDN**: 自动缓存 R2 中的图片及 Worker 响应的静态内容，加速全球访问并降低源站负载。
    * **Worker Secrets**: 用于安全存储调用 GCP 后端所需的共享密钥等。
* **Google Cloud Platform (GCP - 后端层)**:
    * **Cloud Function (`ns-func-get-metadata`)**: 使用 Go 编写的 HTTP 触发函数。负责验证来自 Cloudflare Worker 的请求（通过共享密钥），从 Firestore 查询 APOD 元数据，并以 JSON 格式返回。
    * **Cloud Function (`ns-func-fetch-apod`)**: 使用 Go 编写，由 Cloud Scheduler 定时触发。负责每日从 NASA APOD API 获取最新数据，下载图片存入 Cloudflare R2，并将元数据写入 GCP Firestore。
    * **GCP Firestore (集合: `ns-fs-apod-metadata`)**: NoSQL 数据库，用于存储 APOD 的文本元数据（如标题、解释、日期、R2 图片路径等）。
    * **GCP Cloud Scheduler (`ns-sched-daily-apod-fetch`)**: 定时任务服务，每日触发 `ns-func-fetch-apod` 函数。
    * **GCP Secret Manager (`ns-sm-*-keys`)**: 存储敏感信息，如 NASA API 密钥、R2 访问凭证、后端函数间通信的共享密钥等。
* **外部服务**:
    * **NASA APOD API**: 项目的原始数据来源。

---
## 4. 组件详解

### 4.1 前端/边缘层 (Cloudflare)

* **Cloudflare Worker (`ns-worker-apod-frontend`)**:
    * **语言**: TypeScript。
    * **职责**:
        1.  接收用户 HTTP 请求。
        2.  调用 GCP `ns-func-get-metadata` 函数获取 APOD 元数据（通过共享密钥认证）。
        3.  根据获取的元数据构建指向 Cloudflare R2 中图片的 URL。
        4.  动态生成包含 APOD 信息的 HTML 页面并响应给用户。
    * **部署**: 通过 Wrangler CLI 和/或 Terraform (`cloudflare_worker_script`)。
* **Cloudflare R2 Storage (`ns-r2-apod-images`)**:
    * **职责**: 存储从 NASA 下载的每日天文图片。
    * **访问**: 图片通过 Cloudflare CDN 对外提供，以优化加载速度和降低出口成本。
    * **管理**: 通过 Terraform (`cloudflare_r2_bucket`) 创建和配置。
* **Cloudflare CDN**:
    * **职责**: 自动缓存 R2 中的图片和 Worker 响应的静态内容，加速全球访问。
* **Worker Secrets**:
    * **职责**: 安全存储 Worker 调用 GCP 后端所需的共享密钥 (`NS_GCP_SHARED_SECRET`) 和后端 API URL (`NS_GCP_METADATA_URL`)。
    * **管理**: 通过 Wrangler CLI 或 Cloudflare Dashboard 设置，并在 Terraform 中引用（如果适用）。

### 4.2 后端逻辑层 (GCP)

* **Cloud Function (`ns-func-fetch-apod`)**:
    * **语言**: Go。
    * **触发器**: GCP Cloud Scheduler (`ns-sched-daily-apod-fetch`) 每日定时触发。
    * **职责**:
        1.  从 GCP Secret Manager 安全获取 NASA API 密钥和 Cloudflare R2 访问凭证。
        2.  调用 NASA APOD API 获取当日图片及元数据。
        3.  下载图片并上传至 Cloudflare R2 (`ns-r2-apod-images`)。
        4.  将图片元数据（标题、解释、日期、R2 图片路径等）写入 GCP Firestore 的 `ns-fs-apod-metadata` 集合。
    * **部署**: 通过 Terraform (`google_cloudfunctions2_function`)。
* **Cloud Function (`ns-func-get-metadata`)**:
    * **语言**: Go。
    * **触发器**: HTTP 请求 (由 Cloudflare Worker 调用)。
    * **职责**:
        1.  验证请求头中由 Cloudflare Worker 传递的共享密钥（期望值从 GCP Secret Manager 读取）。
        2.  根据请求参数（通常是日期）从 GCP Firestore 的 `ns-fs-apod-metadata` 集合查询 APOD 元数据。
        3.  以 JSON 格式返回元数据。
    * **部署**: 通过 Terraform (`google_cloudfunctions2_function`)。

### 4.3 数据存储层 (GCP)

* **GCP Firestore**:
    * **集合**: `ns-fs-apod-metadata`。
    * **职责**: 存储 APOD 的文本元数据，如标题、解释、日期以及指向 R2 中对应图片的引用/路径。文档 ID 可以使用日期 (`YYYY-MM-DD`)。
    * **访问**: 由 `ns-func-fetch-apod` 写入，由 `ns-func-get-metadata` 读取。
    * **管理**: Firestore API 通过 Terraform 启用，集合和文档由应用代码（Go 函数）管理。

### 4.4 调度与自动化层 (GCP)

* **GCP Cloud Scheduler (`ns-sched-daily-apod-fetch`)**:
    * **职责**: 每日定时触发 `ns-func-fetch-apod` Cloud Function，以实现 APOD 数据的自动更新。
    * **管理**: 通过 Terraform (`google_cloud_scheduler_job`) 定义。

### 4.5 密钥管理

* **GCP Secret Manager**:
    * **密钥ID示例**: `ns-sm-nasa-api-key`, `ns-sm-r2-key-id`, `ns-sm-r2-secret-access-key`, `ns-sm-cf-worker-shared-secret`。
    * **职责**: 安全存储所有敏感凭证，供 GCP Cloud Functions 在运行时访问。
    * **管理**: 密钥“容器”通过 Terraform (`google_secret_manager_secret`) 创建，实际密钥值安全注入。
* **Cloudflare Worker Secrets**: (已在 4.1 中描述)

### 4.6 基础设施即代码 (Terraform)

* **职责**: 统一管理上述所有云资源的声明、部署和版本控制。
* **文件结构**: 存放在项目根目录的 `terraform/` 子目录下。
* **状态管理**: 推荐使用 GCP Cloud Storage Bucket (`ns-gcs-tfstate`) 作为远程状态后端。

### 4.7 外部服务

* **NASA APOD API**:
    * **职责**: NovaScope 项目的数据来源，提供每日天文图片和相关信息。

---
## 5. 数据流

### 5.1 用户访问 APOD 页面
1.  用户浏览器请求 Cloudflare Worker (`ns-worker-apod-frontend`) 的 URL。
2.  Worker 从其 Secrets 中获取 `NS_GCP_SHARED_SECRET`。
3.  Worker 向 GCP `ns-func-get-metadata` 发起 HTTP GET 请求，携带共享密钥。
4.  `ns-func-get-metadata` 验证密钥，从 Firestore (`ns-fs-apod-metadata`) 读取当日（或指定日期）的元数据。
5.  `ns-func-get-metadata` 将元数据 JSON 返回给 Worker。
6.  Worker 解析元数据，构建指向 R2 (`ns-r2-apod-images`) 中图片的 URL，并渲染包含所有信息的 HTML 页面。
7.  HTML 页面返回给用户浏览器。浏览器随后请求图片，该请求由 Cloudflare CDN 处理并从 R2 提供。

### 5.2 每日数据获取与缓存
1.  GCP Cloud Scheduler (`ns-sched-daily-apod-fetch`) 按预设时间（例如每日一次）触发 GCP `ns-func-fetch-apod`。
2.  `ns-func-fetch-apod` 从 GCP Secret Manager 获取 NASA API 密钥和 R2 凭证。
3.  `ns-func-fetch-apod` 调用 NASA APOD API 获取最新的图片和元数据。
4.  图片被下载并上传到 Cloudflare R2 (`ns-r2-apod-images`)。
5.  元数据被处理并写入 GCP Firestore (`ns-fs-apod-metadata`)。

---
## 6. 安全考量

* **密钥管理**: 所有 API 密钥、服务账号凭证、共享密钥均通过 GCP Secret Manager 或 Cloudflare Worker Secrets 安全存储和访问。
* **服务间认证**: Cloudflare Worker 与 GCP `ns-func-get-metadata` 函数之间通过共享密钥进行基础认证。
* **最小权限原则**: 为 GCP 服务账号和 Cloudflare API Token 配置所需的最小权限。
* **IaC 安全**: Terraform 状态文件（如果包含敏感输出）应安全存储在配置了访问控制的远程后端。敏感变量不应硬编码到 Terraform 文件中（或在练习场景下，确保占位符被真实值替换且文件不被错误提交）。

---
## 7. 可伸缩性与性能

* **Serverless 自动伸缩**: GCP Cloud Functions 和 Cloudflare Workers 均能根据负载自动伸缩，包括缩减到零。
* **CDN 加速**: Cloudflare CDN 用于分发图片和静态内容，减少源站负载，提升全球用户访问速度。
* **R2 Storage**: 设计用于大规模、高持久性的对象存储。
* **Firestore**: 可根据需求自动扩展的高性能 NoSQL 数据库。

---
## 8. 成本考量

* 所选服务 (GCP Cloud Functions, Cloud Scheduler, Firestore, Secret Manager, Cloudflare Workers, R2) 均提供慷慨的免费套餐，对于 NovaScope 项目的初期和演示阶段，运营成本预计极低甚至为零。
* Cloudflare R2 的出口流量通过 Cloudflare CDN 是免费的，显著降低了图片分发成本。

---
## 9. 命名约定参考

本项目所有资源的命名遵循 `ns-naming-conventions-20250522.md` 文档中定义的规范。

---
## 10. 未来可能的增强方向 (可选)

* 更丰富的用户界面和交互功能。
* 支持历史 APOD 图片浏览和搜索。
* 集成 CI/CD 流水线实现自动化部署。
* 更详细的监控和告警。

---