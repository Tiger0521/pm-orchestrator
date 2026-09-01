# 详细设计产出契约

本文件定义详细设计阶段的产出契约，覆盖六类正式文档的字段、frontmatter 规范、ID 分配规则、草稿状态追踪、记忆更新范围和追溯关系。仅在输出草稿预览、落盘或修正已落盘文档时加载。

**边界声明**：本文件只管产出契约。落盘执行步骤（Step 1 草稿即正式直写、Step 2-3 与迭代规划的 JSON 渲染流程）见 `persist-guide.md`；写作规范见 `design-writing.md`；各 Step 执行流程见对应 step 文件夹的 `workflow.md`。

---

## 1. 六类正式文档

详细设计阶段产出六类正式文档。Step 1 的两类由 agent 直写产品库（草稿即正式）；Step 2-3 的三类与迭代规划（`sprint-*.json`，sprint-planning 阶段复用同一条 JSON 渲染轨道）由 `render-doc.sh` 渲染写入。全部落在产品库产品目录下的 `详细设计/` 一级目录，按类型分子目录。所有文档使用产品库继承式 ID，frontmatter 用产品库格式（`id/product/type/aliases/tags`），不带 `capability`/`projectId`/`status`/`refs`。

### 1.1 业务流文档（Step 1 Phase 1）

- 文件路径：`详细设计/结构与流程图/<简称>-业务流.md`
- 层级定位：导航层
- 回答问题：系统怎么跑？页面怎么分层？边界在哪？
- 写入方式：草稿即正式直写（frontmatter 与 ID 由 agent 写入时补全）

| 字段 | 内容要求 |
| ---- | -------- |
| 核心页面层级 | 一级导航分组 + 二级页面清单 |
| 系统边界 | 明确包含的页面/模块，不包含什么（带排除原因） |
| 业务动线 | 从入口到完成的主干动线分步描述 |
| 业务流程图 | Mermaid flowchart（纯用户操作与页面动线）；定稿后追加流程图 HTML 引用 |

### 1.2 页面映射文档（Step 1 Phase 2）

- 文件路径：`详细设计/结构与流程图/<简称>-页面映射.md`
- 层级定位：导航层
- 回答问题：每条 Story 落在哪个页面？跳转是否闭环？
- 写入方式：草稿即正式直写

| 字段 | 内容要求 |
| ---- | -------- |
| 页面映射表 | 页面名称、所属层级/导航路径、关联 Story、核心交互与路由说明（四列表格） |
| 跳转闭环检查 | Story 覆盖、孤儿页面、断链检查结论 |
| 功能架构图 | 定稿后追加：架构图 HTML 引用 + 组件/关系文字摘要 |

### 1.3 原型文档（Step 2）

- 文件路径：`详细设计/原型/<简称>-原型交互说明.md`（可选导出，主交付物为自包含 HTML 文件）
- 层级定位：视觉层
- 回答问题：每个页面长什么样？元素怎么交互？
- 写入方式：JSON + `render-doc.sh`（交互式 HTML 方式的 HTML 主交付物用 Write 直写，见 `persist-guide.md` 第 3.1 节）

| 字段 | 内容要求 |
| ---- | -------- |
| 页面列表 | 原型覆盖的所有页面 |
| 布局 | 每个页面的布局示意（文件路径 + 标注层开关说明） |
| 元素说明 | 每个元素的类型、交互行为、反馈、备注（表格形式，交互式 HTML 方式同时以内联标注卡呈现） |
| 异常状态 | 空状态、加载中、错误状态的具体展示方案和文案 |
| 组件复用 | 跨页面复用的组件名和使用页面 |
| UI 规范引用 | 如已有设计系统，引用对应规范编号 |
| 原型生成方式 | 交互式 HTML（含标注层） |
| 设计决策记录 | 核心页面的方案对比和推荐理由（office-hours 结构） |

### 1.4 交互契约文档（Step 3）

- 文件路径：`详细设计/交互契约/<简称>-交互契约.md`
- 层级定位：逻辑层
- 回答问题：触发时机、状态流转、异常兜底怎么处理？
- 写入方式：JSON + `render-doc.sh`

| 字段 | 内容要求 |
| ---- | -------- |
| 状态机 | 用文字或 Mermaid 描述页面/对象的状态和流转 |
| 交互规则表 | 触发动作 / 校验判断依据（前/后端）/ 状态流转与反馈 / 异常兜底处理（GWT） |
| API 约定 | 如有，列出接口、方法、入参、出参 |
| 错误提示 | 每个错误场景对应一句话术（表格形式） |

### 1.5 规则摘要文档（Step 3）

- 文件路径：`详细设计/规则摘要/<简称>-规则摘要.md`
- 层级定位：约束层
- 回答问题：涉及哪些全局规则、权限约束、NFR？
- 写入方式：JSON + `render-doc.sh`

