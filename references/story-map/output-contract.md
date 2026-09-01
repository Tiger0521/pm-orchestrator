# 故事地图阶段产出契约

本文件在需要生成完整草稿预览、执行 `mode=persist` 或核对正式产物字段时读取。

## 1. 产物清单

本阶段产出三类正式文档：User Story（用户价值层）、溯源矩阵（追溯层）、能力级地图（可视化层）。

| 产物 | 文件数 | 命名规则 | 目录 |
| --- | --- | --- | --- |
| User Story | N（=Story 数） | `<简称>-<能力路径>-<标题>故事.md` | 产品库 `<能力路径>/用户故事/` |
| 溯源矩阵 | 1 | `matrix-<nnn>.md` | 过程项目 `docs/requirement-analysis/` |
| 能力级地图 | N（=能力数） | `{产品名}-{能力名}能力-用户故事地图.md` | 产品库 `用户故事地图/` |

User Story 直接写入产品库，溯源矩阵留在过程项目，故事地图写入产品库 `用户故事地图/` 目录。每份文档通过 frontmatter 建立追溯关系。

## 2. User Story 文档

### 2.1 字段表

文件路径：`<产品目录>/<能力路径>/用户故事/<简称>-<能力路径>-<标题>故事.md`。每条 Story 必须写入其唯一归属 Feature 对应能力路径下的 `用户故事/` 子目录；不得写入过程项目 `docs/` 或其他能力的目录。

| 字段 | 内容要求 |
| ---- | -------- |
| Story 标题 | 用业务语言概括用户目标，不是技术操作名 |
| 三段式描述 | “作为 [角色]，我想要 [目标]，以便于 [价值]”，角色具体、活动描述用户意图、价值清晰合理 |
| 优先级 | P0 / P1 / P2，**继承需求台账条目优先级**；条目缺失或未定则标"待确认"并向用户询问 |
| Story Points 建议 | 1 / 2 / 3 / 5 / 8 / 13，附注“建议值，待团队确认” |
| 旅程阶段 `journey_stage` | 值来自已验证全局旅程叙事线节点（`<全局旅程阶段>-<能力内节点>` 或叙事线节点名） |
| 需求台账关联 `requirementEntryId` | 需求台账条目 ID，格式 `<简称>-REQ-<序号>`（如 `网资-REQ-001`） |
| 验收标准 | 3-8 条 GWT，覆盖正常路径 + 异常路径 + 边界场景 |
| 关联 Feature / 关联需求 | frontmatter refs 含 `implements`（Feature）与 `addresses`（台账条目）；正文含块引用 wikilink |

### 2.2 Frontmatter 规范

User Story 文档：

```yaml
---
id: "网资-EPIC-F01-S01"
product: "网资：网络资源全生命周期管理"
type: "用户故事"
capability: "设备领用能力"
aliases:
  - 设备领用能力 创建模型配置
journey_stage: "建址-审核核准"
tags:
  - 网资
  - 用户故事
  - 设备领用能力
---
```

`journey_stage` 必须属于已确认旅程叙事线节点（见 `guides/journey-extraction.md` 第 3 节）。存量 Story 过程空间 frontmatter（`refs` 等）渲染进产品库时由渲染脚本剥离，产品库 Story 只保留上述产品库字段；`addresses` 边以 `refs.json` edges 维护。

### 2.3 正文关联需求段落

每条 Story 正文必须包含「关联需求」段落，使用 Obsidian 文件链接 + 条目ID 显示文案指向需求台账具体条目（条目是台账表格中的一行，不使用块锚点）：

```markdown
本故事落实 [[网资-需求台账|网资-REQ-001]]。
```

格式：`[[<简称>-需求台账|<条目ID>]]`，`<条目ID>` 为 `<简称>-REQ-<序号>`。禁止用过程 ID、英文编号或裸条目 ID 作为链接文案。

### 2.4 ID 分配规则

遵循 `../shared/traceability-model.md` 的统一规范，使用继承式产品库 ID（`<简称>-EPIC-F<nnn>-S<nnn>`）：

1. 落盘前扫描产品库中当前能力的故事文档（`<产品目录>/<能力路径>/用户故事/*.md`）的 frontmatter ID。
2. 按文档类型取已使用的最大**两位**序号再加一（如已有 `网资-EPIC-F01-S01` 和 `网资-EPIC-F01-S03`，下一个是 `网资-EPIC-F01-S04`）。
3. ID 一经分配不得复用；更新现有文档时沿用原 ID。
4. 文件名使用产品库文件名格式（如 `网资-设备领用能力-创建模型配置故事.md`）。
5. Story 需登记 `addresses` 边（`Story addresses 台账条目`），与 `requirementEntryId` 及正文块引用一致。

## 3. 溯源矩阵文档

文件路径：`docs/requirement-analysis/matrix-<nnn>.md`。矩阵覆盖多个 Feature，因此位于需求分析目录根层，不归属任何单一 Feature 子目录。

| 字段 | 内容要求 |
| ---- | -------- |
| Feature 列表 | ID、名称、优先级、状态，覆盖所有需拆解的 Feature |
| Story 列表 | ID、标题、角色、优先级、Story Points，并新增**旅程阶段**（`journey_stage`）与**需求台账条目**（`requirementEntryId`）两列，覆盖所有已拆解的 Story |
| 映射关系 | Story ID -> 实现 Feature ID + 覆盖度（完整/部分），每条 Story 必须映射到至少一个 Feature |
| 覆盖度检查 | 每个 Feature 至少被一条 Story 实现；所有高优先级（P0）Feature 已覆盖；每条 Story 都能回溯到台账条目 |

