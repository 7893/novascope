好的，我们已经完成了项目架构设计文档、命名规范文档以及可观测性实施规范文档的更新。

根据我们之前精简后的核心项目文档列表，下一个应该输出的文档是 **项目资源清单与IaC边界文档**。

我将基于您之前提供的 `ns-resource-inventory-20250603.md` 的内容（即您上次提供的那份包含GCP和CF资源、Terraform管理边界、以及可观测性考量的清单），并严格遵循您对文档编制的所有要求，来生成这份文档。

**核心调整：**
* 确保所有资源名称与我们最新确认的命名规范 (`ns-naming-conventions-20250605.md`) 和架构 (`ns-architecture-design-20250605.md`) 完全一致。
* 确保文档结构清晰，信息完整。

---

Path: novascope/docs/ns-resource-inventory-20250605.md
# NovaScope 项目资源清单与IaC边界 (ns-resource-inventory-20250605.md)
**最后更新时间**: 2025年6月5日 11:50 (UTC+8)

## 0. 引言
本文件旨在提供 NovaScope 项目所涉及的所有云平台资源（主要为 Google Cloud Platform 和 Cloudflare）的完整清单，并明确指出哪些资源将通过基础设施即代码（IaC）工具 Terraform进行管理，哪些资源由于其特性或管理策略将不纳入或部分纳入 Terraform 管理。本清单基于项目架构设计文档 `ns-architecture-design-20250605.md` 和命名规范文档 `ns-naming-conventions-20250605.md`。

## 1. Google Cloud Platform (GCP) 资源

### 1.1 纳入 Terraform 管理的资源

| 资源类型 (GCP)          | Terraform 逻辑资源名 (示例)                        | 云平台实际名称 (遵循命名规范)                                  | 说明与用途                                                                                                                               |
| :---------------------- | :--------------------------------------------------- | :------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------- |
| 项目 ID                 | –                                                    | `sigma-outcome`                                               | 已有项目，Terraform 配置中作为 `project` 属性引用，不通过Terraform创建项目本身。                                                                      |
| GCS 存储桶              | `google_storage_bucket.project_backend_bucket`       | `ns-gcs-sigma-outcome`                                        | 统一存储桶，用于存放 Terraform 远程状态文件 (路径: `tfstate/novascope/`) 和 Cloud Functions 的源代码部署包 (路径: `sources/functions/`)。 |
| Firestore 数据库        | –                                                    | `(default)`                                                   | 通常使用项目默认的 Firestore 数据库 (Native Mode)。Terraform 主要管理其安全规则和索引，数据库实例本身随服务启用而存在。                                   |
| Firestore 安全规则      | `google_firestore_ruleset.rules`                     | –                                                             | 定义 Firestore 数据库的访问控制规则，存储在 `infra/gcp/firestore.rules` 文件中。                                                                 |
| Firestore 索引          | `google_firestore_index.example_index` (多个)        | –                                                             | 定义 Firestore 集合的复合查询索引，配置通常在 `infra/gcp/firestore.indexes.json` 文件中。                                                        |
| Pub/Sub 主题            | `google_pubsub_topic.daily_fetch_pubsub_topic`       | `ns-ps-daily-nasa-fetch`                                      | 统一的事件触发主题，由 Cloud Scheduler 发布消息，Cloud Function (`ns-func-fetch-nasa-data`) 订阅。                     |
| Cloud Scheduler Job     | `google_cloud_scheduler_job.daily_fetch_scheduler_job` | `ns-sched-daily-fetch`                                        | 每日定时触发器，向 `ns-ps-daily-nasa-fetch` 主题发送消息以启动统一数据抓取函数。                             |
| Cloud Function (抓取器) | `google_cloudfunctions2_function.fetch_nasa_data_function` | `ns-func-fetch-nasa-data`                                     | 统一的 Python 云函数，负责从所有NASA API模块抓取数据，并将媒体存至R2、元数据存至Firestore。                    |
| Cloud Function (API服务) | `google_cloudfunctions2_function.api_nasa_data_function` | `ns-api-nasa-data`                                        | HTTP 触发的 Python 云函数，供 Cloudflare Worker 调用以获取 Firestore 中的元数据。                         |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.nasa_api_key`          | `ns-nasa-api-key`                                             | 存储 NASA API 访问密钥的容器。实际密钥值需手动添加为版本。                                                                                       |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.r2_access_key_id`      | `ns-r2-access-key-id`                                         | 存储 Cloudflare R2 访问密钥 ID 的容器。                                                                                                   |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.r2_secret_access_key`  | `ns-r2-secret-access-key`                                     | 存储 Cloudflare R2 访问密钥 Secret 的容器。                                                                                               |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.cf_worker_shared_secret` | `ns-cf-worker-shared-secret`                                  | 存储 Cloudflare Worker 与 GCP `ns-api-nasa-data` 函数之间共享认证令牌的容器。                                                              |
| 服务账号                | `google_service_account.ns_functions_sa`             | (例如) `sa-ns-functions@sigma-outcome.iam.gserviceaccount.com` | 专为 Cloud Functions 创建的服务账号，授予最小必要权限。Terraform 创建服务账号本身。                                                              |
| IAM 绑定                | `google_project_iam_member.functions_sa_*` (多个)    | –                                                             | 将必要的IAM角色（如 Secret Manager Secret Accessor, Firestore User, Pub/Sub Publisher/Subscriber 等）绑定到上述服务账号。                       |
| 日志导出接收器 (Sink)   | `google_logging_project_sink.default_sink_to_bq`     | (例如) `ns-log-sink-gcp-functions-to-bq`                      | (可选但推荐) 将 Cloud Functions 的结构化日志从 Cloud Logging 导出到 BigQuery 或 GCS 进行长期存储和分析。                  |
| 监控告警策略            | `google_monitoring_alert_policy.func_error_alert` (多个) | (例如) `ns-alert-function-errors`, `ns-alert-scheduler-failures` | 定义 Cloud Monitoring 中的告警规则，例如函数错误率超标、调度作业失败等，并通过邮件等渠道通知。                       |

