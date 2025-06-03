好的，这份 `ns-security-policy-20250605.md` 的大纲非常出色！它系统性地覆盖了 NovaScope 项目在安全与权限策略方面的核心内容，确保项目“运行安全、部署安全、数据不泄露”。

我们就按照这个大纲，并严格遵循您对文档编制的所有要求（文件名、路径、标题包含文件名、更新时间戳、内容详尽准确、完整输出、纯文字描述），来输出这份**安全与权限策略规范文档**。

---

Path: novascope/docs/ns-security-policy-20250605.md
# NovaScope 项目安全与权限策略规范 (ns-security-policy-20250605.md)
**最后更新时间**: 2025年6月5日 12:35 (UTC+8)

## 0. 引言
本文档旨在为NovaScope项目定义和规范所有涉及账号权限管理、Secrets（密钥、令牌等敏感信息）管理、日志数据隐私保护、基础设施访问控制等关键安全相关内容。其核心目的是确保项目在开发、部署和运行全生命周期中的安全性，防止数据泄露、未授权访问和潜在的安全风险。

本文档适用于所有参与NovaScope项目的开发者、部署者和运维人员。所有安全实践都必须严格遵循两大基本准则：**“最小权限原则”**（Principle of Least Privilege），即仅授予主体（用户、服务账号、应用等）执行其预定任务所必需的最小权限集；以及**“密钥绝不硬编码或进入代码仓库”**的基本安全红线。

本文档将与项目架构设计文档 (`ns-architecture-design-20250605.md`)、命名规范文档 (`ns-naming-conventions-20250605.md`)、可观测性实施规范文档 (`ns-observability-spec-20250605.md`) 以及资源清单与IaC边界文档 (`ns-resource-inventory-20250605.md`) 协同工作，共同构成项目的核心规范体系。

## 1. 服务账号管理策略
本节详细说明在Google Cloud Platform (GCP) 和 Cloudflare 中所使用的服务账号（或等效身份）的创建、权限配置和管理规范。

* **GCP 服务账号**:
    * **使用原则**: 对于GCP Cloud Functions（如 `ns-func-fetch-nasa-data`, `ns-api-nasa-data`）和Cloud Scheduler等需要访问其他GCP服务的组件，应使用专用的、具有最小权限的GCP服务账号。**推荐使用项目中已有的、通过Terraform变量（例如 `var.gcp_functions_service_account_email`）引用的预配置服务账号，本文档中不直接列出具体服务账号的ID或邮箱地址。**
    * **最小权限分配**:
        * Cloud Functions专用服务账号**仅应被授予**其执行任务所必需的角色。例如：
            * 访问GCP Secret Manager中特定密钥版本的权限 (`roles/secretmanager.secretAccessor`)。
            * 读写GCP Firestore特定数据库/集合的权限 (`roles/datastore.user` 或更细粒度的自定义角色)。
            * 向GCP Pub/Sub特定主题发布或订阅消息的权限（例如，`ns-func-fetch-nasa-data` 需要 `roles/pubsub.subscriber` 来订阅 `ns-ps-daily-nasa-fetch` 主题）。
            * 写入GCP Cloud Logging的权限（通常默认拥有）。
        * Cloud Scheduler服务账号（或其使用的身份）仅需拥有向目标Pub/Sub主题 (`ns-ps-daily-nasa-fetch`) 发布消息的权限 (`roles/pubsub.publisher`)，不应授予任何对Firestore、Secret Manager或R2的多余权限。
    * **Terraform中引用**: 在Terraform配置中，应通过变量或数据源（data source）来引用服务账号的邮箱地址，而不是硬编码。IAM绑定（`google_project_iam_member` 或 `google_cloudfunctions2_function_iam_member` 等资源）应精确地将所需角色授予此服务账号。
    * **禁止事项**: **严禁创建或使用拥有Owner或Editor等过于宽泛权限的通用服务账号**来运行Cloud Functions或其他自动化任务。

* **Cloudflare (针对API Token)**:
    * 当通过Terraform或Wrangler CLI管理Cloudflare资源时，所使用的API Token应遵循最小权限原则。例如，如果一个Token仅用于管理R2和Worker，则不应授予其管理DNS或账户设置的权限。
    * API Token的实际值应作为敏感信息处理，不应硬编码在Terraform配置中，而是通过环境变量或安全的变量传递机制提供给Terraform执行环境。

