# 需求拆解产出契约

本文件在需要生成完整草稿预览、执行 `mode=persist`、或核对正式产物字段时读取。

## 产出文档

需求拆解阶段产出两类正式文档：User Story（用户价值层）和溯源矩阵（追溯层）。每份文档通过 frontmatter 建立追溯关系，落盘到 `docs/requirement-analysis/`，并与上游 Feature 同层管理。

### User Story 文档

文件路径：`docs/requirement-analysis/feature-<feature-nnn>/story-<nnn>.md`。每条 Story 必须写入其唯一 `implements` 引用所指 Feature 的子目录；不得写入 `docs/design/`、`docs/requirement-analysis/` 根层或其他 Feature 的目录。

| 字段 | 内容要求 |
| ---- | -------- |
| Story 标题 | 用业务语言概括用户目标，不是技术操作名 |
| 三段式描述 | “作为 [角色]，我想要 [目标]，以便于 [价值]”，角色具体、活动描述用户意图、价值清晰合理 |
| 优先级 | P0 / P1 / P2，继承自 Feature 优先级，可在同 Feature 内调整 |
| Story Points 建议 | 1 / 2 / 3 / 5 / 8 / 13，附注“建议值，待团队确认” |
| 验收标准 | 3-8 条 GWT，覆盖正常路径 + 异常路径 + 边界场景 |
| 关联 Feature | 通过 frontmatter `refs` 的 `implements` 关系回引 Feature |

每条 Story 可独立文件，也可合并为清单。独立文件便于版本管理和 Sprint 分配；合并文件适合 Story 数量较少（≤3 条）的 Feature。

### 溯源矩阵文档

文件路径：`docs/requirement-analysis/matrix-<nnn>.md`。矩阵覆盖多个 Feature，因此位于需求分析目录根层，不归属任何单一 Feature 子目录。

| 字段 | 内容要求 |
| ---- | -------- |
| Feature 列表 | ID、名称、优先级、状态，覆盖所有需拆解的 Feature |
| Story 列表 | ID、标题、角色、优先级、Story Points，覆盖所有已拆解的 Story |
| 映射关系 | Story ID -> 实现 Feature ID + 覆盖度（完整/部分），每条 Story 必须映射到至少一个 Feature |
| 覆盖度检查 | 每个 Feature 至少被一条 Story 实现；所有高优先级（P0）Feature 已覆盖 |

### Frontmatter 规范

User Story 文档：

```yaml
---
id: "story-001"
type: "user-story"
projectId: "<project-id>"
title: "<Story 标题>"
status: "draft"
refs:
  - id: "<feature-id>"
    relation: "implements"
---
```

溯源矩阵文档：

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

### ID 分配规则

遵循 `../shared/traceability-model.md` 的统一规范：

1. 落盘前同时扫描 `refs.json.nodes`、`docs/requirement-analysis/matrix-*.md` 和 `docs/requirement-analysis/feature-*/story-*.md` 中的 frontmatter ID。
2. 按文档类型取已使用的最大三位序号再加一（如已有 `story-001` 和 `story-003`，下一个是 `story-004`）。
3. ID 一经分配不得复用；更新现有文档时沿用原 ID。
4. 文件名必须与 ID 一致（如 `story-004` 写入 `story-004.md`）。

## 草稿状态与恢复

`mode=draft` 的唯一过程状态源是每条已选 Story 的 `docs/_extracted/.stories/story-<nnn>.json`。它同时保存可落盘的 Story/AC 顶层字段，以及 `interview` 内的润色 Q&A、事实核查、决策树、强制跳过项和共同理解状态。字段与更新顺序由 `grilling-protocol.md` 定义，本文件不重复其 schema。

- 每个顶层 Story/AC 字段都必须能追溯到已确认决策或已核实事实；用户尚未确认的内容不得写成最终值。
- 每个 Story 与每条 AC 的状态均以 JSON 为准：`pending` 或 `confirmed`；决策节点额外允许且仅允许在用户明确选择时标为 `forced-skip`。
- 会话恢复时，先读匹配的 Story JSON，从 `interview.current_node` 的已满足依赖之后继续；不得重问已确认节点。
- 生成完整草稿或落盘预览时，正文必须从 JSON 的顶层字段生成，与后续脚本渲染同字段、同正文内容；不得用对话摘要替代。
- `interview` 是草稿元数据，`render-story.sh` 忽略它。落盘确认前不得删除或重写其中已确认的盘问记录。

## 记忆更新

落盘后更新以下文件：

| 文件 | 更新内容 |
| ---- | -------- |
| `refs.json` | 注册新文档节点（story-*/matrix-*）和引用边（Story implements Feature、Matrix references Feature） |
| `facts.json` | 记录已确认的角色、规则、流程步骤等结构化事实 |
| `decision-log.md` | 记录 Story 拆分方案、颗粒度调整、优先级排序等决策及理由 |
| `tracking-log.md` | 记录依赖关系、未验证假设、新发现的风险和未决问题 |
| `phase-summary.md` | 追加本阶段恢复摘要：产物清单（Story 数量、矩阵）、关键拆分决策、遗留问题和下一步 |
| `progress.json` | 仅更新当前阶段和顶层 `lastUpdated`；不修改 `workflow.state`、顶层 `status` 或阶段转换字段 |
