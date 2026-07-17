# pm-orchestrator Plugin

`pm-orchestrator` 是一个产品全流程设计插件。它把原来的单一 skill 改造成：

- 一个主调度 skill：负责入口分流、项目恢复、跨会话记忆、阶段路由、用户确认和质量门
- 三个独立 subagent：分别负责需求分析、需求拆解、详细设计
- 一套写作范式体系：6 条通用规律 + 6 种语言范式（A-F），逐字段定义每个文档字段的写法和好差对比
- 一组机械校验脚本：从 JSON 字段渲染 Markdown、校验范式合规、校验阶段产物完整性

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

1. **入口分流** — 用户提新需求时进入需求分析 intake；用户明确继续旧项目时才进入项目恢复。intake 会先创建固定 `docs/background/` 目录并读取背景材料，再理解候选产品和用户业务目标，最后收敛项目类型 new / iteration / refactor。
2. **需求分析** — `requirement-analyst` subagent 通过逐字段追问（需求卡片 5 字段 / Epic 9 字段 / Feature 12 字段），产出按写作范式结构化的需求卡片、Epic 和 Feature
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
| Reference 层 | `skills/pm-orchestrator/references/` | 存放各阶段的工作方法、写作范式、质量门、模板、示例和共享模型 |
| 项目骨架与工具层 | `project-template/`、`scripts/`、`product-library-spec.md`、`evals/` | 提供新项目模板、机械校验脚本、产品库规范与匹配算法和评测样例 |

### 注释版目录树

