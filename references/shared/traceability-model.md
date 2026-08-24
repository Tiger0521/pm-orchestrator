# 追溯模型

本文档定义 pm-orchestrator 项目中所有文档之间的引用关系类型、ID 规范以及 `refs.json` 的结构规范。

---

## 文档节点类型

| 类型 | 说明 | 典型 ID 前缀 |
|------|------|-------------|
| `requirement-card` | 需求卡片：问题本质 + 方案定位 | `req-` |
| `diagnostic-report` | 诊断报告：四个核心判断 + 证据缺口 + 成熟度 | `diagnostic-` |
| `epic` | Epic：战略层能力单元 | `epic-` |
| `feature` | Feature：需求层能力单元 | `feature-` |
| `user-story` | User Story：用户价值单元 | `story-` |
| `traceability-matrix` | Story-Feature 溯源矩阵 | `matrix-` |
| `structure-flow` | 结构与流程图文档 | `flow-` |
| `prototype` | 原型文档 | `proto-` |
| `interaction-contract` | 交互契约 | `contract-` |
| `rules-summary` | 规则摘要 | `rules-` |
| `sprint` | 迭代规划 | `sprint-` |

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
      "path": "product-library/<产品库名>/<产品全名>/网资-设计文档.md",
      "libraryId": "网资-EPIC",
      "contentHash": "a3f5c2e1b9d8...",
      "lastSynced": "2026-08-14T10:30:00"
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

- `id`：过程空间 ID（`req-001`、`epic-001` 等），注册时分配。
- `path`：指向产品库路径（不再指向过程空间 `docs/`）。
- `libraryId`：产品库继承式 ID，persist 时建立映射。
- `contentHash`：文件全文 SHA-256 哈希，由对账脚本计算并更新。
- `lastSynced`：上次同步时间戳。

恢复已有项目时必须先运行对账脚本（`product-library-tools.mjs reconcile`），由脚本扫描产品库、计算哈希、与 `refs.json` 中的 `contentHash` 比对并输出变更报告；AI 只读报告标记为 `changed`/`new` 的文档，跳过 `unchanged`。

---

## Frontmatter 规范

### 过程空间 frontmatter

过程空间文档（草稿态数据、项目记忆文件）统一包含以下 frontmatter：

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

### 产品库 frontmatter

产品库文档统一包含以下 frontmatter：

```yaml
---
id: "<继承式产品库ID>"
product: "<产品全名>"
type: "<需求卡片 | 设计文档 | 能力文档 | 用户故事 | 结构流程图 | 原型 | 交互契约 | 规则摘要 | 迭代规划>"
capability: "<能力路径>"
aliases:
  - <别名>
tags:
  - <标签>
---
```

- `id`：继承式产品库 ID（格式见下文"产品库 ID"章节），不是过程 ID。
- `product`：产品全名。
- `type`：`需求卡片 | 设计文档 | 能力文档 | 用户故事 | 结构流程图 | 原型 | 交互契约 | 规则摘要 | 迭代规划`。
- `capability`：能力文档和用户故事必填，需求卡片、设计文档和详细设计五类（结构流程图/原型/交互契约/规则摘要/迭代规划）无此字段。
- `aliases`/`tags`：YAML 列表，由渲染脚本注入。
- 产品库不得保留过程空间的 `projectId`、`refs` 或 `status`。

## ID 分配规则

1. 模板中的 ID 都是占位符，不是固定值。
2. 落盘前同时扫描 `refs.json.nodes` 和目标目录中的 frontmatter ID。
3. 按文档类型取已使用的最大三位序号再加一，例如已有 `feature-001` 和
   `feature-003` 时，下一个是 `feature-004`。
4. ID 一经分配不得复用；更新现有文档时沿用原 ID。
5. 写入前再次检查 ID、目标路径和 `refs.json` 节点均无冲突；发现冲突时停止写入并重新分配。
6. 产品库文件名使用**全中文**描述性名称（产品简称 + 中文类型名），不含英文与序号；不使用 ID。英文只允许出现在**文档内部**的 ID 上：frontmatter `id` 字段，或正文中的业务/规则编号（如 `US-01`、`BR-01`、`网资-DF-CONTRACT01`）。ID 仅存于 frontmatter `id` 字段，通过该字段定位已有文档。