| 字段 | 内容要求 |
| ---- | -------- |
| 全局规则 | 当前需求涉及的全局规则引用列表 |
| 业务规则 | BR-XXX + 定义与约束摘要 + 影响范围/研发关注点（表格形式） |
| 数据字典 | DD-XXX + 定义与约束摘要 + 影响范围 |
| 权限控制 | NFR-Auth-XX + 定义与约束摘要 + 影响范围 |
| 安全审计 | NFR-Sec-XX + 定义与约束摘要 + 影响范围 |
| 异常兜底规则 | 异常场景 + 兜底策略 + 提示文案（表格形式） |

### 1.6 迭代规划文档（Sprint 分解，sprint-planning 阶段复用）

- 文件路径：`详细设计/迭代规划/<简称>-迭代规划.md`
- 层级定位：交付层
- 回答问题：首个 Sprint 交付什么？依赖和风险是什么？
- 写入方式：JSON + `render-doc.sh`

| 字段 | 内容要求 |
| ---- | -------- |
| 项目总览 | 团队产能、Sprint 长度、总缓冲比例 |
| Sprint 列表 | 每个 Sprint 的目标、包含的 Story（ID、优先级、Story Points、风险） |
| 风险标注 | 高风险 Story 及影响说明 |
| 关键依赖 | 跨 Sprint 依赖和前置条件 |

---

## 2. Frontmatter 规范

每份正式文档使用产品库 frontmatter，必须包含 `id`、`product`、`type`、`aliases`、`tags` 字段。Step 1 两类文档由 agent 直写时手工补全；Step 2-3 三类与迭代规划（sprint-planning 复用）由 `render-doc.sh` 在渲染时分配或复用。产品库 frontmatter 不得保留过程空间的 `projectId`、`status` 或 `refs`；追溯关系由 `refs.json` 的 edges 维护。

### 2.1 业务流文档

```yaml
---
id: "<简称>-DF-FLOW<nn>"
product: "<产品全名>"
type: "业务流"
aliases:
  - "<产品全名> 业务流"
tags:
  - "<简称>"
  - "业务流"
---
```

### 2.2 页面映射文档

```yaml
---
id: "<简称>-DF-FLOW<nn+1>"
product: "<产品全名>"
type: "页面映射"
aliases:
  - "<产品全名> 页面映射"
tags:
  - "<简称>"
  - "页面映射"
---
```

### 2.3 原型文档

```yaml
---
id: "<简称>-DF-PROTO<nnn>"
product: "<产品全名>"
type: "原型"
aliases:
  - "<产品全名> 原型"
tags:
  - "<简称>"
  - "原型"
---
```

### 2.4 交互契约文档

```yaml
---
id: "<简称>-DF-CONTRACT<nnn>"
product: "<产品全名>"
type: "交互契约"
aliases:
  - "<产品全名> 交互契约"
tags:
  - "<简称>"
  - "交互契约"
---
```

### 2.5 规则摘要文档

```yaml
---
id: "<简称>-DF-RULES<nnn>"
product: "<产品全名>"
type: "规则摘要"
aliases:
  - "<产品全名> 规则摘要"
tags:
  - "<简称>"
  - "规则摘要"
---
```

### 2.6 迭代规划文档（sprint-planning 阶段复用）

```yaml
---
id: "<简称>-DF-SPRINT<nnn>"
product: "<产品全名>"
type: "迭代规划"
aliases:
  - "<产品全名> 迭代规划"
tags:
  - "<简称>"
  - "迭代规划"
---
```

---

## 3. ID 分配规则

遵循 `references/shared/traceability-model.md` 的统一规范：

1. **落盘前双重扫描**：同时扫描 `refs.json.nodes` 和产品库目标目录中已有文档的 frontmatter ID，确保不遗漏任何已分配的 ID
2. **按文档类型取最大序号加一**：按文档类型（业务流/页面映射共用 FLOW 序号，原型/交互契约/规则摘要/迭代规划各自独立编号）分别取已使用的最大序号再加一。例如已有 `网资-DF-FLOW01` 和 `网资-DF-FLOW03`，下一个是 `网资-DF-FLOW04`
3. **分配主体**：Step 1 两类文档由 agent 直写时按 `persist-guide.md` 第 2.1 节自行分配；Step 2-3 三类与迭代规划（sprint-planning 复用）由 `render-doc.sh` 在渲染时分配
4. **ID 不可复用**：ID 一经分配不得复用。更新现有文档时沿用原 ID（Step 2-3 与迭代规划由 `render-doc.sh` 从目标文件 frontmatter `id` 字段读取已有 ID），不为更新操作分配新 ID
5. **文件名使用中文描述性名称**：文件名格式为 `<简称>-<类型名>.md`，不使用 ID。例如 `网资-业务流.md`、`网资-原型交互说明.md`。ID 仅存于 frontmatter `id` 字段

---

## 4. 草稿状态追踪

### 4.1 Step 1：文件即草稿

