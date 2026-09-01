# ZCode 运行时机制

会话开头由 `SKILL.md` 的"运行时识别"门识别到宿主为 **ZCode** 后，本会话固定 `RUNTIME=zcode`，主调度器及被委派 subagent 全程只按本文件执行，不读取 `runtime/claude.md`，不漏用另一套机制。

## 固定常量

| 项 | 值 |
| --- | --- |
| `RUNTIME` | `zcode` |
| 过程项目根 | `<workspace>/.claude/product-design-projects/`（与 Claude Code 分支统一，同一 workspace 共用一套过程项目） |
| `skillPath` 基准 | 用户级 skill 安装位置（`~/.zcode/skills/pm-orchestrator` 或 `~/.agents/skills/pm-orchestrator`，以实际加载本 skill 的路径为准） |

## Subagent 自检自举（拷文件夹即用，不需要任何脚本）

ZCode **只从 `~/.zcode/agents/*.md` 发现 subagent**（源码级事实：`resolveUserSubagentRoot` 指向用户级 agents 目录；ZCode 不扫描 skill 文件夹内的 agent 文件，也不存在 `skills-dir` 插件自动识别机制）。因此用户只需把整个 skill 文件夹拷到 `~/.zcode/skills/pm-orchestrator`（或 `~/.agents/skills/...`）。**每次运行本 skill 时，主调度器都自检一次**，把 subagent 补齐到位：

1. 以 `<skillPath>/agents/zcode/` 为来源目录（`skillPath` 为本 skill 实际加载位置）。
2. 对本 skill 的 4 个 subagent（`requirement-analyst`、`story-map-designer`、`detailed-design-designer`、`sprint-planner`）：若 `~/.zcode/agents/<name>.md` 不存在，则从来源目录复制过去。
3. 自检完成后才进入委派。幂等：已存在即跳过，不覆盖用户已有改动；缺失才补，因此即便 agent 被删或换机重拷文件夹，也会自动恢复。

`install.ps1` 仅为预置/清理的**可选**便捷工具，不是必需步骤。

## Subagent 定义位置

subagent 定义以 `agents/zcode/*.md` 随包分发（一份 skill 内同时含 claude 与 zcode 两套）。ZCode 的落点是**用户级** `~/.zcode/agents/*.md`，按文件名发现。主调度器用下方 `Agent` 工具的 `subagent_type` 引用，不通过文件路径加载。

## 主 agent 调用方式

必须用 ZCode 的 `Agent` 工具，参数 `subagent_type` 使用**裸名（不含命名空间）**——ZCode 按其文件名解析类型，带 `pm-orchestrator:` 前缀会匹配不到：

- `requirement-analyst`
- `story-map-designer`
- `detailed-design-designer`
- `sprint-planner`

## 文件路径

- 过程项目根与 Claude Code 分支统一为 `<workspace>/.claude/product-design-projects/`；项目必须是其直接子目录。
- reference **必须经 `${skillPath}` 拼接解析**：ZCode 的 subagent 位于全局 `~/.zcode/agents/`，不在 skill 包内，正文里的相对 `references/...` 解析不到。主调度器每次委派 zcode subagent 时，必须在 handoff 中显式告知："所有 `references/...` 以 `<skillPath>/` 为基准解析"；subagent 按 `<skillPath>/references/<阶段>/...` 读取方法论。

## Agent frontmatter 约定

ZCode 版（`zcode/agents/`）agent frontmatter 的 `tools` **不含 `LS`**（ZCode 子 agent 无 `LS` 工具）：

| agent | tools |
| --- | --- |
| `requirement-analyst` | `["Read","Write","Grep","Glob","Bash"]` |
| `story-map-designer` | `["Read","Write","Grep","Glob","Bash"]` |
| `detailed-design-designer` | `["Read","Write","Grep","Glob","Bash"]` |
| `sprint-planner` | `["Read","Write","Grep","Glob","Bash"]` |

每个 agent 文件的 frontmatter 带 `runtime: zcode`。
