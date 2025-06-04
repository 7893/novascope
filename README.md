
# NovaScope 项目 (README.md)

**最后更新时间**: 2025年6月5日 12:30 (UTC+8)

## 1\. 项目概览

NovaScope 是一个围绕美国国家航空航天局 (NASA) 提供的众多公共开放应用程序接口 (Open APIs) 构建的探索性Serverless云平台项目。本项目旨在通过现代云计算服务，特别是 Google Cloud Platform (GCP) 和 Cloudflare (CF)，实现对NASA科学数据的自动化抓取、结构化整理、持久化存储以及用户友好的前端界面呈现。

**核心目标**：

  * 整合多个NASA开放API（计划17个，从APOD开始）。
  * 构建统一的后端数据处理与存储系统 (GCP)。
  * 提供统一的、服务端渲染(SSR)的前端展示界面 (Cloudflare Workers)。
  * 追求架构简洁、成本最优、功能完备、单人可维护。

**项目的详细架构设计、命名规范、可观测性方案、安全策略与资源清单请参考 `docs/` 目录下的文档。**

  * [项目架构设计 (`docs/ns-architecture-design-20250604.md`)](docs/ns-architecture-design-20250604.md)
  * [项目命名规范 (`docs/ns-naming-conventions-20250605.md`)](docs/ns-naming-conventions-20250605.md)
  * [可观测性实施规范 (`docs/ns-observability-spec-20250603.md`)](docs/ns-observability-spec-20250603.md)
  * [项目资源清单与 IaC 边界 (`docs/ns-resource-inventory-20250605.md`)](docs/ns-resource-inventory-20250605.md)
  * [项目开发与学习清单 (`docs/ns-project-checklist-20250605.md`)](docs/ns-project-checklist-20250605.md)
  * [安全与权限策略 (`docs/ns-security-policy-20250605.md`)](docs/ns-security-policy-20250605.md)

## 2\. 技术栈

  * **云平台**:
      * Google Cloud Platform (GCP)
      * Cloudflare (CF)
  * **后端**:
      * GCP Cloud Functions (Python 3.11+)
      * GCP Pub/Sub
      * GCP Cloud Scheduler
      * GCP Firestore (Native Mode)
      * GCP Secret Manager
      * GCP Cloud Storage (GCS)
  * **前端/边缘**:
      * Cloudflare Workers (TypeScript)
      * Cloudflare R2 Storage
      * Cloudflare CDN
  * **基础设施即代码 (IaC)**:
      * Terraform
  * **代码库管理**:
      * Git / GitHub
      * Monorepo (可能使用 Turborepo 进行优化管理)
  * **核心编程语言**:
      * Python (GCP后端)
      * TypeScript (Cloudflare Worker前端)

## 3\. 项目结构快速指引

本项目采用 Monorepo 结构，主要目录职责如下：

  * **`novascope/`** (项目根目录)
      * **`apps/`**: 存放所有独立部署的应用服务。
          * `apps/frontend/`: Cloudflare Worker (TypeScript) 前端应用。
          * `apps/gcp-py-fetch-nasa-data/`: GCP Cloud Function (Python) 统一数据抓取器。
          * `apps/gcp-py-api-nasa-data/`: GCP Cloud Function (Python) 元数据API服务。
          * (未来其他各NASA API模块的GCP Python函数也将在此创建，例如 `apps/gcp-py-mars-rover-photos/`)
      * **`packages/`**: 存放可在多个应用间共享的可复用代码包。
          * `packages/shared-utils-py/`: Python 通用工具库 (例如 `secrets.py`)。
      * **`infra/`**: 存放所有基础设施即代码 (Terraform) 配置。
          * `infra/gcp/`: GCP 平台相关资源的Terraform配置。
          * `infra/cloudflare/`: Cloudflare 平台相关资源的Terraform配置。
      * **`docs/`**: 存放所有项目详细设计与规范文档。
      * **`scripts/`**: 存放各种辅助脚本（如手动部署脚本、工具脚本等）。
      * **`tests/`**: 存放各类测试代码。
      * **`.github/workflows/`**: 存放CI/CD工作流配置文件。

详细的命名规范请参考 [`docs/ns-naming-conventions-20250605.md`](docs/ns-naming-conventions-20250605.md)。

## 4\. 本地开发环境设置

### 4.1 必要工具与版本

  * **Git**: 版本控制系统。
  * **Python**: 3.11 或更高版本 (用于GCP Functions开发)。
  * **Node.js**: LTS 版本 (例如 18.x 或 20.x，用于Cloudflare Worker开发和构建工具)。
  * **pnpm** (推荐) 或 **npm/yarn**: Node.js包管理工具。
  * **Terraform**: 最新稳定版本。
  * **Google Cloud SDK (`gcloud` CLI)**: 最新版本，并已通过 `gcloud auth login` 和 `gcloud auth application-default login` 配置好认证。
  * **Wrangler CLI**: 最新版本 (Cloudflare Worker开发工具)，并已通过 `wrangler login` 配置好认证。
  * **文本编辑器/IDE**: 例如 VS Code。
  * **(可选) Docker**: 如果未来某些服务需要容器化，或本地模拟某些环境。

