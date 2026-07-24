# 继续已有项目意图

当用户说“继续”“打开”“切到”“接着”“查看”或“借着”某项目时读取本文件。本文件只负责确定项目和恢复状态；恢复后由 `SKILL.md` 阶段路由决定是否读取对应阶段意图文件。

## 1. 匹配项目

1. 扫描当前工作区 `.claude/product-design-projects/`，忽略 `current-project.json`。
2. 按项目 ID、项目名称和一句话描述匹配用户关键词。
3. 只有一个候选时，展示项目 ID、名称、当前阶段和 `phase-summary.md` 摘要，等待用户确认。
4. 多个候选时列出候选并等待选择，不要猜测。
5. 没有候选时提供“查看项目列表 / 开始需求分析 intake / 重新输入关键词”，不要自动创建项目。

## 2. 确认并恢复

1. 规范化候选项目路径，确认它是当前工作区项目根的直接子目录。
2. 用户确认后才更新工作区 `current-project.json`。
3. 只读取 `progress.json` 和 `phase-summary.md` 恢复项目；不要一次性加载全部记忆文件。
4. 比较项目的 `selectedProductLibraryId` 与第 0 步结果；不同则使用项目记录重新执行 `product-library-context.md`。
5. 简要汇报 `projectType`、`workflow.state`、上次进展和已有产物。

## 3. 恢复后的路由

- intake 内部状态：读取 `requirement-analysis-intent.md`，继续对应 intake 步骤；不要把“继续”本身当作产品匹配许可。
- `requirement-analysis`：读取 `requirement-analysis-intent.md`。
- `user-story-breakdown`：读取 `story-breakdown-intent.md`。
- `detailed-design`：读取 `detailed-design-intent.md`。
- `completed`：不读取阶段意图文件，不委派 subagent；展示查看、明确回退或新建项目选项。

继续项目只按实际状态路由。不要因为用户使用“继续”而默认进入需求分析，也不要重复创建项目。
