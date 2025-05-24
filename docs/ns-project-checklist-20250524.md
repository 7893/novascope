Path: novascope/docs/ns-project-checklist-20250524.md

# NovaScope 项目开发与学习清单 - 20250524

**文档版本**: 1.2 (更新时间戳和路径，反映最新进度)
**清单截至**: 2025年5月24日 20:51 (UTC+8)

**目标**: 本清单为 NovaScope 项目的规划、开发、部署和收尾提供详细的任务列表和指引。

## I. 项目初始化与基础设置

* [x] **GCP 项目创建与配置**:
    * [x] 创建 GCP 项目 (ID: `sigma-outcome`)
    * [x] 安装并配置 `gcloud` CLI
    * [x] 启用必要的 API（通过 Terraform 管理）
* [x] **Cloudflare 账户准备**:
    * [x] 确认账户 ID
    * [x] 生成 API Token (具有 R2 读写、Worker 读写权限)
* [x] **本地开发环境设置**:
    * [x] 安装 Terraform CLI (已更新到较新版本)
    * [x] 安装 Go (已安装)
    * [x] 安装 Node.js 和 npm/yarn (已安装)
    * [x] 安装 TypeScript (`tsc`) (已更新到较新版本)
    * [x] 安装 Wrangler CLI (已安装)
* [x] **版本控制 (Git & GitHub)**:
    * [x] 初始化 Git 仓库 (`novascope`)
    * [x] 配置 `.gitignore` 文件 (已更新为最终版)
    * [x] 已将初始代码推送到远程 GitHub 仓库
* [x] **项目文档初始化**:
    * [x] 创建架构设计文档 (`ns-architecture-design-YYYYMMDD.md`) - 已更新
    * [x] 创建命名规范文档 (`ns-naming-conventions-YYYYMMDD.md`) - 已更新并加入文档自身规范
    * [x] 创建此项目清单文档 (`ns-project-checklist-YYYYMMDD.md`) - 已更新
    * [ ] (待办) 创建项目根 `README.md` (最终版)
    * [ ] (待办) 创建各主要目录的 `README.md` (最终版)

## II. Terraform 基础设施即代码 (IaC)

* [x] **Terraform 项目结构设置 (`novascope/terraform/`)**
* [x] **Provider 配置 (`providers.tf`)**:
    * [x] 配置 Google Cloud Provider (使用 `var.gcp_project_id` 等)
    * [x] 配置 Cloudflare Provider (使用 `var.cloudflare_api_token` 等)
* [x] **变量管理 (`variables.tf`, `terraform.tfvars`)**:
    * [x] 定义通用变量 (项目ID, 区域, Cloudflare凭证变量等)
    * [x] 通过 `terraform.tfvars` 安全管理 Cloudflare 凭证
* [x] **Terraform 远程后端配置 (`backend.tf`)**:
    * [x] 决定使用统一 GCS 存储桶 `ns-gcs-unified-sigma-outcome`
    * [x] Terraform 负责创建和管理此统一 GCS 桶 (通过两阶段 `init/apply` 和 `init -migrate-state` 或新状态初始化)
    * [x] `backend.tf` 已配置指向此桶及路径前缀 `tfstate/novascope/`
* [x] **核心基础设施资源定义 (`main.tf`)**:
    * [x] 定义并创建统一 GCS 存储桶 (`ns-gcs-unified-sigma-outcome`)
    * [x] 定义并创建 Cloudflare R2 存储桶 (`ns-r2-nasa-media`)
    * [x] 定义并创建 GCP Secret Manager 密钥容器 (4个)
    * [x] 定义并启用所有必需的 GCP API 服务
    * [x] 定义并创建 GCP Pub/Sub 主题 (`ns-ps-daily-apod-trigger`)
    * [x] 定义并创建 GCP Cloud Scheduler 作业 (`ns-sched-daily-apod-fetch`)
* [x] **Terraform `apply` 已成功部署上述资源。**

## III. APOD 数据处理后端 (Go Cloud Function `ns-func-fetch-apod`)

* [x] **函数项目结构 (`gcp_functions_go/ns-func-fetch-apod/`)**
* [x] **Go 代码实现 (`main.go`)**:
    * [x] 从 Secret Manager 获取 NASA API Key 和 R2 凭证
    * [x] 调用 NASA APOD API
    * [x] 下载图片/视频
    * [x] 上传媒体到 Cloudflare R2 (`ns-r2-nasa-media`)
    * [x] 将元数据写入 Firestore (集合 `ns-fs-apod-metadata`)
    * [x] 结构化日志输出
