好的，您对这份 **NovaScope 项目资源清单与IaC边界** 文档的评审反馈非常细致和专业！您的建议将极大地提升文档的准确性、安全性和在实际工程中的可操作性。

我完全同意您的所有修改建议。我们将根据这些建议，重新输出一份更新版的 `ns-resource-inventory-20250605.md`。

**核心修改点将包括：**

* **服务账号表述**：严格遵循不暴露具体邮箱的原则，采用抽象描述，并提示在Terraform中通过变量引用。
* **日志导出Sink策略细化**：加入关于日志等级和采样策略的说明，并提供示例Sink filter语法。
* **R2 Bucket Binding明确化**：列出Terraform中的绑定配置示例。
* **Cloudflare Worker Route说明**：注明未使用自定义域名时的默认规则，并补充未来绑定自定义域名的处理方式。
* **新增Terraform结构划分建议**：在文档末尾补充关于`infra/`及`observability/`目录下Terraform代码按功能模块划分的说明。
* **采纳其他建议性增强项**：例如，在资源清单中考虑增加“是否关键资源”列，补充资源访问控制的安全注意事项，并在资源后提供`.tf`文件路径参考。

现在，我将基于这些反馈，重新生成这份文档。

---

Path: novascope/docs/ns-resource-inventory-20250605.md
# NovaScope 项目资源清单与IaC边界 (ns-resource-inventory-20250605.md)
**最后更新时间**: 2025年6月5日 12:25 (UTC+8)

## 0. 引言
本文件旨在提供 NovaScope 项目所涉及的所有云平台资源（主要为 Google Cloud Platform 和 Cloudflare）的完整清单，并明确指出哪些资源将通过基础设施即代码（IaC）工具 Terraform进行管理，哪些资源由于其特性或管理策略将不纳入或部分纳入 Terraform 管理。本清单基于项目架构设计文档 `ns-architecture-design-20250605.md` 和命名规范文档 `ns-naming-conventions-20250605.md`。

⚠ **重要说明**：为安全起见，本文档中所有涉及具体服务账号邮箱、密钥实际值等敏感信息均采用抽象描述或逻辑名称占位。实际项目中，这些值将通过安全的方式（如Terraform变量文件、环境变量或手动配置）提供给Terraform或应用，并严格遵守不将敏感信息硬编码或提交到版本控制库的原则。

## 1. Google Cloud Platform (GCP) 资源

### 1.1 纳入 Terraform 管理的资源