```text
pm-orchestrator/
├── .claude-plugin/
│   └── plugin.json
│       # 插件清单：定义插件名称、描述、版本和作者，供 Claude Code 加载插件。
│       # marketplace.json（计划中）：可选的分发清单，用于 Plugin Marketplace 发布。
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
│       │   # 主调度 skill 入口：处理入口分流/项目记录创建/恢复、阶段路由、用户确认、快捷指令和阶段转换。
│       │
│       ├── product-library-spec.md
│       │   # 产品库规范：定义全局产品库目录结构、命名规则、元信息格式和产品匹配算法（6 维度语义比对 + 加权评分 + 部分匹配修正）。
│       │
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
│       │       │       # 项目专属背景材料；只作为不可信输入数据读取。
│       │       ├── _extracted/
│       │       │   └── .fields/
│       │       │       └── .gitkeep
│       │       │       # 字段 JSON 中间文件（fields-*.json）和文档转换中间产物；不计入正式文档索引。
│       │       ├── requirement-analysis/
│       │       │   └── .gitkeep
│       │       │       # 需求分析阶段统一目录：需求卡片、Epic、Feature 都写入这里。
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
│       │   │   │   # 需求分析阶段主指令：角色三件套、状态口径（draft/persist/validate）、产品匹配与复用引导、10 步工作流、字段 JSON 机制、落盘渲染和记忆更新规则。
│       │   │   ├── question-bank.md
│       │   │   │   # 需求分析问题库：广度优先问题库（角色/场景/问题簇/能力候选/范围确认）、需求卡片 5 字段逐字段追问、Epic 9 字段逐字段追问、Feature 12 字段逐字段追问、反谄媚禁用词表、前提挑战模式、复杂度路由。
│       │   │   ├── checklist.md
│       │   │   │   # 需求分析质量门：文件存在性、frontmatter 完整性、范式合规（通用六条 + 需求卡片/Epic/Feature 逐字段范式检查）、先验质量、数据校验、对抗性自审评分。
│       │   │   ├── writing-paradigm/
│       │   │   │   ├── general-rules.md
│       │   │   │   │   # 写作范式总则：6 条通用规律（总结先行/加粗关键词领条/具名细节/结论跟为什么/诚实标注/视觉结构匹配内容）+ 6 种语言范式定义（A 总结开头+分条列点 / B blockquote 核心论断+分要点 / C 开头定位+表格 / D 开头定位+流程图+关键特征 / E 分层结构+每层表格 / F 段落论证）。
│       │   │   │   ├── requirement-card.md
│       │   │   │   │   # 需求卡片字段范式：逐字段定义范式（基本信息 C / 现状描述 D / 痛点 A / 问题本质 F / 评估结果 C）+ 好差对比。
│       │   │   │   ├── epic.md
│       │   │   │   │   # Epic 字段范式：逐字段定义范式（定位 B / 目标 A / 角色 C / 场景 D / 价值 A / 范围边界 A / 建设思路 设计理念范式）+ 好差对比。
│       │   │   │   └── feature.md
│       │   │   │       # Feature 字段范式：逐字段定义范式（描述 F / 目标 A / 价值 A / 场景 A / 流程 D / 规则 C / 可行性 F / 资源 C）+ 好差对比。
│       │   │   └── templates/
│       │   │       ├── requirement-card.md
│       │   │       │   # 需求卡片模板：5 个字段（需求基本信息、现状描述、痛点、问题本质还原、需求评估结果）。
│       │   │       ├── epic.md
│       │   │       │   # Epic 模板：9 个字段（需求背景、产品名称、产品定位、产品目标、用户角色、核心场景、产品价值、产品范围与边界、建设思路）。
│       │   │       ├── feature.md
│       │   │       │   # Feature 模板：12 个字段（需求背景、能力名称、能力描述、能力目标、用户角色、业务价值、业务场景、业务流程、业务规则、技术可行性、资源投入、优先级）。
│       │   │       ├── diagnostic-report.md
│       │   │       │   # 诊断报告模板：用于正式文档前的问题本质还原、需求转化、成熟度评分和待验证事项。
│       │   │       └── alternative-options.md
│       │   │           # 替代方案对比模板：用于比较至少两个方案的成本、时间、风险、ROI 和适用条件。
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
│           ├── prepare-intake.sh
│           │   # Intake 准备脚本：在项目类型确认前创建固定 docs/background/ intake 目录，不依赖项目模板。
│           ├── init-project.sh
│           │   # 新项目初始化脚本：识别 intake 目录、合并项目模板并保留背景材料，初始化 progress/refs/facts。跨平台（Windows Git Bash / macOS / Linux）。
│           ├── render-doc.sh
│           │   # 落盘渲染脚本：从字段 JSON（fields-*.json）读取最终润色值，按模板渲染为正式 Markdown 文档并写入项目目录。渲染后自动运行 validate-paradigm.sh 做范式校验。
│           ├── quick-persist.sh
│           │   # 快速落盘脚本：从独立字段 .md 文件直接渲染 Markdown，绕过 JSON 中间层，无转义问题。适用于 AI 并行写多个字段 .md 后一键渲染。
│           ├── validate-paradigm.sh
│           │   # 范式校验脚本：校验渲染后的 Markdown 是否符合 writing-paradigm/ 范式要求（加粗领条、表格、流程图、blockquote、过渡词等）。支持需求卡片 5 字段、Epic 8 字段、Feature 6 字段。
│           ├── validate-phase.sh
│           │   # 阶段机械校验脚本：检查项目产物是否存在、frontmatter 是否完整、refs.json 是否注册。
│           ├── export-doc-index.sh
│           │   # 文档索引导出脚本：扫描项目文档并导出索引，或生成 Mermaid 引用图。
│           ├── init-product-library.sh
│           │   # 产品库初始化脚本：支持从远程仓库克隆、从本地目录复制或全新创建空产品库。产品库不存在时由主调度器引导调用。
│           ├── validate-product-library.sh
│           │   # 产品库结构校验脚本：校验 ~/.product-library/ 目录结构、命名规则和元信息格式。每次 Skill 启动时自动调用。
│           ├── export-to-library.sh
│           │   # 产品库导出脚本：将已完成项目的正式产物复制到产品库对应目录，并更新 _product.md 元信息。项目完成后手动执行。
│           ├── convert-document.py
│           │   # 可选文档转换脚本：本机已有 Python/markitdown 时，将 PDF/Office/HTML/CSV/TXT 转成 Markdown。
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
| `skills/pm-orchestrator/SKILL.md` | 主入口。负责入口分流、项目恢复、状态机、阶段路由、快捷指令、阶段转换和用户确认 |
| `agents/requirement-analyst.md` | 需求分析专家。通过逐字段追问产出按写作范式结构化的需求卡片、Epic、Feature |
| `agents/story-breakdown-analyst.md` | 需求拆解专家。把 Feature 拆成 User Story、GWT 验收标准和溯源矩阵 |
| `agents/detailed-design-designer.md` | 详细设计专家。产出结构流程、原型、交互契约、规则摘要和 Sprint 规划 |
| `skills/pm-orchestrator/references/` | 各阶段 instruction、writing-paradigm、checklist、模板、示例和追溯模型 |
| `skills/pm-orchestrator/project-template/` | 新建产品项目时复制的项目骨架 |
| `skills/pm-orchestrator/product-library-spec.md` | 产品库规范：定义产品库目录结构、命名规则和产品匹配算法 |
| `skills/pm-orchestrator/scripts/` | 落盘渲染、范式校验、阶段校验、产品库校验/导出和文档索引辅助脚本 |

## 工作流

1. 用户触发 `pm-orchestrator` skill。
2. 主调度器先用完整命令调用 `validate-product-library.sh` 校验 `~/.product-library/` 目录结构，再根据用户本轮表达分流：提新需求进入需求分析 intake；明确继续、打开、切换或查看项目时才扫描并恢复已有项目。
3. 需求分析 intake 先生成 pending 项目记录 ID，调用 `prepare-intake.sh` 创建固定 `docs/background/` intake 目录并读取背景材料；随后读取 `references/requirement-analysis/instruction.md` 的“产品匹配与复用引导”和 `product-library-spec.md`，按需求卡片 → Epic → Feature 递进理解候选产品和用户业务目标，批量核对字段并只问一个最高价值问题；覆盖点、差异点和扩展方式清楚后，收敛项目类型（new / iteration / refactor），再用 `init-project.sh` 补全项目目录并保留背景材料。
4. 项目目录补全后，主调度器读取固定 `docs/background/` 中的背景材料摘要、产品匹配结果和已确认描述，再启动需求分析 agent。
5. 主调度器读取项目 `progress.json` 和 `phase-summary.md`。
6. 主调度器根据 `currentPhase` 委派对应 subagent，传递 `productLibraryDocs`、`matchedProductId`、`productLibraryMatch` 等上下文。
7. Subagent 以 `draft` 模式工作：逐字段追问用户，每轮回答后更新字段 JSON（`docs/_extracted/.fields/fields-*.json`）中的 `qa_log`（Q&A 素材）和最终润色值（按范式写出）。
8. 所有字段覆盖后，subagent 做范式自检，输出完整落盘预览请求用户确认。
9. 用户确认后，主调度器以 `persist` 模式要求 subagent 调用 `render-doc.sh` 从字段 JSON 渲染正式 Markdown，并自动运行 `validate-paradigm.sh` 做范式校验。
10. 阶段完成时，主调度器读取 checklist，运行校验脚本，再推进 `currentPhase`。`iteration`/`refactor` 项目额外校验已有产物是否被修改。

## Skill 特点

`pm-orchestrator` 同时具备产品设计流程能力和高质量询问能力：它不只是问问题，而是按产品产物、决策依赖、质量门和项目记忆，把用户的模糊想法推进成可评审、可拆解、可落盘、可追溯的设计资产。

### Skill 自身特点

- **主调度器 + 阶段专家分工**：主 skill 负责入口分流、项目恢复、阶段路由和用户确认；需求分析、需求拆解、详细设计分别交给独立 subagent。
- **产品架构最高原则**：所有阶段反复对照元数据驱动、职责边界清晰、平台化与通用能力三条原则，避免重复建设、职责漂移和场景硬编码。
- **需求分析 intake 的产品复用判断**：创建项目记录时先生成固定 `docs/background/` intake 目录并读取背景材料；随后按需求卡片 → Epic → Feature 递进解释已有产品，优先寻找可扩展路径，再形成覆盖点、差异点和 `new`、`iteration` 或 `refactor` 的项目类型选择。
- **跨会话项目记忆**：每个项目维护 `progress.json`、`phase-summary.md`、`facts.json`、`decision-log.md`、`tracking-log.md` 和 `refs.json`，支持中断后恢复上下文。
- **阶段化产品设计链路**：从需求卡片、Epic、Feature，到 User Story、GWT、溯源矩阵，再到结构流程、原型、交互契约、规则摘要和 Sprint 规划。
- **字段 JSON 中间层**：需求分析阶段先写 `docs/_extracted/.fields/fields-*.json`，保存最终润色值和 `qa_log`，再由脚本渲染正式 Markdown。
- **写作范式和机械校验**：通过 `writing-paradigm/` 约束字段写法，用 `validate-paradigm.sh` 校验加粗领条、表格、流程图、blockquote 等格式要求。
- **文档追溯模型**：所有正式文档带 frontmatter，用 `refs.json` 记录引用关系，并可导出文档索引或 Mermaid 图。
- **快捷指令和阶段控制**：支持 `!status`、`!list`、`!switch`、`!doc`、`!next`、`!back`、`!graph`。

### Skill 询问与推理特点

- **苏格拉底式追问**：不急着替用户包装方案，而是通过连续追问让用户自己确认真实痛点、业务本质、范围边界和取舍依据。
- **广度优先，不急着钻细节**：先摊开角色、场景、问题簇、能力候选和范围边界，避免一开始就被某个功能点带窄。
- **决策树式追问**：把需求拆成相互依赖的判断节点，先问会影响后续判断的上游问题，再进入下游字段和能力细节。
- **一次只问一个判断**：每轮只处理一个需要用户回答的问题；多个缺口同时存在时，按影响决策的程度选择下一问。
- **字段覆盖驱动**：追问服务于需求卡片、Epic、Feature 的必填字段；字段缺失时不输出正式草稿。
- **事实与决策分权**：能从项目文件、产品库、背景材料中查到的事实由系统查；范围、优先级、建设思路、资源取舍等决策必须由用户确认。
- **当前理解回执**：每轮追问前简短回收已确认内容、待验证缺口和当前追问范围，让用户及时纠偏。
- **候选项式提问**：尽量给出结构化选项，并保留“补充描述”和“强制跳过”，降低用户组织答案的负担。
- **反谄媚原则**：禁止用“这个方向很好”“可以考虑”“功能很重要”掩盖判断缺口；必须追问价值、证据、边界、成本和风险。
- **前提挑战**：遇到“做平台”“AI 赋能”“竞品都有”“领导要求”“都要做”等表达时，先追问用户证据、业务压力、验收口径、兜底责任和版本取舍。
- **问题本质还原**：不把“缺一个页面/按钮/模块”直接当需求，而是追问其背后的信息不对称、流程断点、数据缺失或决策滞后。
- **范围漂移防护**：输出文档前比较“拟输出范围”和“用户初始大问题”，防止 AI 把大需求写成单点小需求。
- **多问题闭环判断**：遇到多个痛点时，先判断它们是并列、因果、上下游，还是同一流程的不同环节，再决定合并或拆分。
- **证据优先与待验证标记**：关键数据优先来自用户或文件；无法确认的内容写成假设或待验证项，不伪造成事实。
- **替代方案对比**：用户需要时，可先输出诊断报告或替代方案对比，比较范围、成本、风险、ROI 和适用条件，再进入正式文档。
- **INVEST 拆解检查**：需求拆解阶段用 Independent、Negotiable、Valuable、Estimable、Small、Testable 检查每条 User Story 的颗粒度和质量。
- **GWT 验收追问**：每条 Story 必须落到 Given-When-Then 验收标准，确保需求能被开发、测试和业务共同验证。
- **异常分支模拟**：需求拆解和详细设计阶段主动枚举权限不足、数据为空、超限、超时、并发冲突、重复提交、格式错误等异常场景。
- **交互状态模拟**：详细设计阶段把原型当成交互定义，追问页面入口出口、状态机、流转规则、错误提示和兜底策略。
- **Sprint 依赖推演**：按优先级、依赖关系和风险把 Story 分配到 Sprint，预留缓冲并标注高风险项。
- **阶段性确认**：输出需求卡片、Epic、Feature、Story、原型、交互契约或 Sprint 前，都要先让用户确认草稿或关键判断。
- **询问过程可恢复**：每轮 Q&A 会进入字段 JSON 的 `qa_log`，中断后可从已回答字段继续。
- **草稿先行，确认后落盘**：询问阶段只生成草稿和完整预览；用户确认后才进入 `persist`，写正式文档并推进阶段。

### 需求分析阶段的字段 JSON 机制

需求分析阶段使用字段 JSON 作为落盘数据源，实现"会话中断可恢复"和"AI 写作有素材可查"：

- 每份文档（需求卡片/Epic/Feature）对应一个 `docs/_extracted/.fields/fields-*.json`
- JSON 包含两部分：**最终润色值**（按范式写出的丰富多行 markdown 内容）和 **`qa_log`**（按字段记录的全部 Q&A 对话素材）
- `render-doc.sh` 只读最终润色值渲染 Markdown，不读 `qa_log`
- 会话中断后重新进入时，读 JSON 检查哪些字段已填、哪些还空着，从中断处继续

### 写作范式体系

所有需求分析文档字段必须遵循 `writing-paradigm/` 中定义的范式：

- **6 条通用规律**：总结先行、加粗关键词领条、具名细节、结论跟"为什么"、诚实标注、视觉结构匹配内容
- **6 种语言范式**：A（总结+分条）、B（blockquote 论断+分要点）、C（定位+表格）、D（定位+流程图+特征）、E（分层+每层表格）、F（段落论证）
- **逐字段范式定义**：需求卡片 5 字段、Epic 9 字段、Feature 12 字段，每个字段指定使用哪种范式，并给出好差对比
- **机械校验**：`validate-paradigm.sh` 自动检查加粗领条、表格、流程图、blockquote 等格式要求

## 阶段路由

| currentPhase | Subagent | Reference | 主要产出 |
|--------------|----------|-----------|----------|
| `requirement-analysis` | `requirement-analyst` | `references/requirement-analysis/` | 需求卡片、Epic、Feature |
| `user-story-breakdown` | `story-breakdown-analyst` | `references/user-story-breakdown/` | User Story、GWT、溯源矩阵 |
| `detailed-design` | `detailed-design-designer` | `references/detailed-design/` | 结构流程、原型、交互契约、规则摘要、Sprint |

## 项目记忆

每个产品项目位于 `.claude/product-design-projects/<project-id>/`，包含：

| 文件 | 作用 |
|------|------|
| `progress.json` | 项目名片与状态：项目 ID、名称、类型、匹配产品 ID（`matchedProductId`）、产品匹配度（`productLibraryMatch`）、短描述、当前阶段、阶段状态、时间戳 |
| `refs.json` | 文档节点索引和引用关系图谱 |
| `facts.json` | 已确认结构化事实（每条标注来源类型） |
| `decision-log.md` | 决策结论、理由、被否定的备选方案 |
| `tracking-log.md` | 假设、风险、未决问题 |
| `phase-summary.md` | 阶段恢复摘要：产物清单、关键结论、遗留问题、下一步 |

字段 JSON 中间文件存放在 `docs/_extracted/.fields/fields-*.json`，是过程状态文件，不与正式 Markdown 产物混放。

正式产出写入项目的 `docs/`：

- `docs/requirement-analysis/`：需求卡片、Epic、Feature
- `docs/design/`：User Story、溯源矩阵、结构流程、原型、交互契约
- `docs/execution/`：规则摘要、Sprint 规划

## 校验

### 范式校验

落盘时 `render-doc.sh` 自动运行 `validate-paradigm.sh`，也可手动运行：

```bash
bash skills/pm-orchestrator/scripts/validate-paradigm.sh "<渲染后的 Markdown 文件>"
```

校验内容：分条列点是否用加粗关键词领条、范式 C 字段是否有表格、范式 D 字段是否有流程图、范式 B 字段是否有 blockquote 核心论断、范式 F 字段是否有过渡词。零警告才能落盘。

### 阶段校验

阶段转换时可运行：

```bash
bash skills/pm-orchestrator/scripts/validate-phase.sh \
  --project-root "<项目根目录>" \
  --project-path "<项目路径>" \
  --phase requirement-analysis