正文中跨文档引用一律使用 Obsidian wikilink `[[产品库中文文件名]]`（文件名不带 `.md` 后缀，可用 `[[文件名|显示名]]`），指向产品库实际文件名，例如：

```markdown
本 Epic 派生自 [[网资-需求卡片]]，见 [[网资-设计文档]]。
```

禁止用过程 ID、英文编号或相对路径作为链接文案（错误示例 `[[epic-001]]`、`[[req-001]]`）；英文 ID 只出现在 frontmatter `id` 字段或正文业务/规则编号上。机器溯源链仍由 frontmatter `refs` + `refs.json` 维护，与正文 Obsidian 链接解耦。

---

## 产品库 ID

产品库文档使用继承式 ID，与过程空间 ID 独立。

### 格式

| 文档类型 | ID 格式 | 示例 |
|---|---|---|
| 需求卡片 | `<简称>-REQ` | `网资-REQ` |
| 设计文档(Epic) | `<简称>-EPIC` | `网资-EPIC` |
| 能力文档(Feature) | `<简称>-EPIC-F<nnn>` | `网资-EPIC-F01` |
| 用户故事 | `<简称>-EPIC-F<nnn>-S<nnn>` | `网资-EPIC-F01-S01` |
| 结构与流程图 | `<简称>-DF-FLOW<nnn>` | `网资-DF-FLOW01` |
| 原型 | `<简称>-DF-PROTO<nnn>` | `网资-DF-PROTO01` |
| 交互契约 | `<简称>-DF-CONTRACT<nnn>` | `网资-DF-CONTRACT01` |
| 规则摘要 | `<简称>-DF-RULES<nnn>` | `网资-DF-RULES01` |
| 迭代规划 | `<简称>-DF-SPRINT<nnn>` | `网资-DF-SPRINT01` |

`DF` 前缀（Design Detail）隔离详细设计序号空间，避免与 `EPIC-F<nnn>` 冲突。详细设计五类序号在产品库内按类型独立递增。

### 分配规则

1. persist 时由渲染脚本分配。
2. 扫描产品库中当前产品的同类型文档，取最大序号 +1。
3. ID 一经分配不变；更新现有文档时沿用原 ID。
4. 通过 frontmatter `id` 字段定位已有文档，不依赖文件名。

### 文件名规范

产品库文件名使用中文描述性名称（产品简称 + 类型名），不使用 ID。ID 仅存于 frontmatter `id` 字段。

| 文档类型 | 文件名格式 | 示例 |
|---|---|---|
| 需求卡片 | `<简称>-需求卡片.md` | `网资-需求卡片.md` |
| 设计文档(Epic) | `<简称>-设计文档.md` | `网资-设计文档.md` |
| 能力文档(Feature) | `<简称>-<能力路径>-能力文档.md` | `网资-设备管理能力-能力文档.md` |
| 结构与流程图 | `<简称>-结构与流程图.md` | `网资-结构与流程图.md` |
| 原型交互说明 | `<简称>-原型交互说明.md` | `网资-原型交互说明.md` |
| 交互契约 | `<简称>-交互契约.md` | `网资-交互契约.md` |
| 规则摘要 | `<简称>-规则摘要.md` | `网资-规则摘要.md` |
| 迭代规划 | `<简称>-迭代规划.md` | `网资-迭代规划.md` |

Step 1 草稿即正式机制下的独立 md 文档和 HTML 图文件命名见 `../detailed-design/shared/persist-guide.md` 第 2 节。

### 与过程 ID 的关系

- 过程空间仍使用 `req-001`、`epic-001` 等过程 ID，记录在 `refs.json` 的 `id` 字段中。
- 产品库 ID 记录在 `refs.json` 的 `libraryId` 字段中。
- persist 时建立过程 ID 到产品库 ID 的映射。

---

## 注册时机

每次产出新文档或更新文档状态时，同步更新 `refs.json`：

1. 添加/更新节点（id、type、title、path、status）
2. 添加/更新 edges（from、to、relation）
3. 更新 `lastUpdated`
4. 校验节点 ID 唯一、节点路径唯一、边的两端节点存在，且 frontmatter `refs`
   与 `edges` 一致