## 2. Secret 管理策略
所有项目所需的密钥、API Key、访问令牌、共享密码等敏感凭证，都必须通过专门的密钥管理服务进行安全存储和访问控制。

* **GCP Secret Manager**:
    * **用途**: 作为后端所有敏感凭证的统一、安全存储位置。这包括：
        * 访问NASA各API所需的API密钥（存储在名为 `ns-nasa-api-key` 的Secret中）。
        * 访问Cloudflare R2所需的Access Key ID（存储在名为 `ns-r2-access-key-id` 的Secret中）。
        * 访问Cloudflare R2所需的Secret Access Key（存储在名为 `ns-r2-secret-access-key` 的Secret中）。
        * 用于Cloudflare Worker与GCP `ns-api-nasa-data` 函数之间认证的共享密钥（存储在名为 `ns-cf-worker-shared-secret` 的Secret中）。
    * **管理**: Secret的“壳体”（即Secret ID）将由Terraform创建和管理。但**实际的密钥值（版本）必须通过GCP控制台或`gcloud` CLI等安全方式手动添加为其第一个版本**，绝不能包含在Terraform代码或任何提交到版本库的文件中。
    * **访问**: GCP Cloud Functions将通过其专用的服务账号，并被授予对特定Secret的`secretmanager.secretAccessor`角色，来在运行时按需读取密钥值。

* **Cloudflare Worker Secrets**:
    * **用途**: 用于存储Cloudflare Worker (`ns`) 在边缘运行时所需的敏感配置。这包括：
        * GCP `ns-api-nasa-data` 函数的访问端点URL (例如，环境变量名为 `NS_GCP_API_URL`)。
        * 从GCP Secret Manager中获取并配置到Worker环境的、用于与GCP `ns-api-nasa-data` 函数通信的**共享密钥的值** (例如，环境变量名为 `NS_GCP_SHARED_SECRET`)。
        * Cloudflare R2存储桶的名称（如果Worker需要直接引用，例如 `NS_R2_BUCKET_NAME`）。
    * **管理**: Worker Secrets的名称可以在Terraform的`cloudflare_worker_script`资源中定义（作为期望的环境变量键），但其实际的值必须通过Cloudflare仪表盘或Wrangler CLI命令（例如 `wrangler secret put KEY_NAME`）安全地设置，绝不能硬编码或提交到版本库。

* **代码仓库与本地环境**:
    * **严禁**将任何实际的密钥、令牌或密码硬编码在源代码（Python, TypeScript, Terraform HCL等）中。
    * 本地开发时，如果需要使用敏感凭证，应通过本地的 `.env` 文件进行配置。该 `.env` 文件**必须**被添加到项目根目录的 `.gitignore` 文件中，以确保不会被意外提交到版本控制系统。
    * 所有函数和应用都应优先从环境变量或配置的Secrets服务中读取敏感信息。

* **统一加载方式**:
    * 对于GCP Python函数，所有从GCP Secret Manager加载密钥的逻辑，都应通过项目共享库 `packages/shared-utils-py/shared_utils/secrets.py` 中提供的统一函数（例如 `get_secret(secret_id)`）来完成。这确保了密钥加载方式的一致性、安全性，并便于未来统一进行审计、更新或引入mock机制。

## 3. Terraform 状态文件与权限管理
Terraform状态文件（`.tfstate`）包含了已部署基础设施的详细快照，是项目的核心敏感资产之一，必须确保其存储和访问的安全性。

* **存储位置**:
    * Terraform远程状态将统一存储在GCP Cloud Storage存储桶 `ns-gcs-sigma-outcome` 中的特定路径下，例如 `tfstate/novascope/`。