```

### 文档索引

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

### 产品库校验与导出

每次 Skill 启动时自动校验产品库结构，也可手动运行：

```bash
bash skills/pm-orchestrator/scripts/validate-product-library.sh \
  "$HOME/.product-library" \
  skills/pm-orchestrator/product-library-spec.md
```

项目完成后，可将正式产物导出到产品库：

```bash
bash skills/pm-orchestrator/scripts/export-to-library.sh \
  "<项目目录>" \
  "~/.product-library/<product-id>" \
  "<skillPath>"
```

导出后需手动更新 `_manifest.md` 并通过 git 上传到远程仓库。

### 文档转换（可选）

将用户提供的 PDF、Word、PPT、Excel、HTML、CSV 或 TXT 转成 Markdown：

```bash
python skills/pm-orchestrator/scripts/convert-document.py "<输入文件路径>" -o "<输出.md>" --metadata-output "<metadata.json>"
```

该脚本不联网、不自动安装依赖、不写项目记忆文件。它依赖真实可用的 Python 3 环境和 Python 包 `markitdown`；没有 Python 时不影响新建项目、阶段校验、文档索引和引用图，只需让用户提供已转 Markdown、文本摘录或直接粘贴关键内容。如环境需要安装依赖，先运行：

```bash
python -m pip install markitdown
```

## 设计原则

- 以元数据作为资源管理能力的核心驱动，各产品围绕统一资源模型协同工作
- 各产品及公共能力聚焦自身领域能力，避免重复建设和功能交叉；能力重叠或职责不清时进入架构评审
- 优先沉淀通用能力、原子能力和可配置能力，避免针对具体业务场景或具体用户问题硬编码
- 主 skill 只做调度，不替代 subagent 的专业工作
- 每次只推进一个阶段
- 草稿先确认，确认后落盘
- reference 按阶段渐进加载
- 所有正式文档必须带 frontmatter，并注册到 `refs.json`
- 所有字段必须遵循 `writing-paradigm/` 范式，落盘前通过 `validate-paradigm.sh` 机械校验
- 字段 JSON 持续记录 `qa_log` 素材和最终润色值，支持会话中断恢复
