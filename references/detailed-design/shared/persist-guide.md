# 落盘指南

本文件是详细设计阶段落盘执行的唯一权威来源。定义两条落盘轨道：**Step 1 采用"草稿即正式"直写机制**（阶段文件直接写入产品库，用户看改，确认即定稿）；**Step 2-4 采用 JSON + 脚本渲染机制**（草稿在对话中确认，确认后写 JSON 并调用 `render-doc.sh` 渲染）。

**加载规则**：`mode=draft` 落盘前加载本文件；`mode=persist` 修正已落盘文档时加载本文件；`mode=validate` 禁止预读。

**边界声明**：本文件只管落盘执行。产出字段定义见 `output-contract.md`；写作规范见 `design-writing.md`；校验项见 `checklist.md`。

---

## 1. 两条落盘轨道总览

| 轨道 | 适用 Step | 机制 | Markdown 写入方式 |
| ---- | ---- | ---- | ---- |
| 草稿即正式 | Step 1（业务流 / 页面映射 / 两张 HTML 图） | 阶段文件直接写入产品库含 frontmatter 与 ID，用户直接看改文件，逐阶段确认，三阶段齐后统一定稿注册 | agent 用 Write 工具整文件写入（唯一允许直写的产物） |
| JSON + 渲染 | Step 2（原型）/ Step 3（交互契约 + 规则摘要）/ Step 4（迭代规划） | 草稿在对话中展示确认，确认后将数据写入 JSON，调用 `render-doc.sh` 渲染 | **严禁**用 Write 工具逐行写 Markdown，必须走脚本 |

**为什么 Step 1 不同**：Step 1 的三份产物需要用户反复看改（用户可直接编辑文件），草稿与正式必须是同一份文件，不存在"对话草稿 -> 脚本渲染"的二次转换。Step 2-4 的产物以对话草稿确认后一次成型，维持脚本渲染的 ID 分配与格式校验保障。

---

## 2. Step 1：草稿即正式

### 2.1 ID 分配

agent 在 Phase 1 写入业务流文档时自行分配 ID（render-doc.sh 不参与 Step 1）：

1. 扫描产品库 `详细设计/结构与流程图/` 目录下全部文件的 frontmatter `id`，取 `<简称>-DF-FLOW` 前缀的最大序号
2. 无已有 FLOW 文档时从 `01` 起；有则取最大序号 +1，得到 `<nn>`
3. 业务流文档取 `<nn>`，页面映射文档取 `<nn>+1`；两张 HTML 图用中文描述性文件名（`<简称>-业务流程图.html`、`<简称>-功能架构图.html`，命名规则见 `../step1-功能架构与动线规划/html-diagram.md` 第 1 节），不嵌入 ID 序号
4. `iteration` 项目：已存在业务流/页面映射文档时**沿用原 ID 原地更新**，不分配新序号；只有缺失的文档才用新序号补建

### 2.2 阶段写入（每阶段执行）

按 `../step1-功能架构与动线规划/workflow.md` 的阶段流程执行：

1. grilling 收敛后，用 Write 工具将阶段文档（含完整产品库 frontmatter）整文件写入产品库 `详细设计/结构与流程图/`
2. Phase 3 两张 HTML 同样用 Write 工具直接写入
3. 更新 `docs/_extracted/.design/step1-state.json`（阶段状态与文件路径）
4. 告知用户文件路径，返回 `needs-input` 等待确认；**不得在用户确认前注册 refs 或更新记忆文件**
5. 用户提出修改：agent 修正后重写文件再等确认；用户直接编辑文件：下一阶段开始前必须重读文件，以文件当前内容为准

### 2.3 定稿（三阶段全部确认后执行）

1. **重读全部四份产物文件**（两份 md + 两张 HTML 的引用关系），吸收用户的直接编辑
2. 在业务流文档的"业务流程图"章节追加流程图 HTML 引用；在页面映射文档的"功能架构图"章节追加架构图 HTML 引用（引用格式见 `../step1-功能架构与动线规划/business-flow-writing.md` 第 3.4 节）
3. 注册 `refs.json`：两份 md 文档节点（含产品库 `libraryId`/`path`/`contentHash`）和引用边（业务流/页面映射 `references` User Story）
4. 更新记忆文件（见第 4 节）
5. 对两份 md 逐个运行 `validate-paradigm.sh`，有 `[WARN]` 时修正文件后重跑，零警告才算定稿
6. 更新 `step1-state.json`（`phase: done`），返回 `draft-ready`

### 2.4 修订（已定稿文档的修正）

用户要求修改已定稿的 Step 1 文档时（`mode=persist`）：直接编辑该 md 文件（或按用户口述修改后重写），保持 ID 不变，重跑 `validate-paradigm.sh` 零警告后更新 `refs.json` 的 `contentHash` 与记忆文件。**不走 JSON + render-doc.sh**。

### 2.5 sourceProduct 直启