### 1.2 不纳入 Terraform 管理的 GCP 资源 (或仅部分管理)

| 资源类型             | 实际名称 (示例)                                | 理由与管理方式                                                                                                |
| :------------------- | :--------------------------------------------- | :---------------------------------------------------------------------------------------------------------- |
| Firestore 集合与文档 | `ns-fs-apod-metadata/2025-06-05` 等            | 集合和文档由应用代码 (`ns-func-fetch-nasa-data`) 在运行时动态创建和管理。Terraform仅管理其安全规则和索引。       |
| Secret Manager 密钥值 | (密钥的实际内容)                               | 为安全起见，密钥的实际值（版本）不应存储在Terraform代码中，通常在创建密钥壳体后通过GCP控制台或gcloud CLI手动添加第一个版本。 |
| Cloud Logging 日志内容 | (实际产生的日志条目)                           | 日志由服务自动生成和收集。Terraform可管理日志导出接收器，但不管理日志本身。                                         |
| Cloud Monitoring 仪表盘 | (自定义的监控仪表盘)                           | 仪表盘通常在GCP控制台中根据实际监控需求手动创建和配置，以便更灵活地可视化指标。Terraform可以管理告警策略。        |

## 2. Cloudflare (CF) 资源

### 2.1 纳入 Terraform 管理的资源

