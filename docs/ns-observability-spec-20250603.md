好的，我们已经完成了项目架构设计文档和命名规范文档的更新。

根据我们之前精简后的核心项目文档列表，下一个应该输出的文档是 **可观测性实施规范文档**。

我将基于您之前提供的 `ns-observability-spec-20250603.md` 的内容，并严格遵循您对文档编制的所有要求（文件名、路径、标题包含文件名、更新时间戳、内容详尽准确、完整输出、纯文字描述），来生成这份文档。

---

Path: novascope/docs/ns-observability-spec-20250605.md
# NovaScope 可观测性实施规范 (ns-observability-spec-20250605.md)
**最后更新时间**: 2025年6月5日 11:40 (UTC+8)

## 0. 引言
本规范旨在指导 NovaScope 项目在各个子系统（包括GCP Cloud Functions和Cloudflare Workers）中系统性地落地可观测性（Observability）措施，确保开发者对系统运行状态具备全面、实时的掌控能力，从而能够快速定位问题、优化性能并保障服务稳定性。文档覆盖结构化日志、指标监控、告警策略、链路追踪等维度的实现策略和约定，并与项目架构设计文档（`ns-architecture-design-20250605.md`）及命名规范文档（`ns-naming-conventions-20250605.md`）保持一致。

## 1. 总体目标
为NovaScope项目提供全面的可观测性，具体实现以下目标：

* **可追踪性 (Traceability)**：当数据抓取任务失败或前端请求异常时，能够快速定位到具体的模块、函数、错误类别和相关上下文。
* **可告警性 (Alertability)**：对于关键路径（如核心数据抓取函数、定时调度任务）发生的错误或性能下降，能够通过预设的告警策略即时通知到相关人员。
* **可调试性 (Debuggability)**：开发者能够通过详细的日志和追踪信息，高效地分析系统行为、复现问题、诊断错误根源。
* **可分析性 (Analyzability)**：长期积累的日志和指标数据应支持对系统行为模式、性能趋势、资源消耗等进行深入分析和洞察，为项目优化提供数据支撑。
* **成本可控性 (Cost Efficiency)**：在满足可观测性需求的前提下，合理配置日志存储、指标采集和告警服务，避免因日志或监控数据过量产生不必要的云服务费用。

## 2. GCP Cloud Functions 可观测性 (`ns-func-fetch-nasa-data` 和 `ns-api-nasa-data`)

### 2.1 结构化日志
所有Python Cloud Functions（`ns-func-fetch-nasa-data`, `ns-api-nasa-data`）必须采用结构化日志方案。

* **实施方案**:
    * **标准库与JSON**: 使用Python内置的`logging`模块，并配置JSON Formatter（例如通过自定义Formatter或引入如`python-json-logger`的库），确保所有日志输出为JSON格式。
    * **GCP Cloud Logging集成**: GCP Cloud Functions的标准输出（stdout/stderr）会自动被Cloud Logging服务捕获。JSON格式的日志可以直接被Cloud Logging识别为结构化条目，便于后续的查询、分析和基于日志的指标创建。
* **日志级别划分**:
    * **INFO**: 记录程序正常运行过程中的关键操作、状态变化、处理进度等信息。例如，开始抓取某个模块、成功写入Firestore的文档数量。
    * **WARNING**: 记录可恢复的异常情况或非预期的系统状态，但程序仍能继续处理。例如，某个API调用出现临时性网络抖动后重试成功，或者某个模块返回的数据部分不符合预期但仍可处理。
    * **ERROR**: 记录某个模块或特定操作失败，但整体函数实例未崩溃，可能影响了部分数据的完整性或及时性。例如，抓取某个NASA API模块时发生连接超时或返回了错误状态码，导致该模块本次数据未被处理。
    * **CRITICAL**: 记录导致整个函数实例或核心流程严重失败的错误，通常表明系统处于非常不健康的状态。例如，无法从Secret Manager读取核心配置、无法连接到Firestore数据库等。