### 4.2 环境变量配置

项目根目录以及各个`apps/`子项目目录下可能需要 `.env` 文件来管理本地开发时的环境变量（例如API密钥、本地服务端口等）。`.env` 文件**必须**被添加到 `.gitignore` 中，不应提交到版本库。

项目根目录可以提供一个 `.env.example` 文件作为模板，说明需要哪些环境变量。

### 4.3 Python 函数开发 (例如 `apps/gcp-py-fetch-nasa-data/`)

1.  进入目标函数目录：`cd apps/gcp-py-fetch-nasa-data/`
2.  创建并激活Python虚拟环境：
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
3.  安装依赖：
    ```bash
    pip install -r requirements.txt
    # 如果引用了本地共享库，可能需要类似 pip install -e ../../packages/shared-utils-py
    ```
4.  在激活的虚拟环境中进行开发和调试。

### 4.4 Cloudflare Worker 开发 (`apps/frontend/`)

1.  进入Worker项目目录：`cd apps/frontend/`
2.  安装依赖：
    ```bash
    pnpm install # 或 npm install / yarn install
    ```
3.  根据 `wrangler.toml` 配置本地开发所需的环境变量或Secrets（通常通过 `.dev.vars` 文件或Wrangler命令设置）。
4.  使用 `wrangler dev` 启动本地开发服务器。

## 5\. 运行与调试指南

  * **GCP Python Functions**:
      * 可以使用 Google Cloud Functions Framework for Python 在本地运行和测试HTTP触发的函数。
      * 对于Pub/Sub触发的函数，可以在本地编写脚本来模拟Pub/Sub消息并调用函数入口点进行测试。
      * 结构化日志将输出到控制台。
  * **Cloudflare Worker**:
      * 使用 `wrangler dev --local` (或移除 `--local` 以连接到Cloudflare的开发网络) 启动本地开发服务器。
      * Worker的日志将输出到 `wrangler dev` 的控制台。
      * 可以使用浏览器或Postman等工具访问本地运行的Worker进行调试。

详细的日志、监控和告警策略请参考 [`docs/ns-observability-spec-20250603.md`](docs/ns-observability-spec-20250603.md)。

## 6\. 构建与部署

### 6.1 构建

  * **GCP Python Functions**: Python是解释型语言，通常不需要显式的“构建”步骤，除非您使用了如Protocol Buffers等需要预编译的工具。主要的准备工作是确保 `requirements.txt` 是最新的。
  * **Cloudflare Worker (TypeScript)**:
    ```bash
    cd apps/frontend/
    pnpm run build # 或 npm run build / yarn build (根据package.json中的脚本)
    ```
    这通常会调用 `tsc` 将TypeScript编译为JavaScript，并由Wrangler进行打包。

### 6.2 部署

项目的基础设施（GCP和Cloudflare的核心资源）将通过 **Terraform** 进行统一管理和部署。

  * 进入 `infra/` 目录或其子目录（如 `infra/gcp/`, `infra/cloudflare/`）。
  * 在 `infra/gcp/terraform.tfvars` 中配置 `gcp_project_id` 等项目变量。
  * 执行 `terraform init` 初始化。
  * 执行 `terraform plan` 预览变更。
  * 执行 `terraform apply` 应用变更。

对于应用的**代码部署**：

  * **GCP Cloud Functions**: Terraform在创建函数资源时会引用打包好的源代码（通常是一个zip文件，存放在GCS中）。这个zip包可以通过CI/CD流程自动构建和上传，或者在初期通过手动打包上传。`gcp-build`脚本（如果存在于`package.json`中，虽然这是Node.js的约定，Python函数通常直接打包源码和`requirements.txt`）会在云端构建时执行。
  * **Cloudflare Worker**: 通常使用 `wrangler deploy` 命令进行部署，或者通过Terraform的`cloudflare_worker_script`资源进行管理。

CI/CD流水线（例如使用GitHub Actions）是项目未来的目标，用于自动化测试、构建和部署流程。

## 7\. 核心脚本说明

  * `scripts/deploy-manual.sh` (示例): 可能包含一系列手动执行部署步骤的命令，用于初期快速验证或没有CI/CD时的手动操作。
  * `scripts/dev-debug-fetch.sh` (示例): 可能用于在本地触发模拟数据抓取流程的脚本，方便调试`gcp-py-fetch-nasa-data`函数。

(未来可以根据实际添加的脚本在此处进行说明)

## 8\. 贡献指南 (远期)

当项目发展到需要多人协作时，将在此处定义代码风格、分支策略（例如GitFlow）、Pull Request流程、Code Review要求等。

## 9\. 许可证

(在此处声明项目的开源许可证，例如 MIT, Apache 2.0 等)

