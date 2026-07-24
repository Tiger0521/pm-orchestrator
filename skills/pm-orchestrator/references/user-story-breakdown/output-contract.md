# 需求拆解产出契约

本文件在需要生成完整草稿预览、执行 `mode=persist`、或核对正式产物字段时读取。

## 产出文档

需求拆解阶段产出两类正式文档：User Story（用户价值层）和溯源矩阵（追溯层）。每份文档通过 frontmatter 建立追溯关系，落盘到 `docs/design/` 目录。

### User Story 文档

文件路径：`docs/design/story-<nnn>.md`

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

文件路径：`docs/design/matrix-<nnn>.md`

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

1. 落盘前同时扫描 `refs.json.nodes` 和 `docs/design/` 目录中的 frontmatter ID。
2. 按文档类型取已使用的最大三位序号再加一（如已有 `story-001` 和 `story-003`，下一个是 `story-004`）。
3. ID 一经分配不得复用；更新现有文档时沿用原 ID。
4. 文件名必须与 ID 一致（如 `story-004` 写入 `story-004.md`）。

## 草稿状态追踪

draft 模式下，每轮产出的 Story 草稿必须结构化输出，包含以下数据块，作为会话恢复的中间状态：

```text
## Story 草稿数据块

### Story: <Story 标题>
- 三段式: "作为 **<角色>**，我想要 **<活动>**，以便于 **<价值>**"
- 优先级: P0 / P1 / P2
- Story Points: <建议值>
- 确认状态: pending / confirmed
- 关联 Feature: <feature-id>

#### 验收标准
1. **<场景关键词>**：Given ... When ... Then ...
2. **<场景关键词>**：Given ... When ... Then ...
```

确认状态追踪：每条 Story 和每条 AC 独立标记 `pending` 或 `confirmed`。用户确认的内容从 `pending` 翻转为 `confirmed`；用户提出修改的内容保持 `pending` 并记录修改方向。确认状态是草稿数据块的一部分，draft 模式下每轮返回时同步更新。

会话恢复：如果会话中断，主调度器可读取上一轮对话中的 Story 草稿数据块（含确认状态），以 `mode=draft` 重新委派，subagent 恢复已确认的 Story 和 AC，只继续未确认部分。不需要重新从上游 Feature 开始拆解。

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