溯源矩阵 frontmatter：

```yaml
---
id: "matrix-001"
type: "traceability-matrix"
projectId: "<project-id>"
title: "Story-Feature 溯源矩阵"
status: "draft"
refs:
  - id: "<feature-id>"
    relation: "references"
---
```

## 4. 故事地图产出契约

### 4.1 能力级地图结构

**能力定位**：引用块，从能力文档提取：能力名称、能力描述、所属类别。

**用户旅程叙事线**：一段文字描述该能力内的子旅程（节点来自业务场景表 SC-XX 推导）：

```
{能力名}旅程：{节点1} -> {节点2} -> {节点3} -> ...
```

**2D 故事地图矩阵**：**核心章节**。Markdown 表格，列 = 能力内旅程节点（从左到右），行 = 优先级。每个单元格包含完整故事卡片：

```
⭐[[故事文件名|故事简称]]
- 角色：{角色}
- 核心价值：{一句话价值}
- 叙事位置：{来自 Story 的 journey_stage}
```

**跨能力关联标注**：列出该能力与其他能力的衔接关系（简表）。

### 4.2 文件 Frontmatter

能力级地图：

```yaml
---
product: "{产品名}"
type: "指南"
capability: "{能力名}"
tags:
  - 用户故事地图
  - "{能力名}"
title: "{产品名}-{能力名}能力-用户故事地图"
---
```

## 5. 草稿预览格式

`mode=draft` 的草稿预览必须与后续 `mode=persist` 的正式文件同结构、同字段、同正文内容。不得输出摘要版草稿。

草稿预览在对话中完整展示，包括分组 Story 草稿（三块内容 + `journey_stage`/`requirementEntryId`）和所有 2D 矩阵表格与故事卡片。

## 6. 文件命名映射规则

故事地图中的 wikilink 必须使用产品库中实际的文件名（不含 `.md` 后缀）。如果故事文件名与故事地图中的引用名不一致，以产品库实际文件名为准。

映射规则：
1. 扫描产品库中 `<能力路径>/用户故事/` 目录下的实际故事文件名。
2. 能力级地图中的 wikilink 使用实际文件名（去除 `.md` 后缀和路径前缀）。
3. 如果实际文件名过长，使用 `[[文件名|显示名]]` 语法，显示名为简短别名。

## 7. 草稿状态与恢复

`mode=draft` 的唯一过程状态源是每条已选 Story 的 `docs/_extracted/.stories/story-<nnn>.json`，以及 `phase-summary.md` 中的旅程叙事线章节。它同时保存可落盘的 Story/AC 顶层字段（含 `journey_stage`、`requirementEntryId`）以及 `interview` 内的润色 Q&A、事实核查、决策树、强制跳过项和共同理解状态。字段与更新顺序由 `grilling-protocol.md` 定义，本文件不重复其 schema。

- 每个顶层 Story/AC 字段都必须能追溯到已确认决策或已核实事实；用户尚未确认的内容不得写成最终值。
- 每个 Story 与每条 AC 的状态均以 JSON 为准：`pending` 或 `confirmed`；决策节点额外允许且仅允许在用户明确选择时标为 `forced-skip`。
- 会话恢复时，先读匹配的 Story JSON 与 `phase-summary.md` 旅程叙事线，从 `interview.current_node` 的已满足依赖之后继续；不得重问已确认节点。
- 生成完整草稿或落盘预览时，正文必须从 JSON 的顶层字段生成，与后续脚本渲染同字段、同正文内容；不得用对话摘要替代。
- `interview` 是草稿元数据，`render-story.sh` 忽略它。落盘确认前不得删除或重写其中已确认的审阅记录。

## 8. 记忆更新

落盘后更新以下文件：

| 文件 | 更新内容 |
| ---- | -------- |
| `refs.json` | 注册新文档节点（story-*/matrix-*，`path` 指向产品库路径，含 `libraryId`/`contentHash`/`lastSynced`）和引用边（Story `implements` Feature、Story `addresses` 台账条目、Matrix `references` Feature） |
| `facts.json` | 记录已确认的角色、规则、流程步骤、旅程节点等结构化事实 |
| `decision-log.md` | 记录 Story 拆分方案、颗粒度调整、旅程阶段划分、优先级排序等决策及理由 |
| `tracking-log.md` | 记录依赖关系、未验证假设、新发现的风险和未决问题 |
| `phase-summary.md` | 维护旅程叙事线（节点白名单、能力映射、变更记录）并追加本阶段恢复摘要：产物清单（Story 数量、矩阵、地图）、关键拆分决策、遗留问题和下一步。摘要随写 `phase_status`（供 `references/phase-navigator.md` 读取）：旅程叙事线增量写入时 `draft`，本阶段全部产出落盘（`persisted`）后 `persisted` |
| `progress.json` | 仅更新当前阶段和顶层 `lastUpdated`；不修改 `workflow.state`、顶层 `status` 或阶段转换字段 |

## 9. 落盘完成后的去向

本批 Story、溯源矩阵与故事地图落盘完成并返回 `persisted` 后，本阶段产物已在产品库与过程项目中就绪。**主调度器确认后，可推进 `detailed-design` 或 `sprint-planning` 阶段**；本 agent 不自行跳转或推进 `workflow.state`，去向由主调度器按阶段转换协议处理。