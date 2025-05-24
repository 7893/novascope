Path: novascope/docs/ns-architecture-design-20250524.md

# NovaScope 项目架构设计 (ns-architecture-design-20250524.md)

**项目名称**: NovaScope
**文档版本**: 2.0 (转为详细文字描述版)
**创建日期**: 2025年5月22日
**最后更新**: 2025年5月24日 21:01 (UTC+8)

## 1. 引言

### 1.1 项目目标
NovaScope 项目的核心目标是构建一个功能丰富、技术先进的实践平台，用以深入学习和探索如何有效利用现代云计算服务，特别是 Google Cloud Platform (GCP) 和 Cloudflare所提供的能力，来与美国国家航空航天局 (NASA) 众多的开放应用程序接口 (Open APIs) 进行交互。项目将从集成 NASA 的“每日天文图片”(APOD) API 开始，逐步扩展到涵盖火星探测、地球观测、近地天体追踪等其他引人入胜的 NASA 数据服务，旨在将每一个API的集成实践都作为一个独立且完整的功能模块呈现。

### 1.2 文档目的
本文档旨在全面、详细地阐述 NovaScope 项目的系统架构。内容将覆盖系统的核心设计原则、技术选型依据、各组件的构成与职责、关键数据流转路径、安全策略、可伸缩性与成本考量，以及对未来可能扩展方向的展望。本文档将作为项目开发、部署、维护和后续迭代的重要参考依据，确保所有参与者对系统架构有统一和深入的理解。

---
## 2. 核心设计原则与决策

NovaScope 项目的设计与实施遵循一系列核心原则，以确保其高效、稳健、经济且易于管理。首先，项目坚定地奉行**Serverless 优先**的策略，这意味着我们将最大限度地利用如 GCP Cloud Functions 和 Cloudflare Workers 这样的无服务器计算资源。这种选择旨在显著降低项目的运维复杂度和闲置资源成本，实现真正的按需付费和弹性伸缩。

其次，**成本优化**是贯穿始终的考量。我们优先选用那些提供慷慨免费套餐且单位使用成本较低的云服务，例如 Cloudflare R2 的零出口费用和 GCP 各项服务的免费层级，力求在满足功能需求的前提下，将运营开销降至最低。

第三，整个项目的基础设施将通过**基础设施即代码 (IaC)** 的方式进行管理，具体选用的工具是 **Terraform**。这一决策确保了所有云资源的定义、部署和版本控制都通过代码进行，从而提高了环境的可复现性、一致性和自动化水平。

在**语言选型**方面，我们做出了针对性的选择：GCP Cloud Functions 将采用 **Go 语言**开发，以充分利用其出色的并发性能、高效的执行效率和较低的内存占用，这对于需要快速响应和处理数据的后端服务至关重要。前端及边缘逻辑则由 Cloudflare Worker 承担，采用 **TypeScript** 编写，这既能利用 V8 引擎的极致性能，又能通过静态类型检查来提升代码的健壮性和可维护性。

对于**数据存储**，我们采取了分层和专用的策略：所有从 NASA API 获取的媒体文件（如图片、视频）将统一存储在 **Cloudflare R2 Storage** 的 `ns-r2-nasa-media` 存储桶中，该存储桶内部会按照不同的 NASA API 模块使用对象键前缀（逻辑上的“文件夹”）进行组织。而这些媒体文件及其他相关信息的元数据，则存放在 **GCP Firestore (Native Mode)** 中。根据我们的最新决策，每个 NASA API 模块将拥有其独立的顶级集合来存储元数据，例如 APOD 模块的数据将存放在 `ns-fs-apod-metadata` 集合中。

项目的**命名约定**将严格遵循已制定的 `docs/ns-naming-conventions-20250524.md` 文档，所有云资源和主要代码模块统一使用 `ns-` 作为前缀，并采用 kebab-case 风格。

在**代码组织**上，项目采用 **Monorepo** 结构，所有 Terraform 配置、后端 Go 函数代码、前端 TypeScript Worker 代码以及项目文档都集中在同一个 Git 仓库中进行管理。项目**文档**本身也作为项目的重要组成部分，统一存放在根目录下的 `docs/` 目录中，并采用扁平化的文件结构。

