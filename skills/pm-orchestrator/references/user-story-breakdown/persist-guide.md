# 落盘指南

本文件仅在 `mode=persist` 时读取。`workflow.md` 第 6 步引用本文件执行落盘流程。

当 `mode=persist` 时，将用户已确认的 Story 和溯源矩阵写入文件。落盘不是自动发生的，而是由主调度器在用户确认后以 `mode=persist` 重新调用时执行。**严禁 AI 用 Write 工具逐行写文件，必须走脚本**。

---

## 落盘步骤

1. 确认用户已看过并确认完整 Story 落盘预览和溯源矩阵草稿。
2. 确认所有 Story、AC 和 `interview.decision_tree` 中的适用节点均为 `confirmed`，或具备用户明确选择的 `forced-skip`；`shared_understanding` 的相关决策组必须均为 `confirmed`。
3. 确认所有 Story 已通过写作规范自检（见 `writing-paradigm/user-story-writing.md` 落盘前自检清单），且顶层可渲染字段与用户确认的预览逐项一致。
4. 读取并校验 draft 已创建的 `docs/_extracted/.stories/story-<nnn>.json`；不得在 `mode=persist` 新建、改写或删除 Story 的 `interview`、Q&A 或已确认字段。详细状态 schema 见 `grilling-protocol.md`。
5. 将已确认的溯源矩阵数据写入 `docs/_extracted/.stories/matrix-<nnn>.json`。
6. 调用 `render-story.sh` 批量渲染已校验的 Story JSON 为 Markdown：
   ```bash
   bash "<skillPath>/scripts/render-story.sh" \
     "<projectPath>/docs/_extracted/.stories/" \
     "<projectPath>/docs/requirement-analysis/"
   ```
   脚本自动完成：按全项目 ID 规则分配或复用 ID、从每条 Story 的 `featureId` 确定唯一归属、渲染 Markdown 到 `docs/requirement-analysis/feature-<feature-nnn>/story-<nnn>.md`，并自动运行 `validate-story.sh` 做写作规范校验。
7. 调用 `render-matrix.sh` 渲染溯源矩阵：
   ```bash
   bash "<skillPath>/scripts/render-matrix.sh" \
     "<projectPath>/docs/_extracted/.stories/matrix-<nnn>.json" \
     "<projectPath>/docs/requirement-analysis/"
   ```
8. **校验硬门禁**：`render-story.sh` 渲染完成后自动运行 `validate-story.sh`。有 `[WARN]` 项时必须修复对应 Story JSON 中的字段格式，重新渲染，直到零警告才能报告 `persisted`。不得跳过校验、不得忽略警告
9. 更新 `refs.json`、`facts.json`、`decision-log.md`、`tracking-log.md`、`phase-summary.md`（更新内容见 `output-contract.md` 的记忆更新章节）
10. 更新 `progress.json`：仅更新当前阶段和顶层 `lastUpdated`，不得修改 `workflow.state`、顶层 `status` 或阶段转换字段

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
  "ac_4_then": "系统提示\"无操作权限\"并隐藏创建入口"
}
```

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
  "story_1_sp": "3",
  "story_2_id": "story-002",
  "story_2_title": "查看模型配置列表",
  "story_2_role": "算法工程师",
  "story_2_priority": "P0",
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
