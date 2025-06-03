好的，我们来重新生成一份 `ns-naming-conventions-20250605.md` 文档。

这份文档将采纳您之前提供的所有宝贵评审反馈，包括：
* Secret Manager 密钥ID统一使用 `ns-sm-` 前缀。
* “Open Science Data Repository” 模块的核心标识符统一为 `osdr`。
* “Vesta/Moon/Mars Trek WMTS” 模块的核心标识符统一为 `trek-wmts` (我们以此为准，如需调整请告知)。
* GCS存储桶的Terraform本地资源名调整为更具体的，例如 `unified_project_gcs_bucket`。
* 增加资源名称确定方式的说明。
* 新增“命名规范维护与更新策略”章节。

---

Path: novascope/docs/ns-naming-conventions-20250605.md
# NovaScope 项目命名规范 (ns-naming-conventions-20250605.md)
**最后更新时间**: 2025年6月5日 12:05 (UTC+8)

_**文档说明**：本规范旨在为 NovaScope 项目在 Google Cloud Platform (GCP), Cloudflare (CF), GitHub, 代码库中的各类资源、文件、变量等提供统一的命名约定和示例，以提高可读性、可维护性和自动化处理的便利性。本规范基于项目架构设计文档 `ns-architecture-design-20250605.md` 中确定的资源名称和结构，并整合了最新的评审反馈。常用缩写包括 `gcp` (Google Cloud Platform), `cf` (Cloudflare), `func` (Function), `fs` (Firestore), `r2` (R2 Storage), `sched` (Scheduler), `sm` (Secret Manager), `gcs` (Google Cloud Storage), `worker` (Cloudflare Worker)。_

---

## 1. 共通原则

* **风格 (云资源名称与顶级目录)**: 优先使用**小写字母**，单词间用**连字符 `-` (kebab-case)** 连接。
* **风格 (代码内部文件名/目录名 - Python)**: `snake_case` (例如 `main.py`, `shared_utils/`, `apod.py`)。
* **风格 (代码内部文件名/目录名 - TypeScript)**: `kebab-case` (例如 `index.ts`, `api-client.ts`) 或遵循特定框架约定。
* **风格 (代码内部变量/函数名等)**: 遵循各自语言的约定：
    * **Python**: `snake_case` (函数/变量)，`PascalCase` (类名)。
    * **TypeScript**: `camelCase` (函数/变量), `PascalCase` (类/接口/类型别名)。
* **风格 (Terraform 本地资源名)**: `snake_case` (例如 `google_storage_bucket.unified_project_gcs_bucket`)。
* **前缀 (云资源)**: 核心云资源统一使用项目标识 **`ns-`** 作为前缀，以明确归属并避免命名冲突。
* **简洁明了**: 名称应清晰反映资源的用途和所属模块（如果适用），在不牺牲可读性的前提下适当使用约定缩写。
* **一致性**: 在整个项目中尽可能保持命名风格和模式的一致性。
* **名称确定方式**: 在后续资源表格中，“名称确定方式”列将指明资源名称是如何产生的：
    * **显式声明 (Terraform)**: 指资源名称在Terraform配置的 `name` (或类似) 参数中直接定义。
    * **应用逻辑生成**: 指资源（如Firestore集合中的文档ID，R2中的对象名）由应用程序代码在运行时根据逻辑生成。
    * **平台默认/内置**: 指资源名称由云平台提供或根据某些平台规则自动生成。

---

## 2. 项目代码库 (Monorepo) 顶级目录结构命名

基于架构设计文档 `ns-architecture-design-20250605.md` 和最终确认的结构。

