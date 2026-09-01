# Claude Code 运行时机制

会话开头由 `SKILL.md` 的"运行时识别"门识别到宿主为 **Claude Code** 后，本会话固定 `RUNTIME=claude`，主调度器及被委派 subagent 全程只按本文件执行，不读取 `runtime/zcode.md`，不漏用另一套机制。

## 固定常量

| 项 | 值 |
| --- | --- |
| `RUNTIME` | `claude` |
| 过程项目根 | `<workspace>/.claude/product-design-projects/` |
| `skillPath` 基准 | `~/.claude/skills/pm-orchestrator`（skill 安装目录，运行时以实际位置为准） |

## Subagent 定义位置

subagent 定义位于本 skill 文件夹内 `agents/*.md`（claude 版平铺在 `agents/` 根，随"一份 skill"分发）。本 skill 根携带 `.claude-plugin/plugin.json`，Claude Code 会把 skill 目录自动识别为名为 `pm-orchestrator` 的插件，`agents/` 下的五个 subagent 因此自动获得 `pm-orchestrator:` 命名空间，**无需任何插件注册**。安装只需把整个 skill 文件夹拷入 `~/.claude/skills/pm-orchestrator` 后重启 Claude Code（`install.ps1` 为可选便捷工具）。主调度器无需关心其存放，只用下方"命名子 agent"方式引用。

## 主 agent 调用方式

以 Claude Code 的命名子 agent（Task）机制委派，subagent 名 **必须带插件命名空间** `pm-orchestrator:` 前缀：

- `pm-orchestrator:requirement-analyst`
- `pm-orchestrator:story-map-designer`
- `pm-orchestrator:detailed-design-designer`
- `pm-orchestrator:sprint-planner`
- `pm-orchestrator:architecture-updater`

## 文件路径

- 过程项目根写死当前工作区 `.claude/product-design-projects/`；项目必须是其直接子目录。
- reference 以相对 `skillPath` 解析：Claude 的 subagent 运行在插件上下文内，`references/...` 相对路径可直接解析，无需拼接前缀。
- 背景目录、项目模板、`current-project.json` 均按 `.claude` 目录布局定位。

## Agent frontmatter 约定

Claude 版 agent frontmatter 的 `tools` 含 `LS`（部分含 `Bash`）：

| agent | tools |
| --- | --- |
| `requirement-analyst` | `["Read","Write","Grep","Glob","LS","Bash"]` |
| `story-map-designer` | `["Read","Write","Grep","Glob","LS","Bash"]` |
| `detailed-design-designer` | `["Read","Write","Grep","Glob","LS","Bash"]` |
| `sprint-planner` | `["Read","Write","Grep","Glob","LS","Bash"]` |
| `architecture-updater` | `["Read","Write","Grep","Glob","LS","Bash"]` |

每个 agent 文件的 frontmatter 带 `runtime: claude`，正文以 `references/...` 相对路径引用方法论。
