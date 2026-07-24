# 快捷指令

本文件是全局中断处理器。输入以 `!` 开头时读取；不要执行正常调度第 0 步，不要读取产品库，也不要把命令改写成阶段意图。

## 通用规则

1. 暂停当前正常流程并保存当前对话中的项目、步骤和待确认事项。
2. 项目根固定为当前工作区 `.claude/product-design-projects/`；扫描时忽略 `current-project.json`。
3. 使用项目前规范化路径，确认它是项目根的直接子目录。拒绝 `..`、绝对路径、盘符、符号链接或目录联接越界。
4. 除 `!next` 对当前阶段执行 `mode=validate` 外，不启动阶段 agent。命令完成后返回结果并等待用户，不自动恢复之前流程，也不自动启动下一阶段 agent。
5. 未知命令只列出支持的命令，不进入正常调度。

## 查询命令

### `!status`

读取工作区 `current-project.json`，验证指针后只读取当前项目的 `progress.json` 和 `phase-summary.md`。展示项目、`projectType`、`workflow.state`、最近进展和最近文档。`completed` 作为终态处理。不委派 subagent。

### `!list`

扫描项目根下的项目目录，读取每个项目的 `progress.json`，展示项目 ID、名称、类型、状态和更新时间。不修改当前项目。

### `!doc <doc-id>`

验证当前项目后，从 `refs.json` 定位文档。规范化目标路径并确认位于当前项目内，再读取和展示。找不到时给出当前项目中的近似文档 ID。不委派 subagent。

### `!graph`

验证当前项目后，优先调用 `scripts/export-doc-index.sh` 从 `refs.json` 生成或展示 Mermaid 引用图；所有输入输出必须位于当前项目内。不委派 subagent。

## 状态变更命令

### `!switch <project-id>`

要求 ID 匹配 `^[a-z0-9][a-z0-9-]{0,62}$`。精确项目存在时，验证路径和 `progress.json` 后更新工作区 `current-project.json`；显式命令本身视为切换确认。缺少 ID 或只有模糊匹配时列出候选并等待确认。切换后只汇报新项目状态，不自动委派。

### `!next`

验证当前项目并读取 `progress.json`。读取 `references/orchestrator/phase-transition.md`，按当前阶段执行 checklist、`mode=validate`、机械校验和用户确认。仅可迁移到相邻下一状态。迁移后汇报结果并等待用户，不自动委派下一阶段。

### `!back`

验证当前项目并展示当前状态、目标回退状态和影响，等待用户确认。确认后读取 `references/orchestrator/phase-transition.md` 并调用状态迁移脚本。只允许 `user-story-breakdown -> requirement-analysis` 和 `detailed-design -> user-story-breakdown`。不得从 `completed` 自动回退。
