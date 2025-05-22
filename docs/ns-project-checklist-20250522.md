# NovaScope 项目推进清单 (ns-project-checklist-20250522.md)

**项目名称**: NovaScope
**文档版本**: 1.1 (更新以反映最新决策)
**清单截至**: 2025年5月22日 22:33 (UTC+8)

**目标**: 本清单为 NovaScope 项目的规划、开发、部署和收尾提供详细的任务列表和指引。

---

## Phase 1: 项目基础与环境设置 (已部分完成) ✅

* [x] **版本控制**:
    * [x] 创建 Git 仓库 (`novascope`)。
    * [x] 初始化项目结构 (`terraform/`, `gcp_functions_go/`, `cf_worker_ts/`, `docs/`, `scripts/`)。
        * [x] `gcp_functions_go/` 下函数目录更正为 `ns-func-fetch-apod/` 和 `ns-func-get-metadata/`。
    * [x] 创建基础 `.gitignore` 文件。
    * [x] 进行初始 Git 提交。
* [x] **本地开发环境验证 (Ubuntu Server)**:
    * [x] Git, curl, wget, unzip, nano/vim 安装并可用。
    * [x] Go (`go1.22.2` 或更高) 安装并配置好 PATH。
    * [x] Node.js (例如 `v20.x` 或更高) 和 npm 安装并可用。
    * [x] TypeScript (`tsc` - 例如 `v5.x`)全局安装。
    * [x] Wrangler CLI (例如 `v3.x` 或更高) 全局安装。
    * [x] GCP `gcloud` CLI 安装、初始化并完成认证 (`gcloud init`, `gcloud auth login`, `gcloud auth application-default login`, `gcloud config set project YOUR_PROJECT_ID`)。
    * [x] Terraform (`v1.8.x` 或更高) 安装并配置好 PATH。
* [ ] **云平台账户准备**:
    * **GCP**:
        * [ ] 确认 GCP 项目 (`novascope-xxxx`) 已创建并选定。
        * [ ] 创建或指定一个服务账号 (`sa-ns-terraform` 或类似) 供 Terraform 使用，并授予必要权限。
        * [ ] 下载服务账号的 JSON 密钥文件 (安全保存，并在 `.gitignore` 中忽略)。
        * [ ] 确保所需 API 已启用 (Cloud Functions, Cloud Scheduler, Secret Manager, Firestore, Cloud Build, IAM)。
    * **Cloudflare**:
        * [ ] 确认 Cloudflare 账户可用。
        * [ ] 创建一个 API Token，授予管理 Workers 和 R2 Bucket 的权限 (安全保存)。
* [x] **项目文档 - 初始版本**:
    * [x] `docs/ns-naming-conventions-20250522.md` - 已创建。
    * [x] `docs/ns-architecture-design-20250522.md` - 已创建。
    * [ ] (本清单) `docs/ns-project-checklist-20250522.md` - 创建并维护。
    * [ ] 创建项目根 `README.md` (初步版本)。
    * [ ] 创建各主要目录的 `README.md` (初步版本：`terraform/`, `gcp_functions_go/`, `cf_worker_ts/`)。
* [x] **Terraform 初始化 (在 `novascope/terraform/` 目录)**:
    * [x] 创建 `providers.tf` 并声明 `google` 和 `cloudflare` 提供商。
    * [x] 运行 `terraform init`。

## Phase 2: 核心基础设施定义 (Terraform - Part 1)

* [ ] **Terraform 后端配置 (`backend.tf`)**:
    * [ ] 在 GCP 中手动创建一个 GCS Bucket (例如 `ns-gcs-tfstate`) 用于存储 Terraform 远程状态。
    * [ ] 在 `terraform/` 目录下创建 `backend.tf`，配置 GCS 后端。
    * [ ] 运行 `terraform init` 迁移状态到 GCS。
* [ ] **Terraform 变量与提供商详细配置**:
    * [ ] 在 `terraform/variables.tf` 中定义 GCP 项目ID, 区域, Cloudflare 账户ID, API Token (标记为 sensitive), `ns_` 前缀等。
    * [ ] 在 `terraform/providers.tf` 中使用这些变量配置 `google` 和 `cloudflare` provider。
    * [ ] 创建 `terraform.tfvars` 文件 (并加入 `.gitignore`) 存储实际变量值。
* [ ] **GCP Secret Manager 密钥容器 (Terraform)**:
    * [ ] 定义 `google_secret_manager_secret` 资源 (仅容器，不含值)：
        * `ns-sm-nasa-api-key`
        * `ns-sm-r2-access-key-id`
        * `ns-sm-r2-secret-access-key`
        * `ns-sm-cf-worker-shared-secret`
* [ ] **Cloudflare R2 Bucket (Terraform)**:
    * [ ] 定义 `cloudflare_r2_bucket` 资源 (`ns-r2-apod-images`)。
    * [ ] (可选) 配置 R2 桶的公开访问性或准备通过 Worker/CDN 访问。
* [ ] **GCP Firestore (Terraform)**:
    * [ ] 定义 `google_project_service` 资源确保 Firestore API (`firestore.googleapis.com`) 已启用。
    * [ ] (Firestore 数据库实例通常默认存在，集合 `ns-fs-apod-metadata` 将由 Go 函数创建)。
