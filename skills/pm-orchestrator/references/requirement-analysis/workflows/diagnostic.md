# 需求分析诊断工作流

**前置条件**：顶层管线已完成第 1 步；`workflow.state=requirement-analysis`；`task` 明确要求“诊断报告”或“替代方案对比”；`mode` 只能为 `draft` 或 `persist`。

**立即读取**：用户指定的一个模板：诊断报告读取 `../templates/diagnostic-report.md`；替代方案对比读取 `../templates/alternative-options.md`。只使用已确认事实、已批准读取的上游文档和本轮用户输入；事实不足时返回一个 `needs-input`，不臆造结论。

**允许写入**：`mode=draft` 不写入文件，只输出完整预览；`mode=persist` 仅在用户已确认该完整预览后，写入 `<projectPath>/docs/requirement-analysis/diagnostic-<nnn>.md`，并按项目既有索引规则登记。不得调用 `render-doc.sh`，不得改写需求卡片、Epic、Feature 或 `workflow.state`。

**终点**：事实不足时返回 `needs-input`；草稿预览完整时返回 `draft-ready`；仅确认后落盘完成时返回 `persisted`；路径、状态或写入范围不合法时返回 `blocked`。

## 第 1 步：生成诊断或方案对比预览

按所选模板完整输出，不得以摘要替代模板字段。结论必须区分已确认事实、推断、假设和待验证项；需要用户澄清时，只提出一个主问题并返回 `needs-input`。

`mode=draft` 在预览完整后返回 `draft-ready`，等待用户确认；不得隐式落盘。

## 第 2 步：确认后落盘

仅在 `mode=persist`、用户已确认完整预览且字段内容未变时执行。手工写入正式 Markdown，检查其 ID、类型、项目 ID、标题、状态和引用元数据；完成后返回 `persisted`。