* **`novascope/`** (项目根目录)
    * **`apps/`**: 存放所有独立部署的应用服务。
        * **`apps/frontend/`**: Cloudflare Worker (TypeScript) 前端应用。
        * **`apps/gcp-py-fetch-nasa-data/`**: GCP Cloud Function (Python) 统一数据抓取器。
            * **`apps/gcp-py-fetch-nasa-data/modules/`**: 存放各NASA API模块的具体Python实现（例如 `apod.py`, `epic.py`）。
        * **`apps/gcp-py-api-nasa-data/`**: GCP Cloud Function (Python) 元数据API服务。
    * **`packages/`**: 存放可在多个应用间共享的可复用代码包。
        * **`packages/shared-utils-py/`**: Python 通用工具库。
            * **`packages/shared-utils-py/shared_utils/`**: 实际的Python包目录。
    * **`infra/`**: 存放所有基础设施即代码 (Terraform) 配置。
        * **`infra/gcp/`**: GCP 平台相关资源的Terraform配置 (例如 `main.tf`, `firestore.rules`, `monitoring.tf`)。
        * **`infra/cloudflare/`**: Cloudflare 平台相关资源的Terraform配置。
    * **`docs/`**: 存放所有项目文档 (例如 `ns-architecture-design-20250605.md`, `ns-naming-conventions-20250605.md`)。
    * **`scripts/`**: 存放各种辅助脚本（如部署脚本、工具脚本等）。
    * **`tests/`**: 存放各类测试代码（单元测试、集成测试、端到端测试）。
    * **`.github/`**: 存放GitHub特定配置，如Actions Workflows。
        * **`.github/workflows/`**: 存放CI/CD工作流配置文件。

---

## 3. Google Cloud Platform (GCP) 资源命名

本节列出的资源名称是云平台上实际创建的名称，基于架构设计文档 `ns-architecture-design-20250605.md` 中资源汇总部分，并采纳了最新评审反馈。

| 资源类型 | 实际名称 (示例) | 名称确定方式 | 说明 |
| :--- | :--- | :--- | :--- |
| Cloud Function (数据抓取) | `ns-func-fetch-nasa-data` | 显式声明 (Terraform) | 统一的数据抓取函数 |
| Cloud Function (API 服务) | `ns-api-nasa-data` | 显式声明 (Terraform) | 供 Worker 调用元数据的 HTTP 函数 |
| Cloud Scheduler Job | `ns-sched-daily-fetch` | 显式声明 (Terraform) | 每日定时触发抓取任务 |
| Pub/Sub Topic | `ns-ps-daily-nasa-fetch` | 显式声明 (Terraform) | 统一的抓取任务触发主题 |
| Firestore 集合 | `ns-fs-<module>-metadata` | 应用逻辑生成 | 例如: `ns-fs-apod-metadata`, `ns-fs-osdr-metadata` (`osdr`为Open Science Data Repository的缩写)。共17个。 |
| GCS 存储桶 | `ns-gcs-sigma-outcome` | 显式声明 (Terraform) | (移除了`unified`) 存储 Terraform 状态和函数源码包 |
| Secret Manager 密钥ID | `ns-sm-nasa-api-key` | 显式声明 (Terraform) | (保留了`sm`前缀) 存储 NASA API 密钥 |
| Secret Manager 密钥ID | `ns-sm-r2-access-key-id` | 显式声明 (Terraform) | 存储 R2 访问密钥 ID |
| Secret Manager 密钥ID | `ns-sm-r2-secret-access-key` | 显式声明 (Terraform) | 存储 R2 访问密钥 Secret |
| Secret Manager 密钥ID | `ns-sm-shared-auth-token` | 显式声明 (Terraform) | Worker 与后端函数共享的鉴权密钥 |
| 服务账号 | (例如) `sa-ns-functions` (逻辑名) | 显式声明 (Terraform) | 实际邮箱地址包含项目ID，Terraform中以逻辑名引用。 |

---

## 4. Cloudflare (CF) 资源命名

基于架构设计文档 `ns-architecture-design-20250605.md` 中资源汇总部分，并采纳了最新评审反馈。