* [x] **依赖管理 (`go.mod`, `go.sum`)**:
    * [x] `go.mod` 模块路径已修正为 `github.com/7893/novascope/gcp_functions_go/ns-func-fetch-apod`
    * [x] 已添加 `secretmanager`, `firestore`, `aws-sdk-go-v2` 等依赖
* [x] **Terraform 部署配置 (`main.tf` 中相关部分)**:
    * [x] `data "archive_file"` 打包源码
    * [x] `google_storage_bucket_object` 上传源码到统一 GCS 桶
    * [x] `google_cloudfunctions2_function` 定义和部署函数 (Gen2, Go1.22, 环境变量, Pub/Sub 触发器, 服务账号 `817261716888-compute@developer.gserviceaccount.com`)
* [x] **填充 Secret Manager 中的密钥值 (手动通过 `gcloud` CLI)**
* [ ] **端到端测试 `ns-func-fetch-apod` 流程** (当前最优先的下一步！)
    * [ ] 手动触发 Cloud Scheduler 作业 `ns-sched-daily-apod-fetch`
    * [ ] 检查 Cloud Function `ns-func-fetch-apod` 的日志输出
    * [ ] 验证图片是否已上传到 R2 存储桶 `ns-r2-nasa-media` (在 `apod/` 前缀下)
    * [ ] 验证元数据是否已写入 Firestore 集合 `ns-fs-apod-metadata` (文档 ID 为日期)

## IV. 元数据 API 服务 (Go Cloud Function `ns-func-get-metadata` - 计划中)

* [ ] **函数项目结构 (`gcp_functions_go/ns-func-get-metadata/`)** (目录已创建)
* [ ] **Go 代码实现 (`main.go`)**:
    * [ ] 设计：从 Firestore 读取 APOD (及未来其他模块) 元数据
    * [ ] 设计：实现 HTTP GET 端点 (支持按日期、模块类型、分页等查询参数)
    * [ ] 设计：实现与 Cloudflare Worker 的共享密钥认证 (读取 `ns-sm-cf-worker-shared-secret`)
* [ ] **Terraform 部署配置 (`main.tf` 中新增)**
* [ ] **单元测试与集成测试**

## V. 前端与 API 网关 (Cloudflare Worker `ns` - 计划中)

* [ ] **Worker 项目结构 (`cf_worker_ts/`)**
    * [ ] 使用 `wrangler init ns --type typescript` 初始化 (如果名称最终确定为 `ns`)
* [ ] **TypeScript 代码实现 (`src/index.ts`)**:
    * [ ] 设计：处理用户 HTTP 请求
    * [ ] 设计：调用 `ns-func-get-metadata` (使用共享密钥认证)
    * [ ] 设计：通过 R2 Binding 直接提供媒体文件服务或生成签名URL
    * [ ] 设计：(可选) 渲染简单的 HTML 页面展示 APOD (及未来模块) 数据
* [ ] **`wrangler.toml` 配置** (Worker 名称 `ns`, R2 binding, secrets, env vars)
* [ ] **Terraform 部署配置 (`main.tf` 中新增 `cloudflare_worker_script`)**
* [ ] **测试 Worker 功能**

## VI. 后续与扩展 (未来计划)

* [ ] **自定义域名配置** (Cloudflare)
* [ ] **集成更多 NASA API 模块** (例如 Mars Rover Photos, EPIC)
* [ ] **CI/CD 自动化部署** (例如使用 GitHub Actions)
* [ ] **监控、告警与日志增强**
* [ ] **安全性加固** (详细的 IAM 策略、输入验证等)
* [ ] **成本优化回顾**

## VII. 已解决的关键问题与决策点 (回顾)

* [x] Terraform 后端策略：采用统一 GCS 存储桶 (`ns-gcs-unified-sigma-outcome`)，由 Terraform 自行管理。
* [x] 敏感信息管理：Terraform 变量使用 `.tfvars` (gitignored)，云端服务凭证使用 GCP Secret Manager。
* [x] IaC 范围：确认使用 Terraform 管理包括 Serverless 函数在内的所有云资源部署和配置。
* [x] 命名规范：已制定并在实践中应用。
* [x] Go 函数 `go.mod` 模块路径问题已解决。
* [x] GCP API (如 Eventarc) 启用问题已通过 Terraform 定义解决。
* [x] Cloudflare R2 存储桶 `location` 参数问题已解决。
* [x] Terraform 配置文件语法错误已修正。
* [x] Cloudflare Provider 认证问题已通过正确配置 `terraform.tfvars` 解决。
* [x] Cloud Function 运行时服务账号：选定使用 Compute Engine 默认服务账号并已为其添加所需权限。
* [x] Firestore 数据存储方式：决定为每个 NASA API 模块使用独立的顶级集合。

---