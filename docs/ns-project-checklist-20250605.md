好的，我们已经完成了项目架构设计文档、命名规范文档、可观测性实施规范文档以及资源清单与IaC边界文档的更新。

根据我们之前精简后的核心项目文档列表，下一个应该输出的文档是 **项目开发与学习清单/任务追踪文档**。

我将基于您最初提供的 `ns-project-checklist-20250524.md` 的内容和结构，并结合我们最近所有的架构调整、技术选型变更（特别是后端从Go迁移到Python，并采用统一抓取函数的设计）以及新的目录结构，来生成一份更新的清单。

这份更新后的清单将反映项目当前的实际状态和接下来的主要任务。

---

Path: novascope/docs/ns-project-checklist-20250605.md
# NovaScope 项目开发与学习清单 (ns-project-checklist-20250605.md)
**最后更新时间**: 2025年6月5日 11:55 (UTC+8)

**目标**: 本清单为 NovaScope 项目的规划、开发、部署和学习提供详细的任务列表和指引，并反映截至文档更新日期的项目状态和后续计划。

---

## I. 项目初始化与基础设置 (大部分已在前期完成或调整)

* [x] **GCP 项目创建与配置**:
    * [x] 创建 GCP 项目 (ID: `sigma-outcome`)
    * [x] 安装并配置 `gcloud` CLI
    * [ ] 启用必要的API（将通过Terraform管理）
* [x] **Cloudflare 账户准备**:
    * [x] 确认账户 ID
    * [x] 生成 API Token (具有R2读写、Worker读写权限)
* [x] **本地开发环境设置**:
    * [x] 安装 Terraform CLI
    * [x] 安装 Python (用于GCP Functions开发)
    * [x] 安装 Node.js 和 npm/pnpm (用于Cloudflare Worker开发)
    * [x] 安装 TypeScript (`tsc`)
    * [x] 安装 Wrangler CLI
* [x] **版本控制 (Git & GitHub)**:
    * [x] 初始化 Git 仓库 (`novascope`)
    * [x] 配置 `.gitignore` 文件 (已包含 `venv/`, `node_modules/`, `dist/`, `.env` 等)
    * [x] 已将初始代码和文档推送到远程 GitHub 仓库
* [x] **项目文档初始化与更新**:
    * [x] 创建/更新架构设计文档 (`docs/ns-architecture-design-YYYYMMDD.md`)
    * [x] 创建/更新命名规范文档 (`docs/ns-naming-conventions-YYYYMMDD.md`)
    * [x] 创建/更新可观测性规范文档 (`docs/ns-observability-spec-YYYYMMDD.md`)
    * [x] 创建/更新资源清单与IaC边界文档 (`docs/ns-resource-inventory-YYYYMMDD.md`)
    * [x] 创建/更新此项目清单文档 (`docs/ns-project-checklist-YYYYMMDD.md`)
    * [ ] (待办) 编写项目根 `README.md`

## II. 基础设施即代码 (IaC) - Terraform

* [x] **项目目录结构调整**：
    * [x] 创建 `infra/gcp/` 和 `infra/cloudflare/` 目录。
* [ ] **Terraform Provider 配置**:
    * [ ] 配置 Google Cloud Provider。
    * [ ] 配置 Cloudflare Provider。
* [ ] **变量管理 (`variables.tf`, `terraform.tfvars`)**:
    * [ ] 定义通用变量 (项目ID, 区域, Cloudflare凭证变量等)。
    * [ ] 安全管理敏感凭证 (例如通过环境变量注入到 `terraform.tfvars` 或使用其他安全机制)。
* [ ] **Terraform 远程后端配置 (`backend.tf`)**:
    * [ ] 配置GCS存储桶 `ns-gcs-sigma-outcome` 作为远程后端，路径 `tfstate/novascope/`。
* [ ] **核心共享基础资源定义与部署 (GCP)**:
    * [ ] 定义并创建 GCS 存储桶 (`ns-gcs-sigma-outcome`)。
    * [ ] 定义并创建 Secret Manager 密钥“壳体” (4个核心密钥：`ns-nasa-api-key`, `ns-r2-access-key-id`, `ns-r2-secret-access-key`, `ns-cf-worker-shared-secret`)。
    * [ ] 定义并创建 Pub/Sub 主题 (`ns-ps-daily-nasa-fetch`)。
    * [ ] 定义并创建 Cloud Scheduler 作业 (`ns-sched-daily-fetch`)，配置其触发 Pub/Sub。
    * [ ] 使用项目的 Compute Engine 默认服务账号 `817261716888-compute@developer.gserviceaccount.com`。
    * [ ] 定义并应用Firestore安全规则 (`infra/gcp/firestore.rules`)。
    * [ ] 定义并应用Firestore初始索引 (`infra/gcp/firestore.indexes.json`) (可选，根据查询需求)。
