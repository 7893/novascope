好的，我完全理解您的要求。从现在开始，我输出的所有文档内容，特别是涉及到列表的部分，都会**完整列出所有项目，不再使用任何省略号或“以此类推”的描述**，确保信息的完整性和精确性。

我们就以这份更新后的**项目命名规范文档**为例，严格按照这个“完整输出”的原则来重新生成。

---

Path: novascope/docs/ns-naming-conventions-20250605.md
# NovaScope 项目命名规范 (ns-naming-conventions-20250605.md)
**最后更新时间**: 2025年6月5日 11:30 (UTC+8)

_**文档说明**：本规范旨在为 NovaScope 项目在 Google Cloud Platform (GCP), Cloudflare (CF), GitHub, 代码库中的各类资源、文件、变量等提供统一的命名约定和示例，以提高可读性、可维护性和自动化处理的便利性。本规范基于项目架构设计文档 `ns-architecture-design-20250605.md` 中确定的资源名称和结构。常用缩写包括 `gcp` (Google Cloud Platform), `cf` (Cloudflare), `func` (Function), `fs` (Firestore), `r2` (R2 Storage), `sched` (Scheduler), `sm` (Secret Manager), `gcs` (Google Cloud Storage), `worker` (Cloudflare Worker)。_

---

## 1. 共通原则

* **风格 (云资源名称与顶级目录)**: 优先使用**小写字母**，单词间用**连字符 `-` (kebab-case)** 连接。
* **风格 (代码内部文件名/目录名 - Python)**: `snake_case` (例如 `main.py`, `shared_utils/`)。
* **风格 (代码内部文件名/目录名 - TypeScript)**: `kebab-case` (例如 `index.ts`, `api-client.ts`) 或遵循特定框架约定。
* **风格 (代码内部变量/函数名等)**: 遵循各自语言的约定：
    * **Python**: `snake_case` (函数/变量)，`PascalCase` (类名)。
    * **TypeScript**: `camelCase` (函数/变量), `PascalCase` (类/接口/类型别名)。
* **风格 (Terraform 本地资源名)**: `snake_case` (例如 `google_storage_bucket.unified_backend_bucket`)。
* **前缀 (云资源)**: 核心云资源统一使用项目标识 **`ns-`** 作为前缀，以明确归属并避免命名冲突。
* **简洁明了**: 名称应清晰反映资源的用途和所属模块（如果适用），在不牺牲可读性的前提下适当使用约定缩写。
* **一致性**: 在整个项目中尽可能保持命名风格和模式的一致性。

---

## 2. 项目代码库 (Monorepo) 顶级目录结构命名

基于架构设计文档 `ns-architecture-design-20250605.md` 和我们的讨论。

* **`novascope/`** (项目根目录)
    * **`apps/`**: 存放所有独立部署的应用服务。
        * **`apps/frontend/`**: Cloudflare Worker (TypeScript) 前端应用。
        * **`apps/gcp-py-fetch-nasa-data/`**: GCP Cloud Function (Python) 统一数据抓取器。
        * **`apps/gcp-py-api-nasa-data/`**: GCP Cloud Function (Python) 元数据API服务。
    * **`packages/`**: 存放可在多个应用间共享的可复用代码包。
        * **`packages/shared-utils-py/`**: Python 通用工具库。
    * **`infra/`**: 存放所有基础设施即代码 (Terraform) 配置。
        * **`infra/gcp/`**: GCP 平台相关资源的Terraform配置。
        * **`infra/cloudflare/`**: Cloudflare 平台相关资源的Terraform配置。
    * **`docs/`**: 存放所有项目文档。
    * **`scripts/`**: 存放各种辅助脚本（如部署脚本、工具脚本等）。
    * **`tests/`**: 存放各类测试代码（单元测试、集成测试、端到端测试）。
    * **`.github/`**: 存放GitHub特定配置，如Actions Workflows。
        * **`.github/workflows/`**: 存放CI/CD工作流配置文件。

---

## 3. Google Cloud Platform (GCP) 资源命名

本节列出的资源名称是云平台上实际创建的名称，基于架构设计文档 `ns-architecture-design-20250605.md` 中“5.1 GCP 资源”部分（架构文档内的章节号可能会因最终版本调整而变化，此处指内容），并结合了我们讨论中最终确认的命名。

* **Cloud Function (统一数据抓取器)**: `ns-func-fetch-nasa-data`
* **Cloud Function (元数据API服务)**: `ns-api-nasa-data`
* **Cloud Scheduler Job**: `ns-sched-daily-fetch`
* **Pub/Sub Topic**: `ns-ps-daily-nasa-fetch`
* **Firestore 集合**:
    * 模式: `ns-fs-<module>-metadata`，其中 `<module>` 是小写连字符格式的模块核心名称。
    * **完整列表 (17个)**:
        1.  `ns-fs-apod-metadata`
        2.  `ns-fs-asteroids-neows-metadata`
        3.  `ns-fs-donki-metadata`
        4.  `ns-fs-earth-metadata`
        5.  `ns-fs-eonet-metadata`
        6.  `ns-fs-epic-metadata`
        7.  `ns-fs-exoplanet-metadata`
        8.  `ns-fs-open-science-data-repository-metadata`
        9.  `ns-fs-insight-metadata`
        10. `ns-fs-mars-rover-photos-metadata`
        11. `ns-fs-nasa-image-and-video-library-metadata`
        12. `ns-fs-techtransfer-metadata`
        13. `ns-fs-satellite-situation-center-metadata`
        14. `ns-fs-ssd-cneos-metadata`
        15. `ns-fs-techport-metadata`
        16. `ns-fs-tle-api-metadata`
        17. `ns-fs-vesta-moon-mars-trek-wmts-metadata`
