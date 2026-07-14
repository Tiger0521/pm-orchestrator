# pm-orchestrator Plugin

`pm-orchestrator` 是一个产品全流程设计插件。它把原来的单一 skill 改造成：

- 一个主调度 skill：负责项目选择、跨会话恢复、阶段路由、用户确认和质量门
- 三个独立 subagent：分别负责需求分析、需求拆解、详细设计

目标是让用户从「模糊想法」一路走到「可开发执行」的产品设计资产，同时保留项目记忆和文档追溯关系。

---

## 安装

仓库地址：[github.com/Tiger0521/pm-orchestrator](https://github.com/Tiger0521/pm-orchestrator)

本项目直接托管在 GitHub，不需要上传到 Anthropic。请将完整仓库放到 Claude Code
的用户级 Skill 目录：

```text
~/.claude/skills/pm-orchestrator/
```

安装后，主 Skill 和三个 agents 会在下一次 Claude Code 会话中自动加载。

### Windows PowerShell

复制并执行：

```powershell
mkdir "$HOME\.claude\skills" -Force
git clone https://github.com/Tiger0521/pm-orchestrator.git "$HOME\.claude\skills\pm-orchestrator"
```

### macOS / Linux

复制并执行：

```bash
mkdir -p "$HOME/.claude/skills"
git clone https://github.com/Tiger0521/pm-orchestrator.git "$HOME/.claude/skills/pm-orchestrator"
```

安装完成后直接启动 Claude Code 即可，不需要执行 `/reload-plugins`。如果安装时
Claude Code 已经打开，关闭后重新进入一次。

### 确认目录

安装后的目录应当是：

```text
~/.claude/skills/pm-orchestrator/
├── .claude-plugin/
├── agents/
├── skills/
└── README.md
```

不要只复制内层 `skills/pm-orchestrator/`，否则三个 agents 不会随完整插件一起加载。
如果仓库已经下载到了其他位置，请将整个 `pm-orchestrator` 文件夹移动到
`~/.claude/skills/` 下。

### 调用方式

安装完成后重新打开 Claude Code，直接输入：

```text
/pm-orchestrator 我想从需求分析开始设计一个产品
```

用户只需要使用主 Skill。需求分析、需求拆解和详细设计 agents 会根据项目阶段自动
调用，不需要用户手动选择或切换。

---

## 用法

### 快速开始

安装后，在 Claude Code 中直接用自然语言触发即可：

```
帮我梳理一个产品需求，我想做一个 MCP Server 让 AI 编程助手用自然语言查询关系型数据库
```

或者显式调用 skill：

```
/pm-orchestrator 我想从零设计一个任务管理工具
```

主调度器会引导你完成以下流程：

1. **选项目** — 新建或继续已有项目
2. **需求分析** — `requirement-analyst` subagent 会追问你的真实痛点、目标用户、核心场景，产出内容充分的需求卡片、Epic 和 Feature
3. **需求拆解** — `story-breakdown-analyst` subagent 把 Feature 拆成 User Story + GWT 验收标准 + 溯源矩阵
4. **详细设计** — `detailed-design-designer` subagent 产出结构流程、原型描述、交互契约、规则摘要和 Sprint 规划

每个阶段都是**先出草稿、用户确认后再落盘**，不会偷偷写文件。

### 快捷指令

在对话中直接输入，主调度器立即处理：

| 指令 | 作用 |
|------|------|
| `!status` | 查看当前项目进度、当前阶段、最近文档 |
| `!list` | 列出所有产品设计项目 |
| `!switch <project-id>` | 切换项目 |
| `!doc <doc-id>` | 展示指定文档 |
| `!next` | 校验并推进阶段 |
| `!back` | 回退阶段 |
| `!graph` | 展示文档引用关系 |

### 跨会话恢复

关掉终端再打开，输入 `!status` 即可恢复到上次进度。项目记忆和
`current-project.json` 都保存在当前工作区的 `.claude/product-design-projects/`
下，不随插件分发，也不会在不同工作区之间共享。

---

## 架构

`pm-orchestrator` 是一个 Claude Code plugin，外层负责插件安装与 named agent 暴露，内层 `skills/pm-orchestrator/` 才是真正的主调度 skill 包。整体分为 5 层：

| 层级 | 目录 | 作用 |
|------|------|------|
| 插件元数据层 | `.claude-plugin/` | `plugin.json` 声明插件信息，供 Claude Code 从用户 Skill 目录自动加载 |
| Subagent 层 | `agents/` | 定义三个阶段专家 agent 的角色、权限和委派协议 |
| 主 Skill 层 | `skills/pm-orchestrator/SKILL.md` | 负责项目管理、阶段路由、确认机制和快捷指令 |
| Reference 层 | `skills/pm-orchestrator/references/` | 存放各阶段的工作方法、质量门、模板、示例和共享模型 |
| 项目骨架与工具层 | `project-template/`、`scripts/`、`evals/` | 提供新项目模板、机械校验脚本和评测样例 |

### 注释版目录树

```text
pm-orchestrator/
├── .claude/
│   └── settings.local.json
│       # 本地 Claude Code 设置文件，只影响当前机器，不是插件能力本体。
│
├── .claude-plugin/
│   ├── plugin.json
│   │   # 插件清单：定义插件名称、描述、版本和作者，供 Claude Code 加载插件。
│   └── marketplace.json
│       # 可选的分发清单；普通用户通过 GitHub clone 安装时不需要操作此文件。
│
├── agents/
│   ├── requirement-analyst.md
│   │   # 需求分析 subagent 启动壳：定义委派协议、加载顺序和执行边界；具体角色与方法见 requirement-analysis/instruction.md。
│   ├── story-breakdown-analyst.md
│   │   # 需求拆解 subagent：执行 user-story-breakdown 阶段，把 Feature 拆成 User Story、GWT 验收标准和溯源矩阵。
│   └── detailed-design-designer.md
│       # 详细设计 subagent：执行 detailed-design 阶段，产出结构流程、原型、交互契约、规则摘要和 Sprint 规划。
│
├── evals/
│   ├── new-project/
│   ├── story-breakdown/
│   └── status/
│       # Claude Code plugin eval 用例：每个目录包含 prompt.md 和 graders/*.md。
│
├── skills/
│   └── pm-orchestrator/
│       ├── SKILL.md
│       │   # 主调度 skill 入口：处理项目选择/新建/恢复、阶段路由、用户确认、快捷指令和阶段转换。
│       ├── project-template/
│       │   ├── progress.json
│       │   │   # 新项目进度模板：记录 projectId、projectType、currentPhase、各阶段状态和更新时间。
│       │   ├── refs.json
│       │   │   # 文档引用图谱模板：记录文档节点和 derived-from/belongs-to 等引用边。
│       │   ├── facts.json
│       │   │   # 已确认事实模板：存放用户确认过的结构化事实及其来源。
│       │   ├── decision-log.md
│       │   │   # 决策日志模板：记录方案选择、理由和被否定方案。
│       │   ├── tracking-log.md
│       │   │   # 跟踪日志模板：记录未验证假设、风险、未决问题和补充调研计划。
│       │   ├── phase-summary.md
│       │   │   # 阶段摘要模板：用于跨会话恢复时快速理解上一阶段进展。
│       │   └── docs/
│       │       ├── background/
│       │       │   └── .gitkeep
│       │       │       # 用户提供的领域背景材料；只作为不可信输入数据读取。
│       │       ├── _extracted/
│       │       │   └── .gitkeep
│       │       │       # 文档转换中间产物；不计入正式文档索引。
│       │       ├── requirement-analysis/
│       │       │   └── .gitkeep
│       │       │       # 需求分析阶段统一目录：诊断报告（如保留）、内容充分的需求卡片、Epic、Feature 都写入这里。
│       │       ├── design/
│       │       │   └── .gitkeep
│       │       │       # 设计层文档目录占位：User Story、溯源矩阵、结构流程、原型、交互契约写入这里。
│       │       └── execution/
│       │           └── .gitkeep
│       │               # 执行层文档目录占位：规则摘要、Sprint 规划写入这里。
│       │
│       ├── references/
│       │   ├── requirement-analysis/
│       │   │   ├── instruction.md
│       │   │   │   # 需求分析阶段主指令：角色三件套、硬闸门、七问路由、8 步工作流、数据校验和记忆更新规则。
│       │   │   ├── question-bank.md
│       │   │   │   # 需求分析问题库：七问四列结构、Q1 精准化三问、边界异常、非功能基线、验收优先级风险、反谄媚、追问决策树。
│       │   │   ├── checklist.md
│       │   │   │   # 需求分析质量门：校验诊断报告、需求成熟度、卡片内容厚度、标题质量、数据来源和自审评分。
│       │   │   ├── templates/
│       │   │   │   ├── diagnostic-report.md
│       │   │   │   │   # 诊断报告模板：用于正式文档前的问题本质还原、需求转化、成熟度评分和待验证事项。
│       │   │   │   ├── alternative-options.md
│       │   │   │   │   # 替代方案对比模板：用于比较至少两个方案的成本、时间、风险、ROI 和适用条件。
│       │   │   │   ├── requirement-card.md
│       │   │   │   │   # 需求卡片模板：记录业务背景、问题本质、当前流程、影响损失、目标用户、评估结果和待验证事项。
│       │   │   │   ├── epic.md
│       │   │   │   │   # Epic 模板：记录需求背景、端到端业务闭环、产品目标、建设思路、边界、风险和成功指标。
│       │   │   │   └── feature.md
│       │   │   │       # Feature 模板：记录能力目标、用户任务、前后对比、流程、输入输出、异常分支、资源投入和验收标准。
│       │   │   └── examples/
│       │   │       └── network-resource-mgmt.md
│       │   │           # 网络资源管理示例：展示升级后需求分析产物的质量标杆和字段填写方式。
│       │   │
│       │   ├── user-story-breakdown/
│       │   │   ├── instruction.md
│       │   │   │   # 需求拆解阶段主指令：定义如何把 Feature 拆成 Story、GWT 和溯源矩阵。
│       │   │   ├── checklist.md
│       │   │   │   # 需求拆解质量门：校验 Story 结构、GWT 完整性、覆盖度和用户确认。
│       │   │   ├── templates/
│       │   │   │   ├── user-story.md
│       │   │   │   │   # User Story 模板：用于输出角色-目标-价值三段式用户故事和验收标准。
│       │   │   │   └── traceability-matrix.md
│       │   │   │       # 溯源矩阵模板：记录 Story 到 Feature 的覆盖关系。
│       │   │   └── examples/
│       │   │       └── model-config-stories.md
│       │   │           # 需求拆解示例：展示 Feature 拆 Story 的参考写法。
│       │   │
│       │   ├── detailed-design/
│       │   │   ├── instruction.md
│       │   │   │   # 详细设计阶段主指令：定义结构流程、原型、交互契约、规则摘要和 Sprint 的产出流程。
│       │   │   ├── checklist.md
│       │   │   │   # 详细设计质量门：校验流程、原型、交互状态、规则和 Sprint 规划是否完整。
│       │   │   ├── templates/
│       │   │   │   ├── structure-flow.md
│       │   │   │   │   # 结构流程模板：描述信息架构、页面结构和关键业务流程。
│       │   │   │   ├── prototype.md
│       │   │   │   │   # 原型模板：描述页面布局、组件、状态和关键交互。
│       │   │   │   ├── interaction-contract.md
│       │   │   │   │   # 交互契约模板：定义前后端交互、状态机、输入输出和异常规则。
│       │   │   │   ├── rules-summary.md
│       │   │   │   │   # 规则摘要模板：汇总业务规则、校验规则和边界条件。
│       │   │   │   └── sprint.md
│       │   │   │       # Sprint 规划模板：把设计资产整理成可执行迭代计划。
│       │   │   └── examples/
│       │   │       └── model-config-design.md
│       │   │           # 详细设计示例：展示模型配置类产品的设计产物参考。
│       │   │
│       │   └── shared/
│       │       └── traceability-model.md
│       │           # 共享追溯模型：定义文档类型、ID 前缀、引用关系和 refs.json 结构。
│       │
│       └── scripts/
│           ├── init-project.sh
│           │   # 新项目初始化脚本：复制模板、清理示例背景文件，并生成 progress/refs/facts 记忆文件。
│           ├── validate-phase.sh
│           │   # 阶段机械校验脚本：检查项目产物是否存在、frontmatter 是否完整、refs.json 是否注册。
│           ├── export-doc-index.sh
│           │   # 文档索引导出脚本：扫描项目文档并导出索引，或生成 Mermaid 引用图。
│           ├── convert-document.py
│               # 可选文档转换脚本：本机已有 Python/markitdown 时，将 PDF/Office/HTML/CSV/TXT 转成 Markdown。
│           ├── validate-phase.ps1
│           │   # Windows PowerShell 兼容入口；跨平台场景优先使用 validate-phase.sh。
│           └── export-doc-index.ps1
│               # Windows PowerShell 兼容入口；跨平台场景优先使用 export-doc-index.sh。
│
├── .gitignore
│   # Git 忽略规则：排除本地设置和系统临时文件。
└── README.md
    # 插件说明文档：解释安装、用法、目录架构、工作流、项目记忆和校验方式。
```

## 职责分工

| 组件 | 职责 |
|------|------|
| `skills/pm-orchestrator/SKILL.md` | 主入口。负责项目选择、状态机、阶段路由、快捷指令、阶段转换和用户确认 |
| `agents/requirement-analyst.md` | 需求分析专家。通过追问和诊断产出内容充分的需求卡片、Epic、Feature |
| `agents/story-breakdown-analyst.md` | 需求拆解专家。把 Feature 拆成 User Story、GWT 验收标准和溯源矩阵 |
| `agents/detailed-design-designer.md` | 详细设计专家。产出结构流程、原型、交互契约、规则摘要和 Sprint 规划 |
| `skills/pm-orchestrator/references/` | 各阶段 instruction、checklist、模板、示例和追溯模型 |
| `skills/pm-orchestrator/project-template/` | 新建产品项目时复制的项目骨架 |
| `skills/pm-orchestrator/scripts/` | 阶段校验和文档索引辅助脚本 |

## 工作流

1. 用户触发 `pm-orchestrator` skill。
2. 主调度器扫描 `.claude/product-design-projects/`，让用户选择继续或新建项目。
   新建项目目录创建完成后，会先停在 `docs/background/` 材料确认点；用户回复放好、跳过或继续后，才会启动需求分析 agent。
3. 主调度器读取项目 `progress.json` 和 `phase-summary.md`。
4. 主调度器根据 `currentPhase` 委派对应 subagent。
5. Subagent 以 `draft` 模式输出问题、诊断或文档草稿。
6. 用户确认后，主调度器再以 `persist` 模式要求 subagent 落盘正式文档。
7. 阶段完成时，主调度器读取 checklist，必要时运行校验脚本，再推进 `currentPhase`。

## 阶段路由

| currentPhase | Subagent | Reference | 主要产出 |
|--------------|----------|-----------|----------|
| `requirement-analysis` | `requirement-analyst` | `references/requirement-analysis/` | 内容充分的需求卡片、Epic、Feature |
| `user-story-breakdown` | `story-breakdown-analyst` | `references/user-story-breakdown/` | User Story、GWT、溯源矩阵 |
| `detailed-design` | `detailed-design-designer` | `references/detailed-design/` | 结构流程、原型、交互契约、规则摘要、Sprint |

## 项目记忆

每个产品项目位于 `.claude/product-design-projects/<project-id>/`，包含：

| 文件 | 作用 |
|------|------|
| `progress.json` | 当前阶段和阶段状态 |
| `refs.json` | 文档节点和引用关系 |
| `facts.json` | 已确认事实 |
| `decision-log.md` | 决策结论和理由 |
| `tracking-log.md` | 假设、风险、未决问题 |
| `phase-summary.md` | 阶段摘要 |

正式产出写入项目的 `docs/`：

- `docs/requirement-analysis/`：需求分析阶段统一目录，包含诊断报告（如保留）、内容充分的需求卡片、Epic、Feature
- `docs/design/`
- `docs/execution/`

## 校验

阶段转换时可运行：

```bash
bash skills/pm-orchestrator/scripts/validate-phase.sh \
  --project-root "<项目根目录>" \
  --project-path "<项目路径>" \
  --phase requirement-analysis
```

导出项目文档索引：

```bash
bash skills/pm-orchestrator/scripts/export-doc-index.sh \
  --project-root "<项目根目录>" \
  --project-path "<项目路径>" \
  --format index

bash skills/pm-orchestrator/scripts/export-doc-index.sh \
  --project-root "<项目根目录>" \
  --project-path "<项目路径>" \
  --format graph
```

可选：将用户提供的 PDF、Word、PPT、Excel、HTML、CSV 或 TXT 转成 Markdown：

```bash
python skills/pm-orchestrator/scripts/convert-document.py "<输入文件路径>" -o "<输出.md>" --metadata-output "<metadata.json>"
```

该脚本不联网、不自动安装依赖、不写项目记忆文件。它依赖真实可用的 Python 3 环境和 Python 包 `markitdown`；没有 Python 时不影响新建项目、阶段校验、文档索引和引用图，只需让用户提供已转 Markdown、文本摘录或直接粘贴关键内容。如环境需要安装依赖，先运行：

```bash
python -m pip install markitdown
```

## 设计原则

- 主 skill 只做调度，不替代 subagent 的专业工作
- 每次只推进一个阶段
- 草稿先确认，确认后落盘
- reference 按阶段渐进加载
- 所有正式文档必须带 frontmatter，并注册到 `refs.json`