| 资源类型 (CF)    | Terraform 逻辑资源名 (示例)             | Cloudflare 实际名称 (遵循命名规范) | 说明与用途                                                                                                  |
| :--------------- | :-------------------------------------- | :--------------------------------- | :-------------------------------------------------------------------------------------------------------- |
| Worker 脚本      | `cloudflare_worker_script.frontend_worker` | `ns`                               | 主前端Cloudflare Worker，运行TypeScript代码，负责SSR、API代理等。部署内容来自`apps/frontend/`目录。 |
| Worker Route     | `cloudflare_worker_route.frontend_route`   | `*.<your_account_id>.workers.dev/*` 或 `脚本名.自定义子域.workers.dev/*` | 将特定域名或路径模式的流量路由到名为`ns`的Worker脚本。默认使用`*.workers.dev`子域。                               |
| R2 存储桶        | `cloudflare_r2_bucket.media_storage_bucket`| `ns-nasa`                          | 统一存储所有从NASA API下载的媒体文件（图片、视频等）。                                 |
| R2 Bucket Binding| (在`cloudflare_worker_script`资源内配置) | (逻辑绑定名称，如`NASA_MEDIA_BUCKET`) | 在Worker脚本中配置，使得Worker代码可以通过绑定的名称直接访问`ns-nasa` R2存储桶。                                 |
| Worker Secrets (壳体) | `cloudflare_worker_secret.gcp_api_url` (多个) | `NS_GCP_API_URL`, `NS_GCP_SHARED_SECRET` | 定义Worker可以访问的Secret变量名称。实际的Secret值通过Cloudflare仪表盘或Wrangler CLI安全地设置。         |

### 2.2 不纳入 Terraform 管理的 CF 资源 (或仅部分管理)

| 资源类型         | 实际名称 (示例)                           | 理由与管理方式                                                                                                                            |
| :--------------- | :---------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| Worker Secrets 的值 | (Secret的实际内容)                        | 为安全起见，敏感的Secret值不存储在Terraform代码中，通常通过Cloudflare仪表盘或Wrangler CLI命令进行设置。                       |
| R2 存储桶中的对象 | `apod/image.jpg` 等                       | 桶中的具体媒体文件由GCP Cloud Function (`ns-func-fetch-nasa-data`) 在运行时上传和管理。Terraform仅管理R2存储桶本身。     |
| DNS 记录 (如使用自定义域) | (例如 `yourdomain.com` 的 CNAME 或 A 记录) | 如果未来为Worker绑定自定义域名，相关的DNS记录通常在Cloudflare DNS服务中手动配置，或通过Terraform的Cloudflare DNS Provider管理（目前项目不涉及自定义域名）。 |
| Wrangler `tail` 日志 | (实时的Worker日志流)                      | 主要用于开发和调试时通过`wrangler tail`命令实时查看，不属于基础设施资源。                                                                 |

## 3. 其他辅助资源与配置

| 资源类型        | 实际名称/路径 (示例)                                 | 管理方式                                                                 | 说明与用途                                                                      |
| :-------------- | :--------------------------------------------------- | :----------------------------------------------------------------------- | :------------------------------------------------------------------------------ |
| GitHub 仓库     | `novascope`                                          | 手动创建和管理 (或通过GitHub Terraform Provider，但通常手动)           | 存储所有项目代码、文档、Terraform配置等。                                       |
| GitHub Actions Secrets | `GCP_SA_KEY_JSON`, `CF_API_TOKEN`, `CF_ACCOUNT_ID` | 在GitHub仓库的Secrets设置中手动配置                                       | 用于CI/CD工作流（例如部署GCP和Cloudflare资源）进行身份验证。                     |
| Terraform 状态后端 | `gs://ns-gcs-sigma-outcome/tfstate/novascope/`       | Terraform根据`backend "gcs"`块配置自动生成和管理存储在GCS中的状态文件。 | 安全、持久地存储Terraform管理的基础设施状态。                                   |
| `.gitignore` 文件 | `.gitignore`                                         | 手动创建和维护，纳入版本控制                                                | 指定Git应忽略的文件和目录（如`venv/`, `node_modules/`, `.tfstate*`本地文件, `.env`等）。 |
| 本地环境变量文件  | `.env` (项目根目录或各应用子目录)                        | 手动创建，**必须添加到`.gitignore`中不提交到版本库** | 存储本地开发时使用的敏感配置或环境变量，方便本地运行和调试。                   |

---

这份资源清单旨在为NovaScope项目的IaC实施和日常管理提供清晰的指引。通过明确Terraform的管理边界，可以确保基础设施的一致性、安全性和可维护性。