* **权限配置建议 (针对GCS状态存储桶)**:
    * **CI/CD服务账号**: 如果项目使用CI/CD流水线（例如GitHub Actions）来执行Terraform操作，则应为该CI/CD流程配置专用的GCP服务账号，并仅授予该服务账号对此GCS存储桶中状态文件路径的读写权限（例如 `roles/storage.objectAdmin` 作用于特定前缀）。
    * **开发者账户**: 对于需要在本地手动执行Terraform的开发者，应通过GCP IAM策略，显式地授予其个人GCP账户或所属的开发者用户组对状态文件路径的必要读写权限。**不应允许匿名或过于宽泛的公共账户访问**。
    * **禁止公开访问**: **严禁将存储Terraform状态文件的GCS存储桶或其任何部分配置为允许公共互联网匿名浏览或读取**。应确保存储桶的访问控制策略是私有的。
    * **版本控制**: 建议启用GCS存储桶的对象版本控制功能，以便在状态文件意外损坏或错误修改时能够进行恢复。
    * **状态锁定**: Terraform在操作时会自动使用GCS提供的机制进行状态锁定，以防止并发修改导致状态损坏。

## 4. 日志脱敏与日志访问权限
日志是排查问题和监控系统状态的重要工具，但同时也可能包含敏感信息。必须采取措施确保日志数据的隐私性和访问安全。

* **日志内容安全**:
    * **禁止输出敏感信息**: 在所有应用（GCP Functions, Cloudflare Worker）的结构化日志中，**严禁直接打印或记录**以下类型的敏感信息：
        * 完整的API密钥（例如NASA API Key）。
        * Cloudflare R2的Access Key ID和Secret Access Key。
        * 共享认证令牌的实际值。
        * 数据库连接字符串中的密码（如果适用）。
        * 从用户请求中获取的、可能包含个人身份信息(PII)的原始数据，如完整的用户IP地址、精确的地理位置信息、用户Cookie中的会话令牌、HTTP Authorization头中的原始Token等。
    * **脱敏建议**：
        * **IP地址**: 如果需要记录IP地址用于分析，应进行部分匿名化处理，例如仅记录子网部分（如 `192.168.1.xxx`）或对IPv6地址进行适当截断或哈希。
        * **用户标识符**: 如果需要追踪特定用户的请求链用于调试，应使用内部生成的、与用户真实身份解耦的匿名化用户标识（例如，对原始用户标识符进行哈希处理后的值）。
        * **错误信息**: 在记录第三方API返回的错误信息时，要注意检查其中是否可能包含请求参数中意外回显的敏感数据。
    * 共享的日志记录模块 (`logger.py`, `logger.ts`) 中应考虑内置或提供易于使用的敏感信息屏蔽或替换功能。

* **Cloud Logging访问权限建议**:
    * **写入权限**: GCP Cloud Functions使用的服务账号通常默认拥有向Cloud Logging写入其自身日志的权限，这是正常的。
    * **读取权限**: 对于需要查看日志进行问题排查或监控分析的开发者或运维人员，应遵循最小权限原则。通常，仅授予他们对特定项目或特定日志存储分区（Log Bucket）的**只读查看权限**（例如 `roles/logging.viewer`）。
    * **配置权限**: 对于需要配置日志导出接收器（Log Sink）或日志分析工具的更高权限角色（例如 `roles/logging.configWriter` 或 `roles/logging.admin`），应严格限制其授予范围。

## 5. Git 仓库与本地开发环境安全约定
确保版本控制系统（Git）中不包含任何敏感信息，并指导开发者如何在本地安全地处理项目配置。

* **`.gitignore` 文件强制忽略**:
    * 项目根目录下的 `.gitignore` 文件必须包含并强制忽略所有可能包含敏感信息或不需要版本控制的文件和目录。这至少应包括：
        * 本地环境变量文件：`.env` (以及任何变体如 `.env.local`, `.dev.vars` 等)
        * 包含密钥的JSON文件：`*.json`（特别是服务账号密钥文件，应特别注意命名模式以确保被忽略，例如 `gcp-sa-*.json`, `secrets/*.json`）
        * Terraform本地状态文件：`.tfstate`, `.tfstate.backup`
        * Terraform本地配置文件缓存：`.terraform/`
        * Terraform锁文件：`.terraform.lock.hcl` (通常建议提交此文件，但如果其中可能泄露本地路径等信息且团队策略不同，则需评估)
        * Python虚拟环境目录：`venv/`
        * Node.js依赖目录：`node_modules/`
        * 编译产物目录：`dist/`
        * IDE和编辑器特定配置文件：如 `.vscode/`, `.idea/`
