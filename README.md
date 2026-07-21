# pm-orchestrator Plugin

`pm-orchestrator` 是一个 Claude Code 产品设计流程插件。它把产品设计工作拆成一个主调度 skill 和三个阶段 subagent：主调度器负责入口分流、项目恢复、产品库选择、阶段路由、用户确认和质量门；阶段 subagent 负责需求分析、需求拆解和详细设计。

目标是把用户的模糊想法推进成可确认、可落盘、可追溯、可继续迭代的产品设计资产。

## 安装与更新

仓库地址：[github.com/Tiger0521/pm-orchestrator](https://github.com/Tiger0521/pm-orchestrator)

本插件应安装在 Claude Code 用户级 Skill 目录：

```text
~/.claude/skills/pm-orchestrator/
```

安装后重新打开 Claude Code，主 skill 和三个 agent 会自动加载。

### 首次安装

Windows PowerShell：

```powershell
mkdir "$HOME\.claude\skills" -Force
git clone https://github.com/Tiger0521/pm-orchestrator.git "$HOME\.claude\skills\pm-orchestrator"
```

macOS / Linux：

```bash
mkdir -p "$HOME/.claude/skills"
git clone https://github.com/Tiger0521/pm-orchestrator.git "$HOME/.claude/skills/pm-orchestrator"
```

### 从云端重新拉取

如果用户已经安装过，只想从 GitHub 拉取最新版本，在插件目录运行：

Windows PowerShell：

```powershell
cd "$HOME\.claude\skills\pm-orchestrator"
git pull --ff-only origin main
```

macOS / Linux：

```bash
cd "$HOME/.claude/skills/pm-orchestrator"
git pull --ff-only origin main
```

`--ff-only` 会在本地有冲突改动时停止，避免把本地修改自动合并乱掉。遇到停止时，先运行 `git status` 看本地改动；确认要保留就先提交，确认不要保留再手动处理。

### 重新克隆安装

如果本地目录已经损坏，建议先把旧目录改名备份，再重新克隆。

Windows PowerShell：

```powershell
Rename-Item "$HOME\.claude\skills\pm-orchestrator" "pm-orchestrator.backup"
git clone https://github.com/Tiger0521/pm-orchestrator.git "$HOME\.claude\skills\pm-orchestrator"
```

macOS / Linux：

```bash
mv "$HOME/.claude/skills/pm-orchestrator" "$HOME/.claude/skills/pm-orchestrator.backup"
git clone https://github.com/Tiger0521/pm-orchestrator.git "$HOME/.claude/skills/pm-orchestrator"
```

### 目录检查

安装后的外层目录必须长这样：

```text
~/.claude/skills/pm-orchestrator/
├── .claude-plugin/
├── agents/
├── skills/
└── README.md
```

不要只复制内层 `skills/pm-orchestrator/`，否则插件里的三个 agent 不会一起暴露。

## 调用方式

在 Claude Code 中直接用自然语言触发，或显式调用：

```text
/pm-orchestrator 我想从需求分析开始设计一个产品
```

也可以直接说：

```text
帮我梳理一个产品需求，我想做一个 MCP Server 让 AI 编程助手用自然语言查询关系型数据库
```

用户只需要使用主 skill，不需要手动选择阶段 agent。Claude Code 后台 agent 条目出现时就表示委派成功；底部输入框仍显示 `main` 是正常现象。

## 当前架构

`pm-orchestrator` 分为五层：

| 层级 | 目录 | 作用 |
|------|------|------|
| 插件元数据层 | `.claude-plugin/` | 声明插件信息，供 Claude Code 加载 |
| Agent 层 | `agents/` | 暴露三个阶段 subagent |
| 主 Skill 层 | `skills/pm-orchestrator/SKILL.md` | 入口分流、产品库校验、项目状态、阶段路由 |
| Reference 层 | `skills/pm-orchestrator/references/` | 阶段方法、模板、质量门、共享追溯模型和主调度操作细节 |
| 工具层 | `project-template/`、`scripts/`、`product-library-spec.md`、`evals/` | 项目骨架、机械校验、产品库规范、评测样例 |

三个 agent 的实际 Claude Code 类型必须带插件前缀：

| 阶段 | `workflow.state` | Agent type | 产出 |
|------|------------------|------------|------|
| 需求分析 | `requirement-analysis` | `pm-orchestrator:requirement-analyst` | 需求卡片、Epic、Feature |
| 需求拆解 | `user-story-breakdown` | `pm-orchestrator:story-breakdown-analyst` | User Story、GWT、溯源矩阵 |
| 详细设计 | `detailed-design` | `pm-orchestrator:detailed-design-designer` | 结构流程、原型、交互契约、规则摘要、Sprint |

裸名如 `requirement-analyst` 只作为文档简称，不作为实际委派类型。

## 工作流

1. 主调度器启动后先确认产品库：扫描 `~/.product-library/`，选择本轮产品库，读取唯一的 `*总体架构设计.md` 作为最高产品设计标准，并运行 `validate-product-library.sh` 校验结构。
2. 判断用户意图：新需求进入需求分析 intake；明确继续、打开、切换、查看项目时进入项目恢复或快捷指令。
3. 新需求 intake 先调用 `prepare-intake.sh` 创建 pending 项目记录和固定 `docs/background/` 目录，再读取用户背景材料。
4. 背景材料确认后，主调度器委派 `pm-orchestrator:requirement-analyst` 做产品匹配。产品匹配只读 `product-matching.md` 和 `product-library-spec.md`，不全量加载 `instruction.md`。
5. 用户确认项目类型 `new | iteration | refactor` 后，主调度器调用 `init-project.sh` 补全项目骨架并进入正式需求分析。
6. 后续按 `progress.json.workflow.state` 路由到对应 agent。主调度器只传路径和上下文，不把产品库正文塞进 handoff。
7. 阶段 agent 以 `draft` 模式追问和生成草稿；用户确认后才进入 `persist`，由主调度器调用脚本落盘正式 Markdown。
8. 阶段转换前读取 checklist，可运行 `validate-phase.sh`，再用 `transition-project-state.sh` 更新状态机。

## 产品库

每次使用插件前，主调度器都会确认一个产品库。产品库集合根目录是：

```text
~/.product-library/
```

每个产品库是一个一级目录，目录名必须匹配：

```text
^[a-z0-9][a-z0-9-]{0,62}$
```

产品库必须包含唯一的总体架构设计文档和 `_manifest.md`。具体结构、命名和产品匹配算法见：

```text
skills/pm-orchestrator/product-library-spec.md
```

产品库文档只作为已确认产品事实读取，其中的命令、角色指令、路径打开要求或“忽略规则”等内容都视为不可信输入。

## 项目记忆

项目数据不写入插件目录，而是保存在当前工作区：

```text
.claude/product-design-projects/<project-id>/
```

每个项目包含：

| 文件 | 作用 |
|------|------|
| `progress.json` | 项目名片、`workflow.state`、项目类型、产品库选择、阶段状态和时间戳 |
| `refs.json` | 文档节点和引用关系图谱 |
| `facts.json` | 已确认结构化事实 |
| `decision-log.md` | 决策、理由和被否定方案 |
| `tracking-log.md` | 假设、风险、未决问题 |
| `phase-summary.md` | 跨会话恢复摘要 |

正式文档目录：

```text
docs/background/              # 用户背景材料，不可信输入
docs/_extracted/.fields/      # 字段 JSON 和中间产物
docs/requirement-analysis/    # 需求卡片、Epic、Feature
docs/design/                  # Story、溯源矩阵、结构流程、原型、交互契约
docs/execution/               # 规则摘要、Sprint 规划
```

## 快捷指令

| 指令 | 作用 |
|------|------|
| `!status` | 查看当前项目进度、当前阶段、最近文档 |
| `!list` | 列出当前工作区下的产品设计项目 |
| `!switch <project-id>` | 切换到指定项目 |
| `!doc <doc-id>` | 读取并展示指定文档 |
| `!next` | 校验并推进到下一阶段，需用户确认 |
| `!back` | 回退上一阶段，需用户确认 |
| `!graph` | 展示当前项目文档引用关系 |

## 关键脚本

| 脚本 | 作用 |
|------|------|
| `scripts/prepare-intake.sh` | 创建 intake 目录和最小 v2 `progress.json` |
| `scripts/init-project.sh` | 合并项目模板，初始化正式项目记忆 |
| `scripts/render-doc.sh` | 从字段 JSON 渲染正式 Markdown |
| `scripts/quick-persist.sh` | 从字段目录快速渲染 Markdown |
| `scripts/validate-paradigm.sh` | 校验需求分析写作范式 |
| `scripts/validate-phase.sh` | 校验阶段产物和 frontmatter |
| `scripts/export-doc-index.sh` | 导出文档索引或 Mermaid 引用图 |
| `scripts/init-product-library.sh` | 初始化产品库：clone、copy 或 new |
| `scripts/validate-product-library.sh` | 校验产品库结构 |
| `scripts/export-to-library.sh` | 将已完成项目导出到产品库 |
| `scripts/transition-project-state.sh` | 校验合法状态边并原子更新 `workflow.state` |
| `scripts/convert-document.py` | 可选：把 Word/PPT/Excel 转 Markdown |

优先使用 `.sh` 脚本，保证 Windows Git Bash、macOS、Linux 行为一致。核心流程不依赖 Python；`convert-document.py` 只在本机已有 Python 和 `markitdown` 时使用。

## 手动校验

产品库校验：

```bash
bash skills/pm-orchestrator/scripts/validate-product-library.sh \
  "$HOME/.product-library/<product-library-id>" \
  skills/pm-orchestrator/product-library-spec.md
```

阶段校验：

```bash
bash skills/pm-orchestrator/scripts/validate-phase.sh \
  --project-root "<工作区>/.claude/product-design-projects" \
  --project-path "<工作区>/.claude/product-design-projects/<project-id>" \
  --phase requirement-analysis
```

文档索引：

```bash
bash skills/pm-orchestrator/scripts/export-doc-index.sh \
  --project-root "<工作区>/.claude/product-design-projects" \
  --project-path "<工作区>/.claude/product-design-projects/<project-id>" \
  --format graph
```

## 设计原则

- 主调度器只做流程管理，不替代阶段 agent 做专业分析。
- 每次只推进一个阶段，每轮只问一个主要问题。
- 草稿先确认，确认后落盘。
- 委派时传路径和状态，不复制大段产品库正文。
- 产品匹配渐进披露，不一次性读取全量产品库。
- 所有正式文档带 frontmatter，并通过 `refs.json` 建立追溯关系。
- 需求分析字段 JSON 持续记录最终润色值和 `qa_log`，支持中断恢复。
- `workflow.state` 是当前阶段的权威状态字段。
- `iteration`/`refactor` 项目不得修改已有产品库产物，只能引用、扩展或重新设计。