Step 1 的草稿就是产品库中的阶段文件本身，配合 `docs/_extracted/.design/step1-state.json` 追踪阶段与确认状态（结构见 `../step1-功能架构与动线规划/workflow.md` 第 2 节）。用户直接编辑文件视为草稿修改，agent 在下一阶段前重读吸收。三阶段全部确认后按 `persist-guide.md` 第 2.3 节定稿。

### 4.2 Step 2-3 与迭代规划：设计草稿数据块

draft 模式下，subagent 每轮产出的设计草稿必须结构化输出，作为会话恢复的中间状态。草稿态字段 JSON 保留在过程项目 `docs/_extracted/.design/`（每类一个或多个 JSON），是落盘时 `render-doc.sh` 的渲染输入。草稿必须与后续写入产品库的 Markdown 同结构、同字段、同正文内容，禁止输出摘要版草稿。

每轮 draft 输出必须包含以下完整数据块：

```
## 设计草稿数据块

### 原型文档
- 原型生成方式: 交互式 HTML（含标注层） / <待确认>
- 页面原型:
  - 页面1: <已确认/待确认>
  - 页面2: <已确认/待确认>
- 组件复用: <已确认/待确认>
- UI 规范引用: <已确认/无/待确认>

### 交互契约
- 状态机: <已确认/待确认>
- 交互规则表: <已确认规则数>/<总规则数>
- 错误提示: <已确认/待确认>

### 规则摘要
- 全局规则: <已确认/待确认>
- 业务规则: <已确认/待确认>
- 权限控制: <已确认/待确认>

### 迭代规划
- Sprint 目标: <已确认/待确认>
- Story 分配: <已确认/待确认>
- 风险标注: <已确认/待确认>
```

**确认状态标记**：每类文档和每个关键字段独立标记确认状态。`pending`：未确认或用户提出修改（记录修改方向）；`confirmed`：用户已确认。

**会话恢复**：会话中断后，主调度器读取上一轮的设计草稿数据块（含确认状态），以 `mode=draft` 重新委派 subagent；Step 1 按文件存在性与 `step1-state.json` 恢复（见 `../step1-功能架构与动线规划/workflow.md` 第 2 节）。

---

## 5. 记忆更新范围

详细设计阶段涉及 6 个记忆文件的读写。下表列出本阶段的特化写入点和写入内容：

| 记忆文件 | 本阶段特化读取点 | 本阶段特化写入点 | 写入内容 |
| -------- | ---------------- | ---------------- | -------- |
| `progress.json` | - | 落盘后 | 当前阶段和顶层 `lastUpdated`；不修改 currentPhase、顶层 status 或阶段转换字段 |
| `refs.json` | 第 1 步读取上游时 | 写入产品库时 | 新文档节点（`<简称>-DF-FLOW*` 等，含产品库 `libraryId`/`path`/`contentHash`）+ 引用边（见第 6 节） |
| `facts.json` | - | 设计中确认事实时 | 已确认的页面映射、系统边界、交互规则、规则编号等结构化事实 |
| `decision-log.md` | - | 落盘时 | 设计决策（页面层级、页面归类方案、原型方式选择、布局方案选择、异常兜底策略）；Sprint 分解决策由 sprint-planning 阶段记录 |
| `tracking-log.md` | - | 设计中识别风险时 | 依赖关系、未验证假设、新发现的风险和未决问题、规则编号待确认项 |
| `phase-summary.md` | 启动时恢复进度 | 落盘后 | 本阶段恢复摘要：产物清单（6 类文档数量）、关键设计决策、遗留问题和下一步。摘要随写 `phase_status`（供 `references/phase-navigator.md` 读取）：Step 1-2 落盘后 `draft`，Step 3 全部落盘（本阶段完成）后 `persisted` |

---

## 6. 追溯关系

详细设计产物通过 `implements`、`references` 和 `contains` 关系回引 User Story 和 Feature，是追溯链从"用户价值层"到"导航层/视觉层/逻辑层/约束层/交付层"的桥梁。下游的技术设计阶段通过 `implements` 关系从设计产物追溯到 User Story。

```
业务流       ──references──▶ User Story
页面映射     ──references──▶ User Story
原型文档     ──implements───▶ User Story
             ──references───▶ 业务流、页面映射
交互契约     ──implements───▶ User Story
             ──references───▶ 原型文档
规则摘要     ──references───▶ Feature
             ──references───▶ 交互契约
迭代规划  ──contains─────▶ User Story
```

### 6.1 追溯关系汇总表

| 设计产物 | 关系类型 | 指向文档 |
| -------- | -------- | -------- |
| 业务流 | references | User Story |
| 页面映射 | references | User Story |
| 原型文档 | implements | User Story |
| 原型文档 | references | 业务流、页面映射 |
| 交互契约 | implements | User Story |
| 交互契约 | references | 原型文档 |
| 规则摘要 | references | Feature |
| 规则摘要 | references | 交互契约 |
| 迭代规划 | contains | User Story |
