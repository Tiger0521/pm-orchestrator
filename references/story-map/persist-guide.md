# 落盘指南

本文件仅在 `mode=persist` 时读取。`workflow.md` 第 5 步引用本文件执行落盘流程。

当 `mode=persist` 时，将用户已确认的 Story、溯源矩阵和故事地图全部写入。落盘不是自动发生的，而是由主调度器在用户确认后以 `mode=persist` 重新调用时执行。**严禁 AI 用 Write 工具逐行写 Story/矩阵 Markdown，必须走脚本**。

---

## 落盘步骤

1. 确认用户已看过并确认完整 Story 落盘预览、溯源矩阵草稿和地图方案（能力级）。
2. 确认所有 Story、AC 和 `interview.decision_tree` 中的适用节点均为 `confirmed`，或具备用户明确选择的 `forced-skip`；`shared_understanding` 的相关决策组必须均为 `confirmed`。
3. 确认所有 Story 已通过写作规范自检（见 `writing-paradigm/user-story-writing.md` 落盘前自检清单），顶层可渲染字段与用户确认的预览逐项一致（含 `journey_stage`、`requirementEntryId`）。
4. 读取并校验 draft 已创建的 `docs/_extracted/.stories/story-<nnn>.json`；不得在 `mode=persist` 新建、改写或删除 Story 的 `interview`、Q&A 或已确认字段。详细状态 schema 见 `grilling-protocol.md`。
5. 将已确认的溯源矩阵数据写入 `docs/_extracted/.stories/matrix-<nnn>.json`。
6. 调用 `render-story.sh` 批量渲染已校验的 Story JSON 为 Markdown，写入产品库 `<能力路径>/用户故事/`：
   ```bash
   bash "<skillPath>/scripts/render-story.sh" \
     "<projectPath>/docs/_extracted/.stories/" \
     "<selectedProductLibraryPath>/<产品全名>/" \
     "<产品简称>" "<产品全名>" "[能力路径]"
   ```
   脚本自动完成：按继承式产品库 ID 规则分配或复用 ID（`<简称>-EPIC-F<nnn>-S<nnn>`）、从每条 Story 的 `featureId` 确定唯一归属、渲染 Markdown 到产品库 `<能力路径>/用户故事/` 目录，并自动运行 `validate-story.sh` 做写作规范校验。**一次调用只渲染单一能力路径下的 Story**：`.stories/` 目录若混有多 Feature 的 Story，必须按 `featureId` 分组后逐能力路径分别调用；渲染脚本会对缺少规范 `featureId`（`feature-<nnn>`）的 Story 输出 WARN，出现时需回填后再渲染。渲染输出的每份 Story frontmatter 与正文必须包含 `journey_stage` 与关联需求文件链接（结构见 `output-contract.md` 第 2 节与 `templates/user-story.md`）。
7. 调用 `render-matrix.sh` 渲染溯源矩阵到过程项目（第三个参数 `产品简称` 决定正文用产品库 wikilink 还是原始过程 ID，必须与 render-story 使用同一简称）：
   ```bash
   bash "<skillPath>/scripts/render-matrix.sh" \
     "<projectPath>/docs/_extracted/.stories/matrix-<nnn>.json" \
     "<projectPath>/docs/requirement-analysis/" \
     "<产品简称>"
   ```
   溯源矩阵留在过程项目 `docs/requirement-analysis/matrix-<nnn>.md`，但正文中的文档引用使用产品库文件名格式（如 `[[网资-设备领用能力-能力文档]]`），不使用过程 ID。wikilink 由矩阵 JSON 的 `feature_N_name` 拼接，**`feature_N_name` 必须填能力路径**（与 render-doc 的 `capability_path`、Story 渲染所取能力路径一致，层级用 `/` 分隔），否则生成的 wikilink 会与实际文件名脱节。矩阵 Story 列表必须含旅程阶段与需求台账条目列（数据来自各 Story JSON 的 `journey_stage`/`requirementEntryId`）；若当前渲染脚本未覆盖这两列，先修 JSON 字段并确认脚本产出符合 `templates/traceability-matrix.md` 结构。
8. 写入故事地图：按 `output-contract.md` 第 4 节与已确认的地图方案，将能力级地图写入产品库 `用户故事地图/` 目录（文件命名 `{产品名}-{能力名}能力-用户故事地图.md`）。地图从已确认 Story 的 `journey_stage` 组装，逐能力落盘；写后校验地图 wikilink 指向的 Story 与能力级地图文件实际存在。
9. **校验硬门禁**：`render-story.sh` 渲染完成后自动运行 `validate-story.sh`。有 `[WARN]` 项时必须修复对应 Story JSON 中的字段格式，重新渲染，直到零警告才能报告 `persisted`。不得跳过校验、不得忽略警告。
10. 更新记忆文件（范围见下方"记忆更新表"），并更新 `progress.json`：仅更新当前阶段和顶层 `lastUpdated`，不得修改 `workflow.state`、顶层 `status` 或阶段转换字段。

---

## Story JSON 结构

每个 Story 对应一个 JSON 文件，字段结构如下：

Story JSON 在 `mode=draft` 已被创建并持续更新，是唯一过程状态源。除下列渲染字段外，它还必须保留 `interview` 元数据（润色 Q&A、事实核查、决策树、强制跳过项和共同理解状态）；完整 schema 与写入规则只见 `grilling-protocol.md`，避免与该文件重复。`render-story.sh` 忽略 `interview`。