最后，关于 **GCS 存储桶的策略**，我们决定使用一个由 Terraform 创建和管理的**统一 GCS 存储桶**，其名称为 `ns-gcs-unified-sigma-outcome`。这个桶将用于两个核心目的：一是作为 Terraform 的远程状态后端（状态文件存储在桶内的 `tfstate/novascope/` 前缀下），二是存放所有 Cloud Functions 的源代码部署包（存储在桶内的 `sources/functions/` 前缀下）。

---
## 3. 系统架构概述 (文字描述)

NovaScope 项目的整体架构设计为一个高度解耦、事件驱动的无服务器应用，其基础设施和服务主要依托于 Cloudflare 的边缘计算网络和 Google Cloud Platform (GCP) 的强大后端能力。这种混合云的部署方式旨在结合两者的优势，实现高性能、高可用性、高成本效益以及全球化的内容分发。

**用户交互的起点**是用户的浏览器，用户将通过访问一个由 Cloudflare Worker 服务的特定 URL 来与 NovaScope 应用进行交互。

**Cloudflare 作为边缘层**，扮演着至关重要的角色。其核心组件 **Cloudflare Worker**（在本项目中部署后名为 `ns`）采用 TypeScript 编写，它不仅是应用的前端界面提供者（动态生成HTML），同时也是一个轻量级的 API 网关或边缘逻辑处理器。它负责接收来自用户浏览器的所有请求，并根据请求内容与 GCP 后端进行通信以获取所需的数据。获取数据后，Worker 会进行必要的处理和格式化，然后渲染成用户可见的网页内容。此外，所有从 NASA API 下载的媒体文件（如图片、视频）都将存储在 **Cloudflare R2 Storage** 的 `ns-r2-nasa-media` 存储桶中。Worker 可以通过 R2 Bucket Binding 高效地访问这些媒体文件，并将它们的 URL 或内容嵌入到返回给用户的 HTML 中。Cloudflare 强大的 **CDN 网络**将自动缓存这些 R2 中的媒体文件以及 Worker 响应的静态内容，从而极大地加速全球用户的访问速度，并显著降低源站（R2 和 Worker）的负载和出口流量费用。Worker 运行时所需的某些配置或凭证（如调用 GCP 后端的共享密钥）将通过 **Worker Secrets** 进行安全管理。

**Google Cloud Platform (GCP) 则构成了项目的核心后端层**，负责数据的获取、处理、持久化存储以及任务的调度。对于每一个计划集成的 NASA API（例如 APOD、火星探测车照片等），我们都将设计一个专门的**数据获取 Cloud Function**（例如 `ns-func-fetch-apod`），使用 Go 语言编写。这些函数通常由 **GCP Cloud Scheduler**（例如作业 `ns-sched-daily-apod-fetch`）按照预定的周期（如每日、每小时）通过 **GCP Pub/Sub** 主题（例如 `ns-ps-daily-apod-trigger`）以事件驱动的方式触发。被触发后，数据获取函数会首先从 **GCP Secret Manager** 中安全地读取访问对应 NASA API 所需的密钥以及访问 Cloudflare R2 所需的凭证。然后，它会调用目标 NASA API 获取原始数据，下载相关的媒体文件，并将这些媒体文件上传到 Cloudflare R2 的 `ns-r2-nasa-media` 桶中（使用能区分不同 API 来源的对象键前缀，如 `apod/`）。同时，解析后的元数据（如标题、描述、日期、媒体文件在 R2 中的引用路径等）将被写入 **GCP Firestore** 数据库。根据我们的设计，每个 NASA API 模块将在 Firestore 中拥有一个独立的顶级集合来存储其元数据（例如 APOD 模块使用 `ns-fs-apod-metadata` 集合）。

为了让前端的 Cloudflare Worker 能够获取这些处理好的元数据，我们还将开发一个或多个由 HTTP 触发的 **GCP Cloud Function 作为后端 API 服务**（例如，计划中的 `ns-func-get-metadata`，或更通用的 `ns-api-nasa-data`）。这些 API 函数同样使用 Go 语言编写，负责从 Firestore 中查询数据，并以 JSON 格式返回给 Worker。Worker 与这些后端 API 函数之间的通信将通过共享密钥进行认证，以确保安全性。