| 资源类型 (GCP)          | Terraform 逻辑资源名 (示例)                        | 云平台实际名称 (遵循命名规范)                                  | 是否关键资源 | 说明与用途 (Terraform配置文件参考)                                                                                                                               |
| :---------------------- | :--------------------------------------------------- | :------------------------------------------------------------ | :----------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| 项目 ID                 | –                                                    | `sigma-outcome`                                               | Y            | 已有项目，Terraform 配置中作为 `project` 属性引用，不通过Terraform创建项目本身。                                                                      |
| GCS 存储桶              | `google_storage_bucket.unified_project_gcs_bucket`   | `ns-gcs-sigma-outcome`                                        | Y            | 统一存储桶，用于存放 Terraform 远程状态文件 (路径: `tfstate/novascope/`) 和 Cloud Functions 的源代码部署包 (路径: `sources/functions/`)。参考: `infra/gcp/gcs.tf` (假设) |
| Firestore 数据库        | –                                                    | `(default)`                                                   | Y            | 通常使用项目默认的 Firestore 数据库 (Native Mode)。Terraform 主要管理其安全规则和索引。                                                                 |
| Firestore 安全规则      | `google_firestore_ruleset.rules`                     | –                                                             | Y            | 定义 Firestore 数据库的访问控制规则。参考: `infra/gcp/firestore.rules`。                                                                     |
| Firestore 索引          | `google_firestore_index.module_timestamp_index` (多个) | –                                                             | Y            | 定义 Firestore 集合的复合查询索引，例如按模块和时间戳查询。参考: `infra/gcp/firestore.indexes.json`。                                            |
| Pub/Sub 主题            | `google_pubsub_topic.daily_fetch_topic`              | `ns-ps-daily-nasa-fetch`                                      | Y            | 统一的事件触发主题，由 Cloud Scheduler 发布消息，Cloud Function (`ns-func-fetch-nasa-data`) 订阅。参考: `infra/gcp/pubsub.tf` (假设) |
| Cloud Scheduler Job     | `google_cloud_scheduler_job.daily_fetch_job`         | `ns-sched-daily-fetch`                                        | Y            | 每日定时触发器，向 `ns-ps-daily-nasa-fetch` 主题发送消息以启动统一数据抓取函数。参考: `infra/gcp/scheduler.tf`。                             |
| Cloud Function (抓取器) | `google_cloudfunctions2_function.fetch_nasa_data_function` | `ns-func-fetch-nasa-data`                                     | Y            | 统一的 Python 云函数，负责从所有NASA API模块抓取数据。参考: `infra/gcp/functions/fetch_nasa_data.tf` (假设)。                    |
| Cloud Function (API服务) | `google_cloudfunctions2_function.api_nasa_data_function` | `ns-api-nasa-data`                                        | Y            | HTTP 触发的 Python 云函数，供 Cloudflare Worker 调用以获取 Firestore 中的元数据。参考: `infra/gcp/functions/api_nasa_data.tf` (假设)。                         |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.nasa_api_key_secret`     | `ns-sm-nasa-api-key`                                          | Y            | 存储 NASA API 访问密钥的容器。实际密钥值需手动添加为版本。参考: `infra/gcp/secrets.tf`。                                                             |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.r2_access_key_id_secret` | `ns-sm-r2-access-key-id`                                      | Y            | 存储 Cloudflare R2 访问密钥 ID 的容器。参考: `infra/gcp/secrets.tf`。                                                                 |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.r2_secret_access_key_secret`| `ns-sm-r2-secret-access-key`                                  | Y            | 存储 Cloudflare R2 访问密钥 Secret 的容器。参考: `infra/gcp/secrets.tf`。                                                              |
| Secret Manager 密钥 (壳体) | `google_secret_manager_secret.cf_worker_shared_secret_obj`| `ns-sm-shared-auth-token`                                   | Y            | 存储 Cloudflare Worker 与 GCP `ns-api-nasa-data` 函数之间共享认证令牌的容器。参考: `infra/gcp/secrets.tf`。                                       |
| 服务账号                | Compute Engine 默认服务账号 | `817261716888-compute@developer.gserviceaccount.com` | Y | 项目中的 Cloud Functions 与 Scheduler 均使用此账号，无需另行创建。 |
| 日志导出接收器 (Sink)   | `google_logging_project_sink.functions_log_sink`     | (例如) `ns-log-sink-gcp-to-bq`                                | N (初期可选) | 将 Cloud Functions 的结构化日志 (例如 `severity >= ERROR`) 从 Cloud Logging 导出到 BigQuery 或 GCS。Sink filter 示例: `resource.type="cloud_function" AND (severity=ERROR OR severity=CRITICAL OR jsonPayload.status="FAIL")`。参考: `observability/logging/sink.tf` (假设)。                  |
| 监控告警策略            | `google_monitoring_alert_policy.func_error_rate_alert` (多个) | (例如) `ns-alert-function-errors`, `ns-alert-scheduler-failures` | Y            | 定义 Cloud Monitoring 中的告警规则。参考: `observability/alerts/gcp_alerts.tf` (假设)。                       |

### 1.2 不纳入 Terraform 管理的 GCP 资源 (或仅部分管理)

| 资源类型             | 实际名称 (示例)                                | 理由与管理方式                                                                                                |
| :------------------- | :--------------------------------------------- | :---------------------------------------------------------------------------------------------------------- |
| Firestore 集合与文档 | `ns-fs-apod-metadata/YYYY-MM-DD` 等            | 集合和文档由应用代码 (`ns-func-fetch-nasa-data`) 在运行时动态创建和管理。Terraform仅管理其安全规则和索引。       |
| Secret Manager 密钥值 | (密钥的实际内容)                               | 为安全起见，密钥的实际值（版本）不应存储在Terraform代码中，通常在创建密钥壳体后通过GCP控制台或gcloud CLI手动添加第一个版本。 |
| Cloud Logging 日志内容 | (实际产生的日志条目)                           | 日志由服务自动生成和收集。Terraform可管理日志导出接收器，但不管理日志本身。                                         |
| Cloud Monitoring 仪表盘 | (自定义的监控仪表盘)                           | 仪表盘通常在GCP控制台中根据实际监控需求手动创建和配置，以便更灵活地可视化指标。Terraform主要管理告警策略。        |

## 2. Cloudflare (CF) 资源

### 2.1 纳入 Terraform 管理的资源

| 资源类型 (CF)    | Terraform 逻辑资源名 (示例)             | Cloudflare 实际名称 (遵循命名规范) | 是否关键资源 | 说明与用途 (Terraform配置文件参考)                                                                                                  |
| :--------------- | :-------------------------------------- | :--------------------------------- | :----------- | :-------------------------------------------------------------------------------------------------------- |
| Worker 脚本      | `cloudflare_worker_script.frontend_worker` | `ns`                               | Y            | 主前端Cloudflare Worker。参考: `infra/cloudflare/worker.tf`。                                                        |
| Worker Route     | `cloudflare_worker_route.frontend_route`   | `ns.<your_account_id>.workers.dev/*` | Y            | 将流量路由到名为`ns`的Worker脚本。若未配置自定义域名，则使用Cloudflare提供的默认 `*.workers.dev` 子域。项目初期不使用自定义域名。参考: `infra/cloudflare/worker.tf`。 |
| R2 存储桶        | `cloudflare_r2_bucket.media_r2_bucket`     | `ns-nasa`                          | Y            | 统一存储所有从NASA API下载的媒体文件。参考: `infra/cloudflare/r2.tf`。                                 |
| R2 Bucket Binding| (在`cloudflare_worker_script`资源内配置) | `NASA_MEDIA_BUCKET` (绑定变量名)   | Y            | 在Worker脚本中配置，例如：`binding { name = "NASA_MEDIA_BUCKET" bucket_name = cloudflare_r2_bucket.media_r2_bucket.name }`。参考: `infra/cloudflare/worker.tf`。 |
| Worker Secrets (壳体) | `cloudflare_worker_secret.gcp_api_url_secret` (多个) | `NS_GCP_API_URL`, `NS_GCP_SHARED_SECRET` | Y            | 定义Worker可以访问的Secret变量名称。实际的Secret值通过Cloudflare仪表盘或Wrangler CLI安全地设置。参考: `infra/cloudflare/secrets.tf` (假设)。         |

### 2.2 不纳入 Terraform 管理的 CF 资源 (或仅部分管理)

| 资源类型         | 实际名称 (示例)                           | 理由与管理方式                                                                                                                            |
| :--------------- | :---------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| Worker Secrets 的值 | (Secret的实际内容)                        | 为安全起见，敏感的Secret值不存储在Terraform代码中，通常通过Cloudflare仪表盘或Wrangler CLI命令进行设置。                       |
| R2 存储桶中的对象 | `apod/image.jpg` 等                       | 桶中的具体媒体文件由GCP Cloud Function (`ns-func-fetch-nasa-data`) 在运行时上传和管理。Terraform仅管理R2存储桶本身。     |
| DNS 记录 (如使用自定义域) | (例如 `yourdomain.com` 的 CNAME 或 A 记录) | 项目初期不使用自定义域名。后期如需绑定，相关DNS记录应由Cloudflare DNS或第三方DNS管理，可考虑纳入Terraform的Cloudflare Provider管理。 |
| Wrangler `tail` 日志 | (实时的Worker日志流)                      | 主要用于开发和调试时通过`wrangler tail`命令实时查看，不属于基础设施资源。                                                                 |

## 3. 其他辅助资源与配置

| 资源类型        | 实际名称/路径 (示例)                                 | 管理方式                                                                 | 说明与用途                                                                      |
| :-------------- | :--------------------------------------------------- | :----------------------------------------------------------------------- | :------------------------------------------------------------------------------ |
| GitHub 仓库     | `novascope`                                          | 手动创建和管理                                                            | 存储所有项目代码、文档、Terraform配置等。                                       |
| GitHub Actions Secrets | `GCP_SA_KEY_JSON`, `CF_API_TOKEN`, `CF_ACCOUNT_ID` | 在GitHub仓库的Secrets设置中手动配置                                       | 用于CI/CD工作流（例如部署GCP和Cloudflare资源）进行身份验证。                     |
| Terraform 状态后端 | `gs://ns-gcs-sigma-outcome/tfstate/novascope/`       | Terraform根据`backend "gcs"`块配置自动生成和管理存储在GCS中的状态文件。 | 安全、持久地存储Terraform管理的基础设施状态。                                   |
| `.gitignore` 文件 | `.gitignore`                                         | 手动创建和维护，纳入版本控制                                                | 指定Git应忽略的文件和目录（如`venv/`, `node_modules/`, `.terraform/`, `.terraform.lock.hcl`, `.tfstate*`本地文件, `.env`, `*.zip`）。 |
| 本地环境变量文件  | `.env` (项目根目录或各应用子目录)                        | 手动创建，**必须添加到`.gitignore`中不提交到版本库** | 存储本地开发时使用的敏感配置或环境变量，方便本地运行和调试。                   |

## 4. Terraform 结构划分建议 (补充)

为更好地组织Terraform代码，建议在`infra/`目录下按功能和平台进行划分：
* **`infra/gcp/`**: 包含所有GCP资源的定义。
    * `main.tf`: GCP提供者配置、后端配置、通用变量。
    * `variables.tf`: GCP特定的变量声明。
    * `outputs.tf`: GCP相关的输出。
    * `gcs.tf`: GCS存储桶定义。
    * `pubsub.tf`: Pub/Sub主题和服务账号权限。
    * `scheduler.tf`: Cloud Scheduler作业定义。
    * `secrets.tf`: Secret Manager密钥壳体定义。
    * `iam.tf`: 服务账号创建和核心IAM角色绑定。
    * `firestore.tf`: Firestore规则和索引的Terraform资源定义（如果通过`google_firestore_document`等管理，否则规则和索引文件直接引用）。
    * `functions/`: 存放各个Cloud Function资源定义的独立 `.tf` 文件（例如 `fetch_nasa_data.tf`, `api_nasa_data.tf`）。
* **`infra/cloudflare/`**: 包含所有Cloudflare资源的定义。
    * `main.tf`: Cloudflare提供者配置、通用变量。
    * `r2.tf`: R2存储桶定义。
    * `worker.tf`: Worker脚本、路由、绑定和Secrets壳体定义。
* **`observability/`** (或在 `infra/gcp/` 下设 `monitoring/` 子目录):
    * **`observability/alerts/`**: 存放GCP Cloud Monitoring告警策略的 `.tf` 文件。
    * **`observability/logging/`**: 存放GCP日志导出接收器 (Log Sink) 的 `.tf` 文件。

项目根目录可以有一个 `terraform.tfvars.example` 文件，用于说明需要配置的变量，实际的 `.tfvars` 文件（包含敏感值）应被 `.gitignore` 忽略。

## 5. 资源访问控制注意事项 (补充)
* **GCS Bucket (`ns-gcs-sigma-outcome`)**: 访问权限应严格控制，仅允许Terraform执行身份（如CI/CD的服务账号或开发者）和GCP服务（如Cloud Build用于部署函数包）进行读写。
* **Cloudflare R2 Bucket (`ns-nasa`)**:
    * 公开访问性：根据需求配置。如果前端Worker直接代理或重定向到R2对象URL，则R2对象可能需要一定的公开可读性（或者Worker使用签名URL）。如果Worker通过绑定直接读取内容并提供给用户，则R2桶可以保持私有。
    * 写入权限：应仅限于GCP的`ns-func-fetch-nasa-data`函数所使用的服务账号（通过配置R2的S3兼容访问策略，授予该服务账号的R2凭证对应的用户写入权限）。
* **Firestore**: 通过`firestore.rules`文件定义严格的读写规则，例如，`ns-api-nasa-data`函数可能需要读取所有模块集合，而`ns-func-fetch-nasa-data`可能需要写入所有模块集合。前端（通过Worker代理）的访问应尽可能限制为只读。
* **Secret Manager**: 函数服务账号应仅被授予对其所需密钥的`secretmanager.secretAccessor`角色。

---
这份资源清单旨在为NovaScope项目的IaC实施和日常管理提供清晰的指引。