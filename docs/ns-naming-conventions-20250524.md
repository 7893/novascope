Path: novascope/docs/ns-naming-conventions-20250524.md

# NovaScope 项目命名规范 (ns-naming-conventions-20250524.md)

_**文档说明**：本规范旨在为 NovaScope 项目在 Google Cloud Platform (GCP), Cloudflare (CF), GitHub 及代码库中的各类资源、文件、变量等提供统一的命名约定和示例，以提高可读性、可维护性和自动化处理的便利性。常用缩写包括 `gcp` (Google Cloud Platform), `cf` (Cloudflare), `func` (Function), `fs` (Firestore), `r2` (R2 Storage), `sched` (Scheduler), `sm` (Secret Manager), `gcs` (Google Cloud Storage), `worker` (Cloudflare Worker)。_

_**架构版本参考**：NovaScope 初始架构_
_**本规范内容截至**：2025年5月24日 20:51 (UTC+8)_

---

## 0. 文档自身规范 (新增)

* **文件名**: 项目主要文档（如本文档、架构文档、清单文档）应使用 `ns-<描述>-YYYYMMDD.md` 的格式，存放于 `docs/` 目录下。
* **文档头部**: 每个主要文档的开头应包含：
    1.  `Path: <仓库内完整路径/文件名>`，例如 `Path: novascope/docs/ns-naming-conventions-20250524.md`。
    2.  文档主标题应包含文件名，例如 `# NovaScope 项目命名规范 (ns-naming-conventions-20250524.md)`。
    3.  明确的“本规范内容截至”或“最后更新”时间戳，使用 `YYYY年M月D日 HH:MM (UTC+8)` 格式。

---

## 1. 共通原则

* **风格 (云资源与文件名)**: 优先使用**小写字母**，单词间用**连字符 `-` (kebab-case)** 连接。
* **风格 (代码内部)**: 遵循各自语言的约定：
    * **Go**: `camelCase` 或 `PascalCase`，包名 `lowercase`。
    * **TypeScript**: `camelCase` (函数/变量), `PascalCase` (类/接口/类型别名)。
    * **Terraform 本地资源名**: `snake_case`。
* **前缀**: 使用项目标识 **`ns-`** 作为大部分云资源和项目内部主要模块/目录的前缀。
* **环境标识 (可选)**: 未来可加入 `-stg`, `-prod` 等后缀。
* **简洁明了**: 名称应清晰反映用途，适当使用约定缩写。
* **一致性**: 尽可能保持命名风格一致。

---

## 2. GitHub 命名规范与示例

| 类型              | NovaScope 示例                                                          | 描述与约定                                                                 |
| :---------------- | :---------------------------------------------------------------------- | :------------------------------------------------------------------------- |
| Repository        | `novascope` (或 `ns-monorepo`)                                            | 主代码仓库。                                                                 |
| Actions Workflows | `ci.yml`, `deploy-gcp.yml`, `deploy-cf.yml`                             | GitHub Actions 工作流文件名。                                                |
| Actions Secrets   | `NS_CF_API_TOKEN`, `NS_GCP_SA_KEY_JSON`, `NS_NASA_API_KEY`              | Actions Secrets 名称，**UPPER_SNAKE_CASE**，前缀 `NS_`。                     |

---

## 3. 代码库 (Monorepo `gcp_functions_go/`, `cf_worker_ts/`) 命名规范与示例

| 类型                         | NovaScope 示例                                                              | 描述与约定                                                                      |
| :--------------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------ |
| **Go - GCP Functions 目录** | `gcp_functions_go/ns-func-fetch-apod/`, `gcp_functions_go/ns-func-get-metadata/` | 顶级目录 `gcp_functions_go/`，函数子目录 `ns-func-<功能描述>`。                       |
| **Go - 包名** | `package main`, `package utils`                                             | 标准 Go 包命名。                                                                  |
| **Go - 文件名** | `main.go`, `handlers.go`, `firestore_client.go`                             | `snake_case.go`。                                                               |
| **Go - 函数/变量/类型名** | `WorkspaceApodData`, `getUserConfig`, `type ApodEntry struct {...}`               | Go 语言约定 (`camelCase`/`PascalCase`)。                                          |
| **TypeScript - Worker 目录**| `cf_worker_ts/`                                                             | 顶级目录。                                                                      |
| **TypeScript - 文件与目录** | `src/index.ts`, `src/api-client.ts`, `src/html-renderer.ts`                 | `kebab-case.ts`。                                                               |
| **TypeScript - 类/接口/类型** | `ApodApiClient`, `interface IApodResponse {...}`, `type ApodData = {...}`     | `PascalCase`。                                                                  |
| **TypeScript - 函数/方法名** | `WorkspaceMetadata`, `renderHtmlPage`                                           | `camelCase`。                                                                   |
| **TypeScript - 变量/常量名**| `apiUrl`, `const DEFAULT_DATE_FORMAT = "YYYY-MM-DD"`                          | `camelCase` (变量), `UPPER_SNAKE_CASE` (常量)。                                     |