* **推荐的日志字段 (JSON结构)**:
    ```json
    {
      "timestamp": "YYYY-MM-DDTHH:mm:ss.sssZ", // ISO 8601格式的UTC时间戳 (由logging模块自动生成)
      "severity": "INFO", // 日志级别 (INFO, WARNING, ERROR, CRITICAL)
      "message": "Detailed log message", // 日志主体信息
      "service_context": { // 服务上下文信息
        "service": "ns-func-fetch-nasa-data", // 或 ns-api-nasa-data
        "version": "1.0.0" // (可选) 函数版本
      },
      "execution_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", // GCP Cloud Function的执行ID (可从环境变量获取)
      "trace_id": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy", // 链路追踪ID (详见链路追踪章节)
      "module_id": "apod", // (仅适用ns-func-fetch-nasa-data) 当前处理的NASA API模块标识
      "operation": "fetch_api_data", // 当前执行的操作或子函数名
      "status": "SUCCESS", // 操作状态 (SUCCESS, FAIL, PARTIAL_SUCCESS)
      "duration_ms": 123.45, // (可选) 操作耗时 (毫秒)
      "error_type": "ConnectionTimeout", // (如果level是ERROR/CRITICAL) 错误类型
      "error_details": "...", // (如果level是ERROR/CRITICAL) 详细错误信息或堆栈
      "record_count": 1, // (可选) 处理或影响的记录数量
      "target_resource": "ns-fs-apod-metadata/2025-06-05", // (可选) 操作相关的目标资源
      "custom_dimensions": { // (可选) 其他自定义维度信息
        "api_url": "https://api.nasa.gov/planetary/apod?date=...",
        "retry_attempt": 1
      }
    }
    ```
* **采集与存储**:
    * 日志默认由GCP Cloud Logging自动收集和存储。
    * **建议配置Log Sink**: 将所有`ERROR`和`CRITICAL`级别的日志，以及采样后的`INFO`和`WARNING`级别日志，从Cloud Logging导出到Google BigQuery进行长期存储和复杂分析，或导出到GCS进行归档。这将有助于成本控制和满足长期审计需求。此Log Sink将通过Terraform (`google_logging_project_sink`)进行管理。

### 2.2 指标监控与告警 (`ns-func-fetch-nasa-data` 和 `ns-api-nasa-data`)
利用GCP Cloud Monitoring来监控函数性能和错误，并设置告警。

* **核心监控指标**:
    * **执行次数 (Invocation Count)**: 总调用量，可按成功/失败状态细分。
    * **执行时间 (Execution Time)**: P50, P90, P95, P99分位数，以及平均执行时间。
    * **错误率 (Error Rate)**: 失败调用次数占总调用次数的百分比。
    * **内存使用 (Memory Usage)**: 监控函数是否接近其配置的内存上限。
* **告警策略 (通过Terraform `google_monitoring_alert_policy` 定义)**:
    1.  **`ns-func-fetch-nasa-data` 抓取失败告警**:
        * **触发条件1**: 在过去1小时内，函数执行的错误率（基于Cloud Functions自身指标或基于日志中`status=FAIL`的错误日志计数）持续高于某个阈值（例如5%）。
        * **触发条件2**: 在过去24小时内，函数连续执行失败次数超过某个阈值（例如2次）。
        * **触发条件3 (基于日志)**: 基于从结构化日志创建的自定义指标（Log-based Metric），例如统计特定模块（如`apod`）在日志中报告`status=FAIL`且`record_count=0`的频次，当该频次在特定时间窗口内（如1小时）高于设定阈值时触发。
    2.  **`ns-api-nasa-data` API服务异常告警**:
        * **触发条件1**: 在过去15分钟内，函数执行的错误率高于某个阈值（例如1%）。
        * **触发条件2**: 函数的P95执行时间持续超过某个阈值（例如2秒）。
* **告警通知渠道**:
    * **初期**: 邮件通知。
    * **后期可扩展**: Webhook集成到Slack、DingTalk等即时通讯工具。

## 3. GCP Cloud Scheduler 可观测性 (`ns-sched-daily-fetch`)

