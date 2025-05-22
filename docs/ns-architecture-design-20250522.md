# NovaScope 项目架构设计文档 (ns-architecture-design-20250522.md)

**项目名称**: NovaScope
**文档版本**: 1.0
**创建日期**: 2025年5月22日
**最后更新**: 2025年5月22日 22:23 (UTC+8)

## 1. 引言

### 1.1 项目目标
NovaScope 项目旨在创建一个高效、低成本、易于维护的 Web 应用，用于每日展示美国国家航空航天局 (NASA) 的每日天文图片 (APOD) 及其相关信息。

### 1.2 文档目的
本文档详细描述 NovaScope 项目的系统架构、关键组件、技术选型、数据流以及设计原则，为项目的开发、部署和后续迭代提供指导。

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

## 3. 系统架构图

```mermaid
graph LR
    subgraph "用户端 (Browser)"
        A[用户浏览器]
    end

    subgraph "Cloudflare (Edge Layer)"
        B[CF Worker: ns-worker-apod-frontend (TS)]
        C[CF R2 Storage: ns-r2-apod-images]
        CDN[Cloudflare CDN]
        W_S[Worker Secrets (e.g., NS_GCP_SHARED_SECRET)]
    end

    subgraph "Google Cloud Platform (Backend Layer)"
        D[GCP Cloud Scheduler: ns-sched-daily-apod-fetch]
        E[GCP Cloud Function: ns-func-fetch-apod (Go)]
        F[GCP Cloud Function: ns-func-get-metadata (Go)]
        G[GCP Secret Manager: ns-sm-*-keys]
        H[(NASA APOD API - External)]
        J[GCP Firestore (Collection: ns-fs-apod-metadata)]
    end

    %% User Request Flow
    A -- "1. 请求 APOD 页面" --> B
    B -- "2. 从 Worker Secrets 获取共享密钥" --> W_S
    B -- "3. 调用 ns-func-get-metadata (携带共享密钥)" --> F
    F -- "4. 验证共享密钥" --> F
    F -- "5. 从 Firestore 读取元数据" --> J
    J -- "元数据" --> F
    F -- "6. 返回元数据给 Worker" --> B
    B -- "7. 构建R2图片URL, 生成HTML" --> A
    A -- "8. 请求 R2 图片 (通过 CDN)" --> CDN
    CDN -- "缓存/从R2获取" --> C

    %% Daily Data Fetch Flow
    D -- "每天定时触发" --> E
    E -- "从 Secret Manager 获取 NASA API Key, R2 Creds" --> G
    E -- "调用 NASA APOD API" --> H
    H -- "APOD 图片和元数据" --> E
    E -- "图片写入 R2 (ns-r2-apod-images)" --> C
    E -- "元数据写入 Firestore (ns-fs-apod-metadata)" --> J