* [ ] **核心共享基础资源定义与部署 (Cloudflare)**:
    * [ ] 定义并创建 R2 存储桶 (`ns-nasa`)。
* [ ] **可观测性基础资源定义与部署 (GCP - Terraform)**:
    * [ ] 定义日志导出接收器 (Log Sink) (可选)。
    * [ ] 定义基础的监控告警策略 (例如在 `infra/gcp/monitoring.tf` 中定义针对函数失败和调度失败的告警)。
* [ ] **完成上述基础资源的 `terraform apply` 并验证。**

## III. 后端开发：统一数据抓取函数 (`apps/gcp-py-fetch-nasa-data/`)

* [x] **项目结构初始化**：
    * [x] 创建 `apps/gcp-py-fetch-nasa-data/` 目录。
    * [x] 创建 `main.py` 和 `requirements.txt`。
    * [x] 初始化并激活 Python 虚拟环境 (`venv/`)。
* [ ] **共享工具库开发 (`packages/shared-utils-py/`)**:
    * [x] 创建 `packages/shared-utils-py/shared_utils/secrets.py` 文件。
    * [ ] 实现 `get_secret` 函数用于从GCP Secret Manager获取密钥。
    * [ ] (可选) 实现通用的HTTP请求客户端、日志封装、数据处理工具等。
    * [ ] 配置 `pyproject.toml` 使其可被本地引用。
* [ ] **`requirements.txt` 配置**:
    * [ ] 添加必要的Python库 (如 `google-cloud-firestore`, `google-cloud-secretmanager`, `google-cloud-pubsub`, `requests`, `python-json-logger` 或 `structlog`, `boto3` for R2)。
    * [ ] 添加对本地共享库的引用 (例如 `-e ../../packages/shared-utils-py`)。
* [ ] **主函数逻辑 (`main.py`)**:
    * [ ] 实现函数入口 (响应Pub/Sub事件)。
    * [ ] 实现模块注册表机制。
    * [ ] 实现基于配置的模块调度逻辑（判断哪些模块今日需要抓取）。
    * [ ] 实现调用各模块独立抓取逻辑的框架。
    * [ ] 实现统一的结构化日志（遵循可观测性规范）。
    * [ ] 实现健壮的错误处理和模块间隔离。
* [ ] **APOD模块实现 (`modules/apod.py`) - 作为第一个模块**:
    * [ ] 实现APOD API的数据抓取逻辑 (每日型策略)。
    * [ ] 实现媒体文件下载并上传到R2 (`apod/` 目录下，使用原始文件名)。
    * [ ] 实现元数据写入Firestore (`ns-fs-apod-metadata` 集合)。
    * [ ] 实现独立的单元测试。
* [ ] **Terraform部署配置 (`infra/gcp/functions/fetch_nasa_data.tf` 或类似文件)**:
    * [ ] 定义 `google_cloudfunctions2_function` 资源 `ns-func-fetch-nasa-data`。
    * [ ] 配置正确的Python运行时、入口点。
    * [ ] 配置环境变量。
    * [ ] 配置Pub/Sub触发器 (`ns-ps-daily-nasa-fetch`)。
    * [ ] 使用默认服务账号 (无需额外配置)。
    * [ ] 配置源代码打包和上传 (引用GCS对象)。
* [ ] **端到端测试 `ns-func-fetch-nasa-data` (APOD模块)**：
    * [ ] 手动触发Cloud Scheduler (或直接向Pub/Sub发消息)。
    * [ ] 检查Cloud Function日志输出。
    * [ ] 验证图片是否已上传到R2的 `apod/` 目录下。
    * [ ] 验证元数据是否已写入Firestore的 `ns-fs-apod-metadata` 集合。
* [ ] **逐步实现其他16个模块的抓取逻辑 (`modules/*.py`)**:
    * [ ] 根据其特定策略（分页型、事件型、慢速型）实现抓取、存储逻辑。
    * [ ] 编写单元测试。