* **核心监控**: 确保调度作业按预期执行并成功触发Pub/Sub。
* **告警策略 (通过Terraform `google_monitoring_alert_policy` 定义)**:
    1.  **调度作业执行失败/超时告警**:
        * **触发条件**: 基于Cloud Scheduler的内置指标 `cloudscheduler.googleapis.com/job/execution_count` 并按 `status` 标签（如 `FAILED`, `TIMEOUT`）进行筛选，当失败或超时计数在24小时内大于0时触发。
    2.  **调度作业未按预期运行告警 (Missed Execution)**:
        * **触发条件**: 监控调度作业的“最后执行成功时间戳”。如果当前时间距离上次成功执行时间戳超过了预设的调度周期（例如，超过25小时对于一个每日任务），则触发告警。这可能需要结合自定义指标或外部检查来实现。
    3.  **触发Pub/Sub后下游无响应告警**:
        * **触发条件**: Scheduler成功将消息发布到`ns-ps-daily-nasa-fetch`主题后，在预期时间内（例如10分钟内），`ns-func-fetch-nasa-data`函数没有相应的执行日志（或执行成功日志）。这可以通过创建基于日志的指标（log-based metric）来统计Pub/Sub消息ID在Scheduler日志和Function日志中的匹配情况，或者统计Function在Scheduler触发后的执行次数。
* **通知渠道**: 同函数告警。

## 4. Cloudflare Worker (`ns`) 可观测性

### 4.1 结构化日志
Cloudflare Worker的日志应遵循结构化原则，便于调试和分析。

* **实施方案**:
    * **统一日志格式**: 所有`console.log`, `console.error`等输出都应使用`JSON.stringify()`封装成JSON对象。
    * **推荐字段**:
        ```json
        {
          "timestamp": "YYYY-MM-DDTHH:mm:ss.sssZ", // new Date().toISOString()
          "severity": "INFO", // INFO, ERROR
          "source": "cloudflare_worker",
          "worker_script_name": "ns",
          "request_url": "https://...", // req.url
          "request_method": "GET", // req.method
          "status_code": 200, // (可选, 记录响应状态码)
          "user_agent": "...", // req.headers.get('user-agent')
          "trace_id": "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz", // 链路追踪ID
          "message": "Detailed log message",
          "error_details": "...", // (如果level是ERROR)
          "custom_dimensions": { // (可选)
            "module_requested": "apod" 
          }
        }
        ```
    * **封装日志函数**: 建议在Worker项目中创建一个通用的`logger.ts`模块，封装结构化日志的打印行为，确保格式统一。
* **日志查看与采集**:
    * **本地开发**: 使用`wrangler dev`时，日志会输出到控制台。
    * **生产环境**: 使用`wrangler tail`实时查看日志流。
    * **长期存储/分析 (可选)**: Cloudflare Workers可以将日志导出到第三方日志服务或对象存储。对于NovaScope的成本控制目标，初期可能不配置导出，依赖`wrangler tail`进行即时调试。未来如果需求明确，可以考虑将错误日志或采样日志发送到GCP Cloud Logging（例如通过一个轻量级的HTTP请求到专用的日志接收端点）。

### 4.2 指标监控与告警 (基础)
* **Cloudflare Analytics**: 利用Cloudflare仪表盘提供的Worker分析功能，监控请求数、CPU时间、错误率等基本指标。
* **自定义告警 (基于Cloudflare功能)**: 如果Cloudflare提供了针对Worker错误率的告警功能，可以配置基础告警。
* **更高级的监控**: 如果需要更细致的自定义指标和告警，可能需要Worker主动将指标数据推送到外部监控系统（例如GCP Cloud Monitoring，通过API），但这会增加复杂度和成本，初期不作重点。

## 5. 请求链路追踪 (Distributed Tracing)
为了能够追踪一个用户请求从Cloudflare Worker到GCP后端服务的完整调用链路，将引入Trace ID机制。