所有这些 GCP 和 Cloudflare 的基础设施资源，包括它们的配置、依赖关系和部署，都将通过 **Terraform** 以代码的形式进行严格管理。Terraform 的状态文件将存储在 GCP Cloud Storage 的一个统一存储桶 (`ns-gcs-unified-sigma-outcome`) 中，该桶也同时用于存放所有 Cloud Functions 的源代码部署包。

最后，整个系统依赖于外部的 **NASA Open APIs** 作为其原始数据的来源。

---
## 4. 组件详解

(此部分将详细描述每个组件的职责、技术实现和配置，可以参考之前列表版本的内容进行扩充。为了避免重复之前已确认的细节，这里仅列出组件名称，详细描述可从上一版架构文档中提取并按需润色成段落。)

### 4.1 前端/边缘层 (Cloudflare)
我们将利用 Cloudflare 的全球网络为用户提供快速、安全的访问体验。
* **Cloudflare Worker (`ns`)**: 这是我们应用的核心前端和边缘逻辑单元，使用 TypeScript 开发。它直接面向最终用户，处理入站的 HTTP 请求。Worker 的主要职责包括解析用户请求，根据需要向 GCP 后端发起数据请求以获取 NASA API 的元数据。在获取到数据后，它会动态构建 HTML 页面，将数据显示给用户，这包括文本信息以及指向存储在 Cloudflare R2 中的媒体文件的链接。它还将处理与 GCP 后端 API 通信时的认证逻辑，例如发送预定义的共享密钥。
* **Cloudflare R2 Storage (`ns-r2-nasa-media`)**: 这是一个高可用、低成本的对象存储服务，专门用于存储从各个 NASA API 下载的图片、视频等媒体文件。数据在桶内会通过对象键前缀（如 `apod/`，`mrp/images/`）进行逻辑上的“文件夹”组织，以便区分不同 API 来源的媒体。
* **Cloudflare CDN**: Cloudflare 的内容分发网络会自动缓存 R2 中的媒体文件以及 Worker 可能响应的静态内容。这不仅能极大提升全球用户的加载速度，还能有效降低 R2 的数据读取操作次数和相关的出口带宽成本（R2 通过 CDN 的出口流量是免费的）。
* **Worker Secrets**: 对于 Worker 运行时需要的一些敏感配置，例如调用 GCP 后端 API 所需的共享密钥，或者后端 API 的 URL 地址，我们会将它们配置为 Worker 的 Secrets 或环境变量，以确保安全。

### 4.2 后端逻辑层 (GCP)
GCP 提供了强大的、可扩展的无服务器计算能力来支持我们的后端数据处理。
* **Cloud Function (`ns-func-fetch-<api_module>`)** (例如 `ns-func-fetch-apod`): 这是我们为每个计划集成的 NASA API 设计的专用数据获取函数。它们使用 Go 语言编写，以追求高效的执行性能。每个此类函数都由其对应的 Cloud Scheduler 作业通过 Pub/Sub 主题以事件驱动的方式定期触发。其核心任务是从指定的 NASA API 获取最新的数据和媒体文件链接，从 GCP Secret Manager 中安全地获取访问 NASA API 和 Cloudflare R2 所需的凭证，下载媒体文件，将其上传到 `ns-r2-nasa-media` 桶中（存放在对应的“文件夹”下），然后将解析和处理后的元数据写入 GCP Firestore 中相应的集合。
* **Cloud Function (`ns-func-get-metadata` 或更通用的 `ns-api-nasa-data`)** (计划中): 这是一个或一组由 HTTP 触发的 Go Cloud Function，充当后端数据服务 API。它的主要职责是接收来自 Cloudflare Worker 的数据请求（会通过共享密钥进行认证），然后根据请求参数（如 API 类型、日期、分页信息等）从 GCP Firestore 中查询相应的元数据，并以 JSON 格式返回给 Worker。