```json
{
  "id": "story-001",
  "type": "user-story",
  "projectId": "<project-id>",
  "title": "创建模型配置",
  "featureId": "feature-001",
  "role": "算法工程师",
  "goal": "创建新的模型配置",
  "value": "快速启用模型进行实验，无需手动编辑配置文件",
  "priority": "P0",
  "journey_stage": "建址-审核核准",
  "requirementEntryId": "网资-REQ-001",
  "storyPoints": "3",
  "acCount": "4",
  "ac_1_keyword": "成功创建",
  "ac_1_given": "算法工程师已登录系统",
  "ac_1_when": "填写模型名称、版本、参数并点击提交",
  "ac_1_then": "系统创建配置并返回成功提示\"创建成功\"",
  "ac_2_keyword": "必填项校验",
  "ac_2_given": "算法工程师未填写模型名称",
  "ac_2_when": "点击提交按钮",
  "ac_2_then": "系统提示\"模型名称不能为空\"并阻止提交",
  "ac_3_keyword": "重复名称",
  "ac_3_given": "已存在名称为\"v1\"的配置",
  "ac_3_when": "再次创建名称为\"v1\"的配置并提交",
  "ac_3_then": "系统提示\"配置名称已存在\"并阻止提交",
  "ac_4_keyword": "权限不足",
  "ac_4_given": "普通用户（非算法工程师）已登录",
  "ac_4_when": "尝试访问配置创建页面",
  "ac_4_then": "系统提示\"无操作权限\"并隐藏创建入口",
  "interview": {}
}
```

顶层字段必须包含 `journey_stage`（已验证叙事线节点）与 `requirementEntryId`（台账条目 ID），二者是渲染关联段落与地图组装的直接输入。

---

## 溯源矩阵 JSON 结构

```json
{
  "id": "matrix-001",
  "type": "traceability-matrix",
  "projectId": "<project-id>",
  "title": "Story-Feature 溯源矩阵",
  "featureCount": "1",
  "feature_1_id": "feature-001",
  "feature_1_name": "模型配置管理",
  "feature_1_priority": "P0",
  "feature_1_status": "approved",
  "storyCount": "2",
  "story_1_id": "story-001",
  "story_1_title": "创建模型配置",
  "story_1_role": "算法工程师",
  "story_1_priority": "P0",
  "story_1_journey": "建址-审核核准",
  "story_1_req_entry": "网资-REQ-001",
  "story_1_sp": "3",
  "story_2_id": "story-002",
  "story_2_title": "查看模型配置列表",
  "story_2_role": "算法工程师",
  "story_2_priority": "P0",
  "story_2_journey": "建址-录入导入",
  "story_2_req_entry": "网资-REQ-002",
  "story_2_sp": "2",
  "mappingCount": "2",
  "mapping_1_story": "story-001",
  "mapping_1_feature": "feature-001",
  "mapping_1_coverage": "完整",
  "mapping_2_story": "story-002",
  "mapping_2_feature": "feature-001",
  "mapping_2_coverage": "完整"
}
```

Story 列表的旅程阶段（`story_N_journey`）与需求台账条目（`story_N_req_entry`）两列必须与对应 Story JSON 的顶层字段一致。

---

## 故事地图落盘规则

### 确认落盘目标

地图方案在 draft 阶段已确认：逐个能力确认能力级地图。persist 阶段按确认结果写入 `用户故事地图/` 目录：
- 能力级地图：`{产品名}-{能力名}能力-用户故事地图.md`

### 写入规则

- 只写入用户已确认的内容，不得重新生成、改写、压缩或扩写。
- 产品库中没有 `用户故事地图/` 目录时创建该目录。
- 文件编码使用 UTF-8；换行符使用 LF。
- frontmatter 中的字段值使用双引号包裹。
- wikilink 使用 `[[文件名|显示名]]` 格式，文件名不含 `.md` 后缀。
- 地图中的故事卡片与旅程列来自已落盘 Story 的 `journey_stage`。

### 覆盖已有文件

如果产品库 `用户故事地图/` 目录中已存在同名文件：
- 向用户确认是否覆盖。
- 确认覆盖后写入新文件。
- 不保留旧文件备份（由用户自行管理版本控制）。

---

## 记忆更新表

| 文件 | 更新内容 |
| ---- | -------- |
| `refs.json` | 注册新节点（story-*/matrix-*，`path` 指向产品库路径，含 `libraryId`/`contentHash`/`lastSynced`）与引用边（Story `implements` Feature、Story `addresses` 台账条目 `requirementEntryId`、Matrix `references` Feature） |
| `facts.json` | 记录已确认的角色、规则、流程步骤、旅程节点等结构化事实 |
| `decision-log.md` | 记录 Story 拆分方案、颗粒度调整、旅程阶段划分、优先级排序等决策及理由 |
| `tracking-log.md` | 记录依赖关系、未验证假设、新发现的风险和未决问题 |
| `phase-summary.md` | 维护旅程叙事线（节点白名单、能力映射、变更记录）并追加本阶段摘要（产物清单：Story 数量、矩阵、地图）。摘要随写 `phase_status`（供 `references/phase-navigator.md` 读取）：本阶段全部产出落盘后 `persisted` |
| `progress.json` | 仅更新当前阶段和顶层 `lastUpdated`；不修改 `workflow.state`、顶层 `status` 或阶段转换字段 |

---

## 落盘后汇报

落盘完成后，向主调度器返回 `status=persisted`，并在回执中包含：

- 已写入的 Story 数量、矩阵文件与能力级地图文件
- `journey_stage`/`requirementEntryId` 回填与 `addresses` 边注册情况
- `validate-story.sh` 校验结果（必须零警告）
- 下一步提示：产品库 Story、过程项目矩阵与产品库地图均已就绪，主调度器确认后可推进 detailed-design 或 sprint-planning