handoff 含 `sourceProduct` 时，Step 1 三份产物与其他项目一致，直接写入来源产品在产品库的产品目录 `详细设计/结构与流程图/`，命名与 ID 规则不变；定稿流程（refs 注册 + 记忆更新 + 校验）与第 2.3 节一致。只读约束仅针对来源产品的已有文档（Story、设计、能力文档），新设计文档的写入不受限制（见 `../step1-功能架构与动线规划/workflow.md` 第 7 节）。

---

## 3. Step 2-4：JSON + 脚本渲染

### 3.1 脚本化落盘原则

落盘分两层：AI 负责准备结构化数据（设计 JSON），脚本负责渲染 Markdown 文件。**严禁 AI 用 Write 工具逐行写这几类 Markdown 文件**。

- **AI 的职责**：每步确认后，将用户已确认的设计草稿数据写入 `docs/_extracted/.design/` 目录下的 JSON 文件。AI 不负责渲染、不负责 ID 分配、不负责格式校验
- **脚本的职责**：读取 JSON 数据 -> 按模板替换占位符 -> 分配 ID -> 写入 Markdown -> 自动运行校验
- **失败重试规则**：脚本返回非 0 时，AI 按其错误信息修正 JSON 中的字段后重试。不得回退到逐行 Write
- **交互式 HTML 主交付物例外**：Step 2 主交付物 HTML 文件（含标注层，预览态/标注态同一份）用 Write 工具直接写入产品库 `详细设计/原型/` 目录（与 Step 1 两张 HTML 图同机制），不走 JSON + render-doc.sh；交互说明文档（proto-*.md）降为可选导出（用户需要离线 md 时从同一份 proto JSON 用 `render-doc.sh` 渲染），不再是默认必交。

### 3.2 设计 JSON 结构

JSON 文件写入 `docs/_extracted/.design/` 目录，每类文档对应一个或多个 JSON 文件：

| 文件名 | 文档类型 | 所属 Step |
| ---- | ---- | ---- |
| `proto-<nnn>.json` | 原型数据 | Step 2 |
| `contract-<nnn>.json` | 交互契约数据 | Step 3 |
| `rules-<nnn>.json` | 规则摘要数据 | Step 3 |
| `sprint-<nnn>.json` | 迭代规划数据 | Step 4 |

JSON 字段结构与草稿数据块一致（字段定义见 `output-contract.md` 第 4 节），字段值为已格式化的 Markdown 片段（表格/代码块/列表字符串），字段名与 `render-doc.sh` 渲染函数提取的 key 一一对应。

`proto-<nnn>.json` 结构示例：

```json
{
  "type": "prototype",
  "title": "原型文档",
  "proto_method": "交互式 HTML（含标注层，预览态/标注态可切换）",
  "page_list": "1. 订单列表页\n2. 退款弹窗",
  "page_detail": "### 订单列表页\n布局：顶部筛选条 + 表格\n元素：搜索框、状态筛选、操作列",
  "component_reuse": "| 组件 | 复用页面 |\n| ---- | ---- |\n| 表格 | 列表页、详情页 |",
  "ui_spec_ref": "无已有设计系统，本轮统一定义",
  "design_decision": "- **布局**：筛选置于顶部，与表格分离\n- **交互**：点击行跳详情，非弹窗"
}
```

`contract-<nnn>.json` 结构示例：

```json
{
  "type": "interaction-contract",
  "title": "交互契约",
  "state_machine": "```mermaid\nstateDiagram-v2\n  [*] --> 草稿\n  草稿 --> 提交: 保存\n  提交 --> [*]: 成功\n```",
  "interaction_rules": "| 触发条件 | 前端校验 | 成功流转 | 失败兜底 |\n| ---- | ---- | ---- | ---- |\n| 点击保存 | 必填项校验 | 写入成功，停留列表 | 显示错误提示 |",
  "error_prompt": "| 场景 | 提示文案 |\n| ---- | ---- |\n| 超时 | 网络异常，请重试 |\n| 无权限 | 无操作权限，请联系管理员 |",
  "api_convention": "| 接口 | 方法 | 入参 | 出参 |\n| ---- | ---- | ---- | ---- |\n| /api/order | POST | order | id |"
}
```

`rules-<nnn>.json` 结构示例：

```json
{
  "type": "rules-summary",
  "title": "规则摘要",
  "global_rules": "- **规则一**：所有列表页默认按创建时间倒序\n- **规则二**：删除操作均为软删除",
  "business_rules": "| 编号 | 摘要 | 范围 |\n| ---- | ---- | ---- |\n| BR-01 | 列表默认倒序 | 全部列表 |",
  "data_dict": "| 编号 | 摘要 | 范围 |\n| ---- | ---- | ---- |\n| DD-01 | 状态字段 | 全部 |",
  "auth_control": "| 编号 | 摘要 | 范围 |\n| ---- | ---- | ---- |\n| NFR-Auth-01 | 角色隔离 | 运营端 |",
  "security_audit": "| 编号 | 摘要 | 范围 |\n| ---- | ---- | ---- |\n| NFR-Sec-01 | 操作留痕 | 全部 |",
  "exception_fallback": "| 场景 | 兜底策略 | 文案 |\n| ---- | ---- | ---- |\n| 超时 | 重试 | 请重试 |"
}
```