### 4.3 数据存储层 (GCP)
* **GCP Firestore (Native Mode)**: 我们选择 Firestore 作为元数据的主要存储方案。它是一个 NoSQL 文档数据库，具有高可扩展性和灵活的数据模型。根据我们的决策，每个 NASA API 模块的元数据将存储在 Firestore 中的一个独立顶级集合中，例如 APOD 模块的数据存放在 `ns-fs-apod-metadata` 集合里。文档的 ID 通常会选择具有业务含义且能保证唯一性的字段（例如 APOD 的日期 `YYYY-MM-DD`）。

### 4.4 调度与自动化层 (GCP)
* **GCP Cloud Scheduler** (例如作业 `ns-sched-daily-apod-fetch`): 提供类似 Cron 的定时调度服务。我们将为每个需要定期获取数据的 `ns-func-fetch-<api_module>` 函数配置一个独立的调度作业，定义其执行频率（例如每天、每小时）。
* **GCP Pub/Sub** (例如主题 `ns-ps-daily-apod-trigger`): 作为一个异步消息中间件，它在 Cloud Scheduler 和 Cloud Functions 之间起到了解耦和缓冲的作用。Scheduler 作业将消息发布到指定的主题，而对应的 Function 则订阅该主题以接收消息并被触发执行。

### 4.5 密钥管理
安全地管理各种密钥和凭证是项目成功的关键。
* **GCP Secret Manager**: 这是我们存储所有后端敏感信息的主要场所。例如，NASA API 密钥、Cloudflare R2 的 Access Key ID 和 Secret Access Key、以及用于 Cloudflare Worker 与 GCP 后端函数之间认证的共享密钥，都会作为独立的 Secret 存储在这里（Terraform 会创建密钥的“容器”，实际值由我们手动添加版本）。GCP Cloud Functions 在运行时会通过其被授予的服务账号身份从 Secret Manager 安全地读取这些值。
* **Cloudflare Worker Secrets**: Cloudflare Worker 运行时需要的敏感信息（如它要发送给 GCP 后端的共享密钥）会配置为 Worker 自身的 Secrets。

### 4.6 基础设施即代码 (Terraform)
项目的整个云基础设施（包括 GCP 和 Cloudflare 上的所有资源）都将通过 Terraform以代码的形式进行定义、部署和管理。这种方式确保了环境的一致性、可复现性和版本控制。Terraform 的状态文件将安全地存储在 GCP Cloud Storage 的统一存储桶 (`ns-gcs-unified-sigma-outcome`) 中的 `tfstate/novascope/` 路径下。

### 4.7 外部服务
* **NASA Open APIs**: 这是 NovaScope 项目所有数据的最终来源，我们将逐步集成和实践其提供的多种 API 服务。

---
## 5. 数据流

(此部分详细描述关键场景下的数据流动路径，与上一版文字描述基本一致，此处省略，具体请参考上一版详细的数据流描述，只需将APOD特定的名称替换为更通用的概念或针对特定模块的示例即可。)

### 5.1 用户访问前端页面 (以APOD为例，未来由通用Worker `ns` 和 API `ns-func-get-metadata` 处理)
### 5.2 每日数据自动获取与存储 (以`ns-func-fetch-apod` 为例)

---
## 6. 安全考量

(此部分详细描述项目的安全策略，与上一版文字描述基本一致，此处省略，具体请参考上一版详细的安全考量，例如密钥管理、服务间认证、最小权限原则、IaC安全等。)

---
## 7. 可伸缩性与性能

(此部分详细描述系统如何通过Serverless和CDN等技术实现高可伸缩性和高性能，与上一版文字描述基本一致，此处省略。)

---
## 8. 成本考量

(此部分详细描述项目的成本效益设计，与上一版文字描述基本一致，此处省略，例如依赖免费套餐、Serverless按需付费、R2免费出口等。)

---
## 9. 命名约定参考

本项目所有资源的命名将严格遵循 `docs/ns-naming-conventions-20250524.md` 文档中定义的规范。

---
## 10. 未来可能的增强方向 (可选)

(此部分与上一版基本一致，列举未来可能的扩展点，此处省略。)

---