* **GCS 存储桶**: `ns-gcs-sigma-outcome`
* **Secret Manager 密钥ID (密钥容器)**:
    * 模式: `ns-<secret_purpose>`
    * **完整列表**:
        * `ns-nasa-api-key` (存储NASA API密钥)
        * `ns-r2-access-key-id` (存储Cloudflare R2访问密钥ID)
        * `ns-r2-secret-access-key` (存储Cloudflare R2访问密钥Secret)
        * `ns-cf-worker-shared-secret` (存储Cloudflare Worker与GCP后端API通信的共享认证令牌)
* **服务账号**:
    * 采用抽象描述，例如：“专为NovaScope Cloud Functions设计的服务账号”。
    * 如果需要在Terraform或代码中引用其逻辑名，可以使用如 `sa-ns-functions`，实际邮箱地址将在IAM中创建并由Terraform引用。

---

## 4. Cloudflare (CF) 资源命名

本节列出的资源名称是云平台上实际创建的名称，基于架构设计文档 `ns-architecture-design-20250605.md` 中“5.2 CF 资源”部分（架构文档内的章节号可能会因最终版本调整而变化，此处指内容），并结合了我们讨论中最终确认的命名。

* **Worker 脚本名称**: `ns`
* **R2 存储桶**: `ns-nasa`
* **Worker Secrets (在Cloudflare中配置的密钥名称)**:
    * 遵循大写加下划线的环境变量风格。
    * **示例列表**:
        * `NS_GCP_API_URL` (存储 GCP API 端点 URL)
        * `NS_GCP_SHARED_SECRET` (存储与 GCP API 通信的共享密钥的值)
        * `NS_R2_BUCKET_NAME` (存储 R2 桶名，供 Worker 内部逻辑使用)
        * (未来可能根据实际需求增加其他Worker Secrets)

---

## 5. R2 存储桶内部对象键 (文件夹) 命名

基于我们对17个NASA API模块的讨论，媒体文件在 `ns-nasa` R2存储桶中将按模块组织。文件夹名称（对象键前缀）直接来源于NASA API能力名称（小写，连字符连接）。

* **完整列表 (17个)**:
    1.  `apod/`
    2.  `asteroids-neows/`
    3.  `donki/`
    4.  `earth/`
    5.  `eonet/`
    6.  `epic/`
    7.  `exoplanet/`
    8.  `open-science-data-repository/`
    9.  `insight/`
    10. `mars-rover-photos/`
    11. `nasa-image-and-video-library/`
    12. `techtransfer/`
    13. `satellite-situation-center/`
    14. `ssd-cneos/`
    15. `techport/`
    16. `tle-api/`
    17. `vesta-moon-mars-trek-wmts/`

---

## 6. Terraform 内部资源命名 (IaC)

Terraform配置文件内部声明资源时使用的本地名称 ( `resource "google_cloudfunctions2_function" "this_is_the_local_name" { ... }` ) 应采用**`snake_case`**风格。

| 云平台资源类型 (示例)     | Terraform 资源类型 (示例)           | Terraform 内部本地名 (示例)             | 云平台实际名称 (`name`属性等) (示例)         |
| :------------------------ | :---------------------------------- | :------------------------------------ | :--------------------------------------- |
| GCP Cloud Function        | `google_cloudfunctions2_function`   | `fetch_nasa_data_function`, `api_nasa_data_function` | `ns-func-fetch-nasa-data`, `ns-api-nasa-data` |
| GCP Secret Manager Secret | `google_secret_manager_secret`      | `nasa_api_key`, `r2_access_key_id`    | `ns-nasa-api-key`, `ns-r2-access-key-id` |
| GCP Cloud Scheduler Job   | `google_cloud_scheduler_job`        | `daily_fetch_scheduler_job`           | `ns-sched-daily-fetch`                   |
| GCP Pub/Sub Topic         | `google_pubsub_topic`               | `daily_fetch_pubsub_topic`            | `ns-ps-daily-nasa-fetch`                 |
| GCS Bucket                | `google_storage_bucket`             | `project_backend_bucket`              | `ns-gcs-sigma-outcome`                   |
| CF Worker Script          | `cloudflare_worker_script`          | `frontend_worker_script`              | `ns`                                     |
| CF R2 Bucket              | `cloudflare_r2_bucket`              | `media_storage_bucket`                | `ns-nasa`                                |

---

这份命名规范文档旨在确保NovaScope项目所有组成部分在命名上的一致性、清晰性和可维护性，并与最新的架构设计保持同步。