## IV. 后端开发：元数据API服务 (`apps/gcp-py-api-nasa-data/`)

* [ ] **项目结构初始化**：
    * [ ] 创建 `apps/gcp-py-api-nasa-data/` 目录。
    * [ ] 创建 `main.py` 和 `requirements.txt`。
    * [ ] 初始化并激活 Python 虚拟环境。
* [ ] **`requirements.txt` 配置**:
    * [ ] 添加必要的Python库 (如 `google-cloud-firestore`, `Flask` 或 `FastAPI` (如果不用GCP内置的HTTP框架)，`google-cloud-secretmanager` (用于获取共享密钥))。
    * [ ] 添加对本地共享库的引用。
* [ ] **主函数逻辑 (`main.py`)**:
    * [ ] 实现HTTP触发的函数入口。
    * [ ] 实现基于共享密钥的请求认证。
    * [ ] 实现根据请求参数（如模块名、日期、分页等）从Firestore查询元数据的逻辑。
    * [ ] 实现结构化日志。
    * [ ] 返回JSON格式的响应。
* [ ] **Terraform部署配置 (`infra/gcp/functions/api_nasa_data.tf` 或类似文件)**:
    * [ ] 定义 `google_cloudfunctions2_function` 资源 `ns-api-nasa-data`。
    * [ ] 配置正确的Python运行时、HTTP触发器、入口点。
    * [ ] 配置环境变量（包括共享密钥的Secret ID）。
    * [ ] 使用默认服务账号 (无需额外配置)。
* [ ] **集成测试**:
    * [ ] 模拟Cloudflare Worker调用此API并验证响应。

## V. 前端开发：Cloudflare Worker (`apps/frontend/`)

* [ ] **项目结构初始化 (使用Wrangler)**：
    * [ ] 创建 `apps/frontend/` 目录并初始化TypeScript Worker项目。
    * [ ] 配置 `wrangler.toml` (包括R2绑定、Worker Secrets名称等)。
* [ ] **核心逻辑实现 (`src/index.ts`)**:
    * [ ] 实现路由逻辑，处理不同页面请求。
    * [ ] 实现服务端渲染 (SSR) 逻辑，动态生成HTML。
    * [ ] 实现调用GCP后端API (`ns-api-nasa-data`) 获取元数据的逻辑 (使用共享密钥)。
    * [ ] 整合元数据和R2媒体链接到渲染的HTML中。
    * [ ] 实现结构化日志（遵循可观测性规范，包含Trace ID）。
    * [ ] 实现Trace ID的生成与向下游传递。
* [ ] **Terraform部署配置 (`infra/cloudflare/worker.tf`, `r2.tf` 等)**:
    * [ ] 定义 `cloudflare_worker_script` 资源 `ns`。
    * [ ] 定义 `cloudflare_r2_bucket` 资源 `ns-nasa`。
    * [ ] 定义必要的Worker Route。
    * [ ] 配置Worker Secrets“壳体”。
    * [ ] 配置R2 Bucket绑定。
* [ ] **端到端测试**:
    * [ ] 部署Worker后，通过浏览器访问，验证页面是否能正确展示APOD等模块的数据。

## VI. 可观测性实施

* [ ] **结构化日志**:
    * [x] 确立GCP Functions (Python) 和 Cloudflare Worker (TypeScript) 的结构化日志JSON格式规范。
    * [ ] 在所有函数和Worker中全面实施。
* [ ] **告警策略**:
    * [x] 确立针对抓取函数失败、调度异常的告警策略。
    * [ ] 通过Terraform在Cloud Monitoring中实现这些告警策略。
* [ ] **链路追踪**:
    * [x] 确立Trace ID生成和传递机制。
    * [ ] 在Worker和GCP Functions中实现Trace ID的记录与传递。
* [ ] **日志导出 (可选)**:
    * [ ] 配置Log Sink将GCP日志导出到BigQuery或GCS。

## VII. CI/CD 自动化 (远期)

* [ ] 设计CI/CD流水线 (例如使用GitHub Actions)。
* [ ] 实现自动化测试。
* [ ] 实现自动化构建和部署到GCP及Cloudflare。

## VIII. 持续优化与迭代

* [ ] 根据实际运行情况优化各模块的抓取策略。
* [ ] 监控并优化资源使用和成本。
* [ ] 根据用户反馈（如果有）或新的学习目标，添加对更多NASA API模块的支持。

---