* **实施方案**:
    1.  **Trace ID 生成**: Cloudflare Worker (`ns`) 在接收到外部请求或发起对GCP的请求时，应生成一个全局唯一的`trace_id`（例如UUID）。
    2.  **Trace ID 传递**:
        * Worker在向GCP Cloud Function (`ns-api-nasa-data`) 发起HTTP请求时，将此`trace_id`放入自定义的请求头中（例如 `X-Cloud-Trace-Context` 或 `X-Request-ID` 或 `X-Trace-Id`）。
        * 如果`ns-api-nasa-data`进一步调用其他服务（目前架构中不直接涉及），也应继续传递此`trace_id`。
        * `ns-func-fetch-nasa-data` 虽然是Pub/Sub触发，但其内部处理不同模块时，也可以为每个模块的抓取过程生成一个唯一的`correlation_id`，并在日志中记录。
    3.  **Trace ID 记录**:
        * Cloudflare Worker在其所有结构化日志中都必须包含此`trace_id`。
        * 所有GCP Cloud Functions在其所有结构化日志中，如果请求是由Worker发起的，则必须从请求头中提取并记录相同的`trace_id`。
* **目标**:
    * 通过在Cloud Logging（以及未来可能的Cloud Trace）中按`trace_id`筛选，可以轻松地将一个请求在不同服务间的日志串联起来，还原完整的调用链路。
    * 有助于快速定位性能瓶颈和错误发生的环节。
    * 为未来集成GCP Cloud Trace或兼容OpenTelemetry的分布式追踪系统打下基础。

## 6. 前端性能数据采集 (可选，远期考虑)
若未来NovaScope前端界面（由Cloudflare Worker SSR生成）的交互变得复杂，且对用户体验有更高要求时，可以考虑引入前端性能数据采集。

* **推荐策略**:
    * **核心Web指标 (Web Vitals)**: 采集LCP (Largest Contentful Paint), FID (First Input Delay), CLS (Cumulative Layout Shift) 等标准指标。
    * **自定义指标**: 例如，从用户感知角度出发，可以采集特定NASA模块数据的加载时间、首屏图片渲染完成时间等。
    * **数据上报**: 可以通过一个轻量级的JavaScript信标(beacon)将采集到的性能数据以采样方式（例如5%-10%的用户会话）上报。上报端点可以是一个专用的简单Cloudflare Worker或GCP Cloud Function，它接收数据并将其存入BigQuery或Cloud Logging进行分析。
    * **Cloudflare Workers KV**: 可用于暂存一些轻量的、与性能相关的配置或临时聚合数据。

## 7. 日志安全与合规
* **禁止打印敏感信息**: 在任何日志（包括GCP和Cloudflare）中，严禁直接打印或间接泄露任何敏感信息，如API密钥、访问令牌、数据库凭证、用户个人身份信息(PII)等。
* **共享密钥管理**: Cloudflare Worker与GCP后端API之间的共享认证密钥，其值应分别安全存储在Cloudflare Worker Secrets和GCP Secret Manager中，代码中通过引用名称来获取，绝不硬编码。
* **数据脱敏**: 对于请求日志中可能包含的用户IP地址、精确地理位置或其他潜在敏感的用户标识符，在记录到日志前应进行必要的脱敏处理（例如，IP地址部分匿名化）。

## 8. 总结与执行优先级
可观测性是确保NovaScope项目长期稳定运行的关键。以下是建议的实施优先级：

1.  **立即实施 (高优先级)**:
    * GCP Cloud Functions的**结构化日志** (JSON格式，包含核心字段)。
    * `ns-func-fetch-nasa-data` 的**核心抓取失败告警** (基于错误率或连续失败次数)。
    * `ns-sched-daily-fetch` 的**核心调度失败告警**。
    * Cloudflare Worker的**基本结构化日志** (JSON格式，包含核心字段)。
    * **请求链路Trace ID**的生成（在Worker）与传递及记录（在Worker和GCP Functions的日志中）。
    * 在共享库`packages/shared-utils-py/shared_utils/secrets.py`中实现统一的Secret加载逻辑。
2.  **逐步增强 (中优先级)**:
    * 配置GCP日志导出到BigQuery/GCS。
    * 实现更细致的基于日志的指标和告警（例如特定模块抓取失败告警）。
    * 完善Cloudflare Worker的告警（如果平台功能支持）。
    * 将告警策略通过Terraform (`monitoring.tf`)进行完整管理。
3.  **远期考虑 (可选，低优先级)**:
    * 全面集成GCP Cloud Trace。
    * 引入前端性能数据采集。

通过上述规范的逐步实施，NovaScope项目将具备良好的可观测性基础。