`sprint-<nnn>.json` 结构示例：

```json
{
  "type": "sprint",
  "title": "迭代规划",
  "project_overview": "产能：20 人天\n长度：2 周\nSprint 数：2",
  "sprint_list": "### Sprint 1\n| Story | 优先级 | SP | 风险 | 依赖 |\n| ---- | ---- | ---- | ---- | ---- |\n| US-01 | P0 | 3 | 低 | 无 |\n| US-02 | P0 | 5 | 中 | 区划数据 |",
  "risk_annotation": "- **风险一**：区划数据未就绪，影响 US-02\n- **风险二**：审核流程未对齐，影响 US-05",
  "key_dependency": "- 区划基础数据\n- 鉴权服务"
}
```

### 3.3 脚本渲染流程

每个 Step 用户确认后立即执行步级落盘，不等四步全完成：

1. **写入该步 JSON**：将用户已确认的该步设计数据写入 `docs/_extracted/.design/` 对应文件
2. **调用渲染脚本**：对该步产出的每个 JSON 文件调用一次 `render-doc.sh`（单文件渲染）：

   ```bash
   bash "<skillPath>/scripts/render-doc.sh" \
     "<projectPath>/docs/_extracted/.design/<file>.json" \
     "<selectedProductLibraryPath>/<产品全名>" \
     "<产品简称>" \
     "<产品全名>"
   ```

   脚本自动完成：按类型分配继承式产品库 ID（`<简称>-DF-PROTO<nn>` 等）、用中文描述性文件名写入产品库 `详细设计/<类型子目录>/`（如 `<简称>-原型交互说明.md`）、自动运行 `validate-paradigm.sh`
3. **校验硬门禁**：有 `[WARN]` 项时必须修复对应 JSON 中的字段格式，重新渲染，直到零警告才能报告该步 `persisted`。不得跳过校验、不得忽略警告；修复在 JSON 字段层面进行，不得直接修改已渲染的 Markdown 文件
4. **更新记忆文件**：见第 4 节
5. **更新 `progress.json`**：仅更新当前阶段和顶层 `lastUpdated`，不得修改 `workflow.state`、顶层 `status` 或阶段转换字段

各步对应类别与输出子目录：

| Step | 落盘类别 | JSON 文件 | 输出子目录 |
| ---- | ---- | ---- | ---- |
| Step 2 原型 | 原型 | `proto-*.json` | `详细设计/原型/` |
| Step 3 交互契约+规则 | 交互契约 + 规则摘要 | `contract-*.json`、`rules-*.json` | `详细设计/交互契约/`、`详细设计/规则摘要/` |
| Step 4 Sprint | 迭代规划 | `sprint-*.json` | `详细设计/迭代规划/` |

**修订场景**：用户要求修正已落盘的 Step 2-4 文档时，直接重新调用 `render-doc.sh` 即可--脚本通过中文文件名定位目标文件，从该文件 frontmatter `id` 字段读取已有 ID 并沿用，覆盖更新。无需在 JSON 中传 `existing_id` 字段。

---

## 4. 记忆更新（两条轨道共用）

落盘/定稿后更新以下记忆文件（仅注册本轮落盘的文档节点与引用边）：

- `refs.json` -- 注册新文档节点（含产品库 `libraryId`/`path`/`contentHash`）和引用边
- `facts.json` -- 记录已确认事实（页面映射、系统边界、交互规则、规则编号）
- `decision-log.md` -- 记录设计决策及理由（页面归类、原型方式、布局方案、异常兜底、Sprint 分解）
- `tracking-log.md` -- 记录风险/假设/未决问题（依赖关系、规则编号待确认项）
- `phase-summary.md` -- 追加本轮摘要（产物、关键设计决策、遗留问题）

---

## 5. 脚本列表

| 脚本 | 作用 | 适用轨道 |
| ---- | ---- | ---- |
| `render-doc.sh` | 单文件渲染设计 JSON 为产品库 Markdown，分配继承式 ID，渲染后自动运行 `validate-paradigm.sh` | 仅 Step 2-4 |
| `validate-paradigm.sh` | 校验写作规范（加粗领条、表格、流程图等，按 frontmatter type 路由） | 两条轨道（Step 1 定稿时对两份 md 手动运行；Step 2-4 由 render-doc.sh 自动运行） |

**脚本使用铁律**：Step 2-4 的 Markdown 落盘用脚本，不用 AI 逐行 Write；Step 1 的三份产物是唯一例外，按第 2 节用 Write 直写。
