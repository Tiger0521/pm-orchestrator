# 追溯模型

本文档定义 pm-orchestrator 项目中所有文档之间的引用关系类型、ID 规范以及 `refs.json` 的结构规范。

---

## 文档节点类型

| 类型 | 说明 | 典型 ID 前缀 |
|------|------|-------------|
| `requirement-card` | 需求卡片：问题本质 + 方案定位 | `req-` |
| `epic` | Epic：战略层能力单元 | `epic-` |
| `feature` | Feature：需求层能力单元 | `feature-` |
| `user-story` | User Story：用户价值单元 | `story-` |
| `traceability-matrix` | Story-Feature 溯源矩阵 | `matrix-` |
| `structure-flow` | 结构与流程图文档 | `flow-` |
| `prototype` | 原型文档 | `proto-` |
| `interaction-contract` | 交互契约 | `contract-` |
| `rules-summary` | 规则摘要 | `rules-` |
| `sprint` | Sprint 规划 | `sprint-` |

---

## 引用关系类型

| 关系 | 含义 | 方向 |
|------|------|------|
| `derived-from` | 派生自 | 下游文档 → 上游文档 |
| `belongs-to` | 归属于 | 子文档 → 父文档 |
| `implements` | 实现 | 实现文档 → 被实现文档 |
| `contains` | 包含 | 容器文档 → 成员文档 |
| `references` | 一般引用 | 任意 → 任意 |

标准追溯链：

```
Epic ──derived-from──▶ 需求卡片
Feature ──belongs-to────▶ Epic
Feature ──references────▶ 需求卡片
User Story ──implements──▶ Feature
原型/契约 ──implements──▶ User Story
Sprint   ──contains─────▶ User Story
```

---

## refs.json 结构

```json
{
  "projectId": "<project-id>",
  "lastUpdated": "<timestamp>",
  "nodes": [
    {
      "id": "epic-001",
      "type": "epic",
      "title": "...",
      "path": "docs/requirement-analysis/epic-001.md",
      "status": "approved"
    }
  ],
  "edges": [
    {
      "from": "feature-001",
      "to": "epic-001",
      "relation": "belongs-to"
    }
  ]
}
```

---

## Frontmatter 规范

每份产出文档统一包含以下 frontmatter：

```yaml
---
id: "<doc-id>"
type: "<doc-type>"
projectId: "<project-id>"
title: "<文档标题>"
status: "draft | review | approved"
refs:
  - id: "<上游文档id>"
    relation: "<relation-type>"
---
```

需求卡片是追溯链起点，允许 `refs: []`。Epic 必须通过 `derived-from` 引用需求卡片；Feature 必须通过 `belongs-to` 引用 Epic，并可通过 `references` 回引需求卡片。

正文中引用其他文档使用 `[@doc-id]` 语法，例如：

```markdown
本 Feature 属于 [@epic-001]，解决的需求卡片见 [@req-001]。
```

---

## 注册时机

每次产出新文档或更新文档状态时，同步更新 `refs.json`：

1. 添加/更新节点（id、type、title、path、status）
2. 添加/更新 edges（from、to、relation）
3. 更新 `lastUpdated`