* [ ] **GCS Bucket for Cloud Function Source Code (Terraform)**:
    * [ ] 定义 `google_storage_bucket` 资源 (`ns-gcs-func-source`) 用于存放 Go 函数的部署包。
* [ ] **运行 `terraform plan` 和 `terraform apply`** 应用以上基础资源。

## Phase 3: 后端开发 (GCP Cloud Functions - Go)

* [ ] **`ns-func-fetch-apod` 函数 (在 `gcp_functions_go/ns-func-fetch-apod/`)**:
    * [ ] 编写 Go 代码实现核心逻辑 (获取 NASA API Key/R2凭证, 调用NASA API, 下载图片, 上传图片到 R2, 元数据写入 Firestore)。
    * [ ] 编写 `go.mod`。
    * [ ] (推荐) 本地单元测试。
* [ ] **`ns-func-get-metadata` 函数 (在 `gcp_functions_go/ns-func-get-metadata/`)**:
    * [ ] 编写 Go 代码实现核心逻辑 (HTTP触发, 验证共享密钥, 从Firestore读取元数据, 返回JSON)。
    * [ ] 编写 `go.mod`。
    * [ ] (推荐) 本地单元测试。
* [ ] **(可选) 共享 Go 代码**:
    * [ ] 如果有共享逻辑，在 `gcp_functions_go/shared/` 中创建并被函数引用。

## Phase 4: 前端/边缘开发 (Cloudflare Worker - TypeScript)

* [ ] **`ns-worker-apod-frontend` Worker (在 `cf_worker_ts/`)**:
    * [ ] 使用 `wrangler init ns-apod-frontend --type typescript` 初始化项目 (如果尚未完成)。
    * [ ] 编写 TypeScript (`src/index.ts`) 代码实现核心逻辑 (接收请求, 从Secrets获取配置, 调用`ns-func-get-metadata`, 构建R2图片URL, 动态渲染HTML)。
    * [ ] 设计基础的 HTML 模板。
    * [ ] 配置 `wrangler.toml` (服务名、main入口、兼容性日期、环境变量/Secrets绑定、R2绑定)。
    * [ ] 使用 `wrangler dev` 进行本地开发和测试。

## Phase 5: 完整基础设施部署 (Terraform - Part 2)

* [ ] **GCP Cloud Functions 部署 (Terraform)**:
    * [ ] 准备 Go 函数的部署包 (手动 `zip` 或通过脚本，然后上传到 `ns-gcs-func-source`；或者让 Terraform 的 `archive_file` data source 处理打包)。
    * [ ] 定义 `google_cloudfunctions2_function` 资源 (x2)，配置运行时(Go)、入口点、源码位置 (GCS)、环境变量 (引用 Secret Manager 密钥名)、服务账号、触发器 (HTTP for `get-metadata`, Event-driven/HTTP for `Workspace-apod`)。
    * [ ] 定义相关 IAM 权限 (`google_cloudfunctions2_function_iam_member`) 允许调用。
* [ ] **GCP Cloud Scheduler 作业 (Terraform)**:
    * [ ] 定义 `google_cloud_scheduler_job` 资源 (`ns-sched-daily-apod-fetch`)，配置 cron 表达式和目标 (触发 `ns-func-fetch-apod`，例如通过 HTTP 或 Pub/Sub)。
* [ ] **Cloudflare Worker 部署 (Terraform)**:
    * [ ] (推荐) 使用 `cloudflare_worker_script` 资源部署 Worker，配置脚本内容 (从构建好的JS文件读取)、Secrets绑定、R2 Bucket绑定。
    * [ ] (可选) 定义 `cloudflare_worker_route` 将 Worker 绑定到特定路由。
* [ ] **运行 `terraform plan` 和 `terraform apply`** 部署所有应用层资源。

## Phase 6: 集成、测试与部署后操作

* [ ] **手动注入敏感密钥值**:
    * [ ] 在 GCP Secret Manager 中，为 Terraform 创建的每个密钥“容器”添加实际的敏感值。
    * [ ] 在 Cloudflare Worker 配置中（Dashboard 或 `wrangler secret put`）设置实际的 Secret 值 (如果不由 Terraform 管理值)。
* [ ] **端到端全面测试**:
    * [ ] 触发 `ns-func-fetch-apod` (手动或等待Scheduler)，验证 R2 和 Firestore 数据。
    * [ ] 访问 Worker URL，验证页面功能和图片显示。
    * [ ] 检查所有日志 (GCP Cloud Logging, Cloudflare Worker Logs)。
* [ ] **(可选) 配置自定义域名** for Cloudflare Worker。

## Phase 7: 文档、代码规范与项目收尾

* [ ] **完善所有项目文档**:
    * [ ] 更新根 `README.md` 和各组件 `README.md`。
    * [ ] 确保 `docs/` 目录下的文档 (`ns-architecture-design-20250522.md`, `ns-naming-conventions-20250522.md` 等) 内容完整和最新。
* [ ] **代码审查与清理**:
    * [ ] 检查代码注释、规范性。
    * [ ] 移除不必要的测试代码或日志。
* [ ] **Terraform 代码审查**: 确保代码清晰、模块化（如果适用）。
* [ ] **最终 Git 提交和版本标记 (例如 `v1.0.0`)**。

---

请将此清单保存到您的 `novascope/docs/ns-project-checklist-20250522.md` 文件中，并根据项目进展勾选完成的任务。祝您进展顺利！