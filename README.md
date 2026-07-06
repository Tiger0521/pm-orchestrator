# pm-orchestrator Plugin

`pm-orchestrator` 是一个产品全流程设计插件。它把原来的单一 skill 改造成：

- 一个主调度 skill：负责项目选择、跨会话恢复、阶段路由、用户确认和质量门
- 三个独立 subagent：分别负责需求分析、需求拆解、详细设计

目标是让用户从「模糊想法」一路走到「可开发执行」的产品设计资产，同时保留项目记忆和文档追溯关系。

---

## 架构

```text
pm-orchestrator/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── requirement-analyst.md
│   ├── story-breakdown-analyst.md
│   └── detailed-design-designer.md
├── skills/
│   └── pm-orchestrator/
│       ├── SKILL.md
│       ├── current-project.json
│       ├── references/
│       ├── scripts/
│       ├── project-template/
│       └── evals/
└── README.md
```

## 职责分工

| 组件 | 职责 |
|------|------|
| `skills/pm-orchestrator/SKILL.md` | 主入口。负责项目选择、状态机、阶段路由、快捷指令、阶段转换和用户确认 |
| `agents/requirement-analyst.md` | 需求分析专家。通过追问和诊断产出需求卡片、Epic、Feature |
| `agents/story-breakdown-analyst.md` | 需求拆解专家。把 Feature 拆成 User Story、GWT 验收标准和溯源矩阵 |
| `agents/detailed-design-designer.md` | 详细设计专家。产出结构流程、原型、交互契约、规则摘要和 Sprint 规划 |
| `skills/pm-orchestrator/references/` | 各阶段 instruction、checklist、模板、示例和追溯模型 |
| `skills/pm-orchestrator/project-template/` | 新建产品项目时复制的项目骨架 |
| `skills/pm-orchestrator/scripts/` | 阶段校验和文档索引辅助脚本 |

## 工作流

1. 用户触发 `pm-orchestrator` skill。
2. 主调度器扫描 `.claude/product-design-projects/`，让用户选择继续或新建项目。
3. 主调度器读取项目 `progress.json` 和 `phase-summary.md`。
4. 主调度器根据 `currentPhase` 委派对应 subagent。
5. Subagent 以 `draft` 模式输出问题、诊断或文档草稿。
6. 用户确认后，主调度器再以 `persist` 模式要求 subagent 落盘正式文档。
7. 阶段完成时，主调度器读取 checklist，必要时运行校验脚本，再推进 `currentPhase`。

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
| `progress.json` | 当前阶段和阶段状态 |
| `refs.json` | 文档节点和引用关系 |
| `facts.json` | 已确认事实 |
| `decision-log.md` | 决策结论和理由 |
| `tracking-log.md` | 假设、风险、未决问题 |
| `phase-summary.md` | 阶段摘要 |

正式产出写入项目的 `docs/`：

- `docs/strategic/`
- `docs/requirement/`
- `docs/design/`
- `docs/execution/`

## 快捷指令

快捷指令由主调度器直接处理，不触发 subagent：

| 指令 | 作用 |
|------|------|
| `!status` | 查看当前项目进度、当前阶段、最近文档 |
| `!list` | 列出所有产品设计项目 |
| `!switch <project-id>` | 切换项目 |
| `!doc <doc-id>` | 展示指定文档 |
| `!next` | 校验并推进阶段 |
| `!back` | 回退阶段 |
| `!graph` | 展示文档引用关系 |

## 校验

阶段转换时可运行：

```powershell
.\skills\pm-orchestrator\scripts\validate-phase.ps1 -projectPath "<项目路径>" -phase requirement-analysis
```

导出项目文档索引：

```powershell
.\skills\pm-orchestrator\scripts\export-doc-index.ps1 -projectPath "<项目路径>"
```

## 设计原则

- 主 skill 只做调度，不替代 subagent 的专业工作
- 每次只推进一个阶段
- 草稿先确认，确认后落盘
- reference 按阶段渐进加载
- 所有正式文档必须带 frontmatter，并注册到 `refs.json`