| 资源类型 | 实际名称 | 名称确定方式 | 说明 |
| :--- | :--- | :--- | :--- |
| Worker 脚本 | `ns` | 显式声明 (Terraform/Wrangler) | 主前端 Worker |
| R2 存储桶 | `ns-nasa` | 显式声明 (Terraform) | (移除了`-r2-`和`-media`) 存储 NASA 媒体文件 |
| Worker Secrets (名称) | `NS_GCP_API_URL` | 显式声明 (Terraform/Wrangler) | Worker脚本内引用的环境变量名。实际值手动配置。 |
| Worker Secrets (名称) | `NS_GCP_SHARED_SECRET` | 显式声明 (Terraform/Wrangler) | 存储与 GCP API 通信的共享密钥的名称。 |
| Worker Secrets (名称) | `NS_R2_BUCKET_NAME` | 显式声明 (Terraform/Wrangler) | 存储 R2 桶名的环境变量名称。 |

---

## 5. R2 存储桶内部对象键 (文件夹) 命名

媒体文件在 `ns-nasa` R2存储桶中将按模块组织。文件夹名称（对象键前缀）直接来源于NASA API能力名称（小写，连字符连接，并使用确认后的缩写）。

* **完整列表 (17个)**:
    1.  `apod/`
    2.  `asteroids-neows/`
    3.  `donki/`
    4.  `earth/`
    5.  `eonet/`
    6.  `epic/`
    7.  `exoplanet/`
    8.  `osdr/` (Open Science Data Repository 的缩写)
    9.  `insight/`
    10. `mars-rover-photos/`
    11. `nasa-image-and-video-library/`
    12. `techtransfer/`
    13. `satellite-situation-center/`
    14. `ssd-cneos/`
    15. `techport/`
    16. `tle-api/`
    17. `trek-wmts/` (Vesta/Moon/Mars Trek WMTS 的缩写)

---

## 6. Terraform 内部资源命名 (IaC)

Terraform配置文件内部声明资源时使用的本地名称应采用**`snake_case`**风格。

| 云平台资源类型 (示例)     | Terraform 资源类型 (示例)           | Terraform 内部本地名 (示例)             | 云平台实际名称 (`name`属性等) (示例)         |
| :------------------------ | :---------------------------------- | :------------------------------------ | :--------------------------------------- |
| GCP Cloud Function        | `google_cloudfunctions2_function`   | `fetch_nasa_data_function`, `api_nasa_data_function` | `ns-func-fetch-nasa-data`, `ns-api-nasa-data` |
| GCP Secret Manager Secret | `google_secret_manager_secret`      | `nasa_api_key_secret`, `r2_key_id_secret` | `ns-sm-nasa-api-key`, `ns-sm-r2-access-key-id` |
| GCP Cloud Scheduler Job   | `google_cloud_scheduler_job`        | `daily_fetch_job`                   | `ns-sched-daily-fetch`                   |
| GCP Pub/Sub Topic         | `google_pubsub_topic`               | `daily_fetch_topic`                 | `ns-ps-daily-nasa-fetch`                 |
| GCS Bucket                | `google_storage_bucket`             | `project_gcs_bucket` (修正，例如 `unified_project_gcs_bucket`) | `ns-gcs-sigma-outcome`                   |
| CF Worker Script          | `cloudflare_worker_script`          | `frontend_worker`                   | `ns`                                     |
| CF R2 Bucket              | `cloudflare_r2_bucket`              | `media_r2_bucket`                   | `ns-nasa`                                |

---

## 7. 命名规范维护与更新策略

* 本文档 (`ns-naming-conventions-20250605.md`) 应随项目架构设计文档 (`ns-architecture-design-20250605.md`) 的变化而定期审查和更新，确保两者保持同步。
* 当项目中新增NASA API模块、引入新的云服务资源类型或调整现有资源用途时，必须首先在本命名规范中注册或更新其命名约定。
* 所有Terraform配置、部署脚本、CI/CD流水线配置以及应用代码中涉及资源引用的部分，都应强制遵循本命名规范。任何偏离本规范的命名都应被视为需要修正的问题，以保证项目整体的一致性和可维护性。
* 对本规范的任何重大修改都应经过讨论并记录变更原因。

---

这份命名规范文档旨在为NovaScope项目所有组成部分在命名上的一致性、清晰性和可维护性提供指导，并与最新的架构设计保持完全同步。