---

## 4. Cloudflare (CF) 命名规范与示例

**基本格式**: `ns-<cf服务简称>-<主要功能描述>[-可选标识]`

| 类型            | NovaScope 示例                                           | 描述                                                                   |
| :-------------- | :------------------------------------------------------- | :--------------------------------------------------------------------- |
| Worker Script   | `ns` (由 `var.worker_script_name` 控制)                  | Worker 服务名称。                                                        |
| R2 Bucket       | `ns-r2-nasa-media`                                       | R2 存储桶名称 (全局唯一)。                                                 |
| Secrets (Worker)| `NS_GCP_SHARED_SECRET`, `NS_GCP_METADATA_URL`, `NS_CF_API_TOKEN` | Worker Secrets 名称 (在 `wrangler.toml` 或 Dashboard 中)，**UPPER_SNAKE_CASE**。 |

---

## 5. Google Cloud Platform (GCP) 命名规范与示例

**基本格式**: `ns-<gcp服务简称>-<主要功能描述>[-可选标识]`

| 类型                     | NovaScope 示例                                                       | 描述                                                                 |
| :----------------------- | :------------------------------------------------------------------- | :------------------------------------------------------------------- |
| Project ID               | `sigma-outcome` (您的项目ID，通常创建后固定)                           | GCP 项目ID。                                                           |
| Cloud Function           | `ns-func-fetch-apod`, `ns-func-get-metadata`                         | Cloud Function 服务名称。                                                |
| Firestore Database ID    | `(default)`                                                          | Firestore 数据库实例ID。                                               |
| Firestore Collection     | `ns-fs-apod-metadata`, `ns-fs-mrp-metadata` (示例)                   | Firestore 集合名称。                                                 |
| Cloud Storage Bucket(GCS)| `ns-gcs-unified-sigma-outcome` (统一存储桶)                         | GCS 存储桶名称 (全局唯一)。                                            |
| Service Account          | `sa-ns-functions@sigma-outcome.iam.gserviceaccount.com` (若创建专用SA) | 服务账号邮箱。 `sa-ns-<用途>` 结构。                                   |
| Secret Manager Secret ID | `ns-sm-nasa-api-key`, `ns-sm-r2-key-id`, `ns-sm-cf-shared-secret`      | Secret Manager 中的密钥ID。                                            |
| Cloud Scheduler Job      | `ns-sched-daily-apod-fetch`                                          | Cloud Scheduler 作业名称。                                             |
| Pub/Sub Topic            | `ns-ps-daily-apod-trigger`                                           | Pub/Sub 主题名称。                                                   |

---

## 6. Terraform 内部资源名 (IaC)

Terraform 内部的资源名称 (resource "type" "**local_name**") 应采用 **`snake_case`**。

| 云平台资源类型 (示例)     | Terraform 资源类型 (示例)           | Terraform 内部名 (示例)             | 云平台实际名称 (`name`属性等) (示例)         |
| :------------------------ | :---------------------------------- | :---------------------------------- | :--------------------------------------- |
| CF Worker Script          | `cloudflare_worker_script`          | `ns_frontend_worker`                | `ns`                                     |
| CF R2 Bucket              | `cloudflare_r2_bucket`              | `ns_r2_nasa_media_bucket`           | `ns-r2-nasa-media`                       |
| GCP Cloud Function        | `google_cloudfunctions2_function`   | `ns_func_fetch_apod`, `ns_func_get_metadata` | `ns-func-fetch-apod`, `ns-func-get-metadata` |
| GCP Secret Manager Secret | `google_secret_manager_secret`      | `ns_sm_nasa_api_key`                | `ns-sm-nasa-api-key`                     |
| GCP Cloud Scheduler Job   | `google_cloud_scheduler_job`        | `ns_sched_daily_apod_fetch`         | `ns-sched-daily-apod-fetch`              |
| GCP GCS Bucket            | `google_storage_bucket`             | `ns_unified_gcs_bucket`             | `ns-gcs-unified-sigma-outcome`           |

---

✅ **总结**
所有 NovaScope 项目的资源、代码和服务组件的命名应力求**清晰、一致、可预测**，并严格遵循本规范。通过 `ns-` 前缀和约定的服务缩写可以很好地区分项目资源。

---