* **禁止提交敏感文件**:
    * **严禁将任何包含实际密钥、密码、API令牌等敏感信息的文件提交到Git仓库**，即使是私有仓库。
    * 在编写代码或配置文件时，所有敏感值都应通过引用环境变量、Secret Manager中的密钥名或Cloudflare Worker Secrets中的变量名来间接获取。
* **GitHub Actions Secrets (CI/CD)**:
    * 如果项目使用GitHub Actions进行自动化部署，所有需要的敏感凭证（如用于访问GCP的服务账号密钥JSON内容、Cloudflare API Token、Cloudflare Account ID等）必须存储为GitHub仓库的加密Secrets。
    * CI/CD工作流配置文件 (`.github/workflows/*.yml`) 中应通过 `${{ secrets.YOUR_SECRET_NAME }}` 的方式引用这些Secrets，绝不能在工作流文件中明文写入。
    * 为GitHub Actions配置的GCP服务账号密钥或Cloudflare API Token，其本身也应遵循最小权限原则，仅授予执行CI/CD任务所必需的权限。
* **本地开发安全**:
    * 开发者在本地配置 `.env` 文件或其他包含敏感信息的文件时，必须确保这些文件位于 `.gitignore` 的规则覆盖范围内。
    * 共享项目时，应提供 `.env.example` 或类似的模板文件，说明需要哪些环境变量，但不包含实际值。

## 6. 未来安全增强建议 (可选)
随着项目的发展、团队规模的扩大或处理的数据敏感性提高，可以考虑逐步引入以下安全增强措施：

* **密钥轮换 (Secret Rotation)**:
    * 为存储在GCP Secret Manager中的关键凭证（如NASA API Key, R2访问密钥, 共享认证令牌）制定并实施定期的自动或半自动轮换策略。

* **使用OpenID Connect (OIDC) 授权GitHub Actions访问GCP**:
    * 替代将GCP服务账号密钥JSON作为GitHub Secret上传的方式，配置GitHub Actions与GCP之间的Workload Identity Federation (基于OIDC)。这允许GitHub Actions工作流直接模拟一个GCP服务账号身份来访问GCP资源，无需管理和轮换长期的服务账号密钥，更为安全和便捷。

* **增强Web应用防火墙 (WAF) 和安全扫描**:
    * 如果Cloudflare Worker (`ns`) 暴露的端点未来处理更敏感的请求或面临更复杂的威胁，可以考虑利用Cloudflare提供的WAF功能配置更严格的安全规则。
    * 定期使用GCP Security Command Center对GCP资源进行安全状况评估和漏洞扫描。
    * 对于Cloudflare Worker，可以利用Cloudflare Zero Trust的相关功能来增强对公网暴露面的访问控制和安全审查（如果适用）。

* **定期IAM权限审计**:
    * 定期（例如每季度或每半年）对GCP项目中所有用户和服务账号的IAM角色绑定进行审计，确保所有权限分配仍然符合最小权限原则，及时移除不再需要或权限过大的绑定。可以考虑使用自动化工具或脚本来辅助进行权限检测。

* **依赖项安全扫描**:
    * 在CI/CD流程中集成针对Python依赖 (`requirements.txt`) 和TypeScript依赖 (`package.json`) 的安全漏洞扫描工具（例如 `pip-audit`, `npm audit`, Snyk, Dependabot等），及时发现并修复已知漏洞。

## 7. 总结与执行
本安全与权限策略规范是确保NovaScope项目安全、合规运行的基础保障。所有项目参与者都应理解并严格遵守本规范中定义的各项策略和约定。本规范将作为代码审查、基础设施变更审查以及日常运维操作的重要依据。

* **核心原则**: 最小权限、密钥不入库、日志不泄密。
* **关键措施**: 服务账号精细化授权、Secret Manager与Worker Secrets统一管理敏感信息、Terraform状态安全存储、日志脱敏、严格`.gitignore`配置。
* **持续改进**: 定期回顾和更新本安全策略，以适应项目发展和新的安全威胁。

通过共同努力，我们可以为NovaScope项目构建一个安全、可靠的运行环境。