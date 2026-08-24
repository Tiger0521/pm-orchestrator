# pm-orchestrator

产品全流程设计主调度器。把模糊的产品想法，推进为已确认、可直接写入产品库、可追溯、可继续迭代的产品设计资产。

**一句话**：你说一个想法，它帮你完成从需求分析到详细设计的全流程。

---

## 一、工作流程概览

使用 `pm-orchestrator` 会经历以下几个流程。理解这些流程，你就知道什么时候该做什么、什么时候流程会走完。

### 前置依赖：产品库

**使用本 skill 前，你需要先有一个产品库。** 产品库是存放产品设计文档的目录，包含产品目录、需求文档、设计文档等。没有产品库，skill 无法工作。

产品库的获得方式：
- 从 Git 远程仓库克隆
- 使用你已有的本地产品库路径
- skill 会自动从当前目录向上最多 3 层查找 `product-library/`

### 流程一：需求分析

**入口**：用户说"我想做个产品"、"帮我梳理需求"

**过程**：主调度器 → 委派 `requirement-analyst` → 逐轮追问（背景、用户、功能） → 产出需求卡片 + Epic → 用户确认 → 写入产品库 → 继续拆解 Feature → 全部 Feature 写入产品库

**结束标志**：需求卡片、Epic 和所有 Feature 均已写入产品库。此时可进入"需求拆解"阶段。

### 流程二：需求拆解

**入口**：需求分析完成后，用户提出继续拆解

**过程**：主调度器 → 委派 `story-breakdown-analyst` → 逐轮追问每个 Feature → 拆分为 User Story + GWT 验收标准 → 用户确认 → 写入产品库 `用户故事/` 目录 + 生成溯源矩阵

**结束标志**：所有 Story 和溯源矩阵已写入产品库。**落盘完成后自动进入"用户故事地图生成"**，不需要用户额外提出。

### 流程三：用户故事地图生成

**入口**：需求拆解完成后自动进入，或用户直接说"生成故事地图"

**过程**：主调度器 → 委派 `story-map-designer` → 逐个能力迭代（自检→提问→生成→确认→落盘） → 所有能力地图完成 → 生成总览地图

**结束标志**：所有能力地图和总览地图均已写入产品库的 `用户故事地图/` 目录。这是一个独立流程，不改变项目阶段状态。

### 流程四：详细设计（四步）

**入口**：需求拆解（或故事地图）完成后，用户提出继续详细设计

**过程**：主调度器 → 委派 `detailed-design-designer` → 按 Step 1→2→3→4 顺序推进，每个 Step 完成后经用户确认才进入下一步：

| Step | 做什么 | 产出 |
|------|--------|------|
| **Step 1** 功能架构与动线规划 | grilling 决策域 → 业务流文档 → 页面映射表 → 两张 HTML 图 | 产品库 `详细设计/结构与流程图/` |
| **Step 2** 原型设计与规范对齐 | 确定平台/UI风格 → 生成交互式 HTML 原型（含标注层） → 设计自检 | 产品库 `详细设计/原型/` |
| **Step 3** 交互规则与边界补全 | 穷举异常分支 → 交互契约（状态机/权限/边界） → 规则摘要 | 产品库 `详细设计/` |
| **Step 4** Sprint 分解 | 按弹性和依赖分解 Sprint → Sprint 规划 | 产品库 `详细设计/` |

**结束标志**：四步全部完成，经用户确认后阶段状态变为 `completed`。

### 流程五：原型修改（独立模式）

**入口**：用户对已有交互式 HTML 原型提出修改请求

**过程**：主调度器 → 委派 `detailed-design-designer` → 升版本号 → 加/改注释 → 高亮标记 → 更新版本栏 → 旧版另存为快照 → 新版写入产品库

**结束标志**：修改后的原型文件写入产品库。不改变阶段状态。

### 流程六：修补产品库能力分类（独立模式）

**入口**：用户说"修补产品库能力分类"、"重新归类能力"

**过程**：主调度器 → 以 `fix-category` 模式委派 `requirement-analyst` → 操作产品库能力文档

**结束标志**：能力分类修补完成。不涉及过程项目，不改变阶段状态。

---

## 二、安装与更新

仓库地址：[github.com/Tiger0521/pm-orchestrator](https://github.com/Tiger0521/pm-orchestrator)

### 首次安装（拷文件夹即用）

**两种宿主都只要把整个 skill 文件夹拷到对应的 skills 目录，重启即可用。**

- **Claude Code**：把整个 `pm-orchestrator/` 文件夹拷到 `~/.claude/skills/pm-orchestrator`。目录自带 `.claude-plugin/plugin.json`，Claude 重启后自动识别为插件，`agents/` 下的 4 个 agent 自动获得 `pm-orchestrator:` 命名空间。
- **ZCode**：把整个 `pm-orchestrator/` 文件夹拷到 `~/.zcode/skills/pm-orchestrator`。ZCode 不扫描 skill 文件夹内的 agent 文件，每次运行本 skill 时自动自检自举，把 `agents/zcode/` 中缺失的 agent 补到 `~/.zcode/agents/`。

`install.ps1` 是**可选**便捷工具（用于预置 subagent、做干净的整包重装），不是必需步骤。

### 更新

```powershell
git pull --ff-only origin main
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target claude   # 或 -Target zcode
```

拉取后重装，重启目标客户端即可生效。

### 安装结果

安装后，最终在目标宿主上得到一致结构：

1. **skill 本体**：`SKILL.md`、`references/`、`runtime/`、`agents/`、`scripts/`、`project-template/` 放进目标宿主 skills 目录
2. **subagent 落点**：
   - Claude Code：无需投递——`.claude-plugin/plugin.json` 自动注册
   - ZCode：由 skill **每次运行时自检**，自动补齐到 `~/.zcode/agents/`

### 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| V4.0.2 | 2026-08-21 | 更新 README：补充完整调用关系流程图 |
| V4.0.1 | 2026-08-21 | 修复产品库命名和 obsidian 引用格式 |
| V4.0.0 | 2026-08-21 | 支持 zcode 使用，完成详细设计 step1+step2，可生成原型 |

---

## 三、目录结构

```
pm-orchestrator/                          ← git 仓库根 = skill 本体
│
├── SKILL.md                              ← 主调度入口 + 运行时识别门
├── README.md
├── .gitignore
├── install.ps1                           ← 统一安装脚本（可选）
├── .claude-plugin/
│   └── plugin.json                       ← Claude Code 插件注册
│
├── runtime/                              ← 运行时机制层
│   ├── claude.md                         ← Claude Code 机制（命名/项目根/路径解析）
│   └── zcode.md                          ← ZCode 机制（自检自举/Agent 工具/路径解析）
│
├── agents/                               ← Subagent 定义
│   ├── requirement-analyst.md            ← Claude Code 版（平铺，插件自动命名空间）
│   ├── story-breakdown-analyst.md
│   ├── detailed-design-designer.md
│   ├── story-map-designer.md
│   └── zcode/                            ← ZCode 版（分发副本）
│       ├── requirement-analyst.md
│       ├── story-breakdown-analyst.md
│       ├── detailed-design-designer.md
│       └── story-map-designer.md
│
├── references/                           ← 方法论、模板、质量门（双平台共用）
│   │
│   ├── orchestrator/                     ← 主调度器操作协议
│   │   ├── operations.md                 ← 委派、返回、记忆、安全协议
│   │   ├── output-format.md              ← 输出规范
│   │   ├── phase-transition.md           ← 阶段迁移规则
│   │   ├── product-library-context.md    ← 产品库确认流程
│   │   └── shortcut-commands.md          ← ! 快捷指令
│   │
│   ├── orchestrator-operations.md        ← 共享操作协议主文件
│   │
│   ├── product-library/
│   │   └── contract.md                   ← 产品库契约（命名/frontmatter/层级/链接）
│   │
│   ├── shared/
│   │   └── traceability-model.md         ← 共享追溯模型
│   │
│   ├── requirement-analysis/             ← 需求分析阶段
│   │   ├── instruction.md                ← 整体指令
│   │   ├── guides/                       ← 方法论指南
│   │   │   ├── checklist.md              ← 质量门清单
│   │   │   ├── evidence-and-input.md     ← 证据与输入
│   │   │   ├── product-matching.md       ← 产品匹配
│   │   │   ├── capability-classification.md  ← 能力分类
│   │   │   ├── quality-and-interaction.md    ← 质量与交互
│   │   │   └── question-bank.md          ← 问题库
│   │   ├── workflows/                    ← 工作流
│   │   │   ├── intake.md                 ← 新需求受理
│   │   │   ├── draft.md                  ← 需求分析草稿
│   │   │   ├── persist.md                ← 写入产品库
│   │   │   ├── diagnostic.md             ← 诊断
│   │   │   └── fix-category.md           ← 修补能力分类
│   │   ├── templates/                    ← 模板
│   │   │   ├── requirement-card.md
│   │   │   ├── epic.md
│   │   │   ├── feature.md
│   │   │   ├── diagnostic-report.md
│   │   │   └── alternative-options.md
│   │   └── writing-paradigm/             ← 写作范式
│   │       ├── general-rules.md
│   │       ├── requirement-card.md
│   │       ├── epic.md
│   │       └── feature.md
│   │
│   ├── user-story-breakdown/             ← 需求拆解阶段
│   │   ├── instruction.md
│   │   ├── workflow.md
│   │   ├── grilling-protocol.md          ← 追问协议
│   │   ├── confirmation-method.md        ← 确认方法
│   │   ├── core-mechanisms.md            ← 核心机制
│   │   ├── checklist.md                  ← 质量门
│   │   ├── output-contract.md            ← 产出契约
│   │   ├── persist-guide.md              ← 落盘指南
│   │   ├── templates/
│   │   │   ├── user-story.md
│   │   │   └── traceability-matrix.md
│   │   ├── writing-paradigm/
│   │   │   └── user-story-writing.md
│   │   └── examples/
│   │       └── model-config-stories.md
│   │
│   ├── detailed-design/                  ← 详细设计阶段
│   │   ├── instruction.md                ← 整体调度 + 4 步路由
│   │   ├── shared/                       ← 跨 Step 共享机制
│   │   │   ├── upstream-quality-gate.md  ← 上游质量门
│   │   │   ├── grilling-protocol.md      ← 问答协议
│   │   │   ├── confirmation-method.md    ← 确认流程
│   │   │   ├── design-review.md          ← 设计审查五维度
│   │   │   ├── persist-guide.md          ← 落盘轨道
│   │   │   ├── output-contract.md        ← 产出字段契约
│   │   │   ├── design-writing.md         ← 设计写作规范
│   │   │   ├── checklist.md              ← 质量门清单
│   │   │   ├── scale-adaptation.md       ← 规模自适应
│   │   │   ├── templates/                ← render-doc.sh 渲染模板
│   │   │   │   ├── structure-flow.md
│   │   │   │   ├── prototype.md
│   │   │   │   ├── interaction-contract.md
│   │   │   │   ├── rules-summary.md
│   │   │   │   └── sprint.md
│   │   │   └── examples/
│   │   │       └── model-config-design.md
│   │   │
│   │   ├── step1-功能架构与动线规划/      ← Step 1
│   │   │   ├── workflow.md
│   │   │   ├── business-flow-writing.md
│   │   │   ├── page-mapping.md
│   │   │   └── html-diagram.md
│   │   │
│   │   ├── step2-原型设计与规范对齐/      ← Step 2
│   │   │   ├── workflow.md
│   │   │   ├── prototype-method.md
│   │   │   ├── annotation-overlay.md
│   │   │   ├── ui-design-style.md
│   │   │   ├── ui-style-presets/          ← 20+ 套 UI 风格预设
│   │   │   │   ├── README.md
│   │   │   │   ├── admin-backend-{dark,industrial,minimal}.md
│   │   │   │   ├── mini-program-{chinese,pastel}.md
│   │   │   │   ├── mobile-app-{art-deco,glassmorphism,material,pastel,vibrant}.md
│   │   │   │   ├── web-app-{gradient,industrial,minimal}.md
│   │   │   │   ├── web-dashboard-{dark,industrial,minimal,retro,zen}.md
│   │   │   │   └── web-landing-{brutalist,chinese,luxury,magazine}.md
│   │   │   └── pm-prototype-prd/          ← 内嵌子技能：交互式 HTML + 标注引擎
│   │   │       ├── SKILL.md
│   │   │       ├── assets/
│   │   │       │   └── prototype-framework.js
│   │   │       └── references/
│   │   │           ├── prototype-guide.md
│   │   │           └── prd-template.md
│   │   │
│   │   ├── step3-交互规则与边界补全/
│   │   │   └── workflow.md
│   │   │
│   │   └── step4-Sprint分解/
│   │       └── workflow.md
│   │
│   ├── story-map/                        ← 用户故事地图阶段
│   │   ├── instruction.md
│   │   ├── workflow.md
│   │   ├── core-mechanisms.md
│   │   ├── checklist.md
│   │   ├── output-contract.md
│   │   ├── persist-guide.md
│   │   ├── guides/
│   │   │   ├── journey-extraction.md
│   │   │   ├── story-placement.md
│   │   │   └── walking-skeleton.md
│   │   ├── templates/
│   │   │   ├── capability-map.md
│   │   │   └── overview-map.md
│   │   └── writing-paradigm/
│   │       └── map-writing.md
│   │
│   └── vendor/                           ← 第三方工具
│       └── archify/                      ← 架构图渲染工具
│           ├── SKILL.md
│           ├── bin/
│           ├── renderers/
│           ├── schemas/
│           ├── references/
│           ├── examples/
│           ├── test/
│           ├── brand-marks/
│           ├── delta/
│           └── recipes/
│
├── scripts/                              ← 工具脚本
│   ├── 项目初始化
│   │   ├── prepare-intake.sh             ← 创建 intake 目录 + progress.json
│   │   └── init-project.sh               ← 合并项目模板，初始化项目
│   │
│   ├── 渲染与落盘
│   │   ├── render-doc.sh                 ← 字段 JSON → 产品库文档
│   │   ├── render-story.sh               ← Story JSON → 用户故事
│   │   ├── render-matrix.sh              ← 矩阵 JSON → 溯源矩阵
│   │   └── quick-persist.sh              ← 快速渲染 Markdown
│   │
│   ├── 校验
│   │   ├── validate-phase.sh             ← 阶段产物校验
│   │   ├── validate-phase.ps1            ← PowerShell 版
│   │   ├── validate-paradigm.sh          ← 写作范式校验
│   │   ├── validate-story.sh             ← 用户故事规范校验
│   │   ├── validate-product-library.sh   ← 产品库全量校验
│   │   └── validate-product-library-lite.sh  ← 产品库快速校验
│   │
│   ├── 产品库管理
│   │   ├── acquire-product-library.sh    ← Git 克隆/更新产品库
│   │   ├── product-library-tools.mjs     ← 对账工具（reconcile）
│   │   ├── backfill-library-ids.mjs      ← 回填继承式 ID
│   │   └── rename-product.sh             ← 产品简称变更
│   │
│   ├── 状态与迁移
│   │   ├── transition-project-state.sh   ← 原子更新 workflow.state
│   │   └── migrate-story-layout.ps1      ← Story 布局迁移
│   │
│   ├── 导出
│   │   ├── export-doc-index.sh           ← 文档索引/Mermaid 引用图
│   │   ├── export-doc-index.ps1          ← PowerShell 版
│   │   └── export-to-library.sh          ← 【已废弃】旧版导出
│   │
│   └── 其他
│       └── convert-document.py           ← Word/PPT/Excel → Markdown
│
└── project-template/                     ← 过程项目骨架
    ├── progress.json                     ← 项目名片 + workflow.state
    ├── refs.json                         ← 文档节点 + 引用关系
    ├── facts.json                        ← 已确认结构化事实
    ├── phase-summary.md                  ← 跨会话恢复摘要
    ├── decision-log.md                   ← 决策记录
    └── tracking-log.md                   ← 假设、风险、未决问题
```

---

## 四、核心调用流程图

### 1. 主调度流程（总图）

```mermaid
flowchart TD
    Start([用户输入]) --> Shortcut{以 ! 开头？}
    Shortcut -- 是 --> Cmd[执行快捷指令<br/>!status / !list / !switch / !doc / !graph / !next / !back]
    Cmd --> Wait([等待下一轮输入])

    Shortcut -- 否 --> RuntimeDetect{运行时识别}
    RuntimeDetect -->|具备 Agent 工具 + ZCode 解析能力| ZCode[固化 RUNTIME=zcode<br/>运行 subagent 自检自举]
    RuntimeDetect -->|插件命名空间解析能力| Claude[固化 RUNTIME=claude<br/>插件自动注册 pm-orchestrator: 前缀]

    ZCode --> Library
    Claude --> Library

    Library[定位候选 product-library<br/>从当前目录向上最多 3 层] --> LibraryOK{用户确认且校验通过？}

    LibraryOK -- 否 --> Acquire[从 Git 获取产品库<br/>或提供已有本地路径]
    Acquire --> Library

    LibraryOK -- 是 --> Project{继续已有过程项目？}

    Project -- 是 --> Restore[读取 progress.json<br/>读取 phase-summary.md<br/>校验产品库一致性<br/>运行对账脚本 reconcile]
    Restore --> State{workflow.state}

    State -- requirement-analysis --> RA[委派 requirement-analyst]
    State -- user-story-breakdown --> SB[委派 story-breakdown-analyst]
    State -- detailed-design --> DD[委派 detailed-design-designer]
    State -- completed --> Report([汇报项目已完成])

    Project -- 否 --> Intent{本轮意图分类}

    Intent -- 需求分析 --> Intake[创建新 intake 项目<br/>mode=intake 委派 requirement-analyst]
    Intent -- 需求拆解 --> NewSB[选择产品库已有产品<br/>init-project.sh 创建 iteration 项目<br/>mode=draft → story-breakdown-analyst]
    Intent -- 详细设计 --> NewDD[选择产品库已有产品<br/>init-project.sh 创建 iteration 项目<br/>mode=draft → detailed-design-designer]
    Intent -- 故事地图 --> SM[独立模式<br/>mode=generate → story-map-designer]
    Intent -- 修补能力分类 --> FC[独立模式<br/>mode=fix-category → requirement-analyst]
    Intent -- 原型修改 --> PM[独立模式<br/>传递参考路径 → detailed-design-designer]
```

### 2. Subagent 返回状态路由

```mermaid
flowchart LR
    Result([Subagent 返回]) --> Status{status}

    Status -- needs-input --> Ask[展示问题<br/>等待用户补充信息]
    Ask --> ReDelegate[下一轮重新委派]

    Status -- intake-initialized --> ReRead[重新读取项目状态]
    ReRead --> RARedelegate[以 mode=draft 委派 requirement-analyst]

    Status -- draft-ready --> Preview[完整展示草稿正文<br/>请求用户确认写入产品库]
    Preview --> WaitInput([等待确认])

    Status -- persisted --> Artifact{artifactScope}

    Artifact -- requirement-epic --> ContinueFeature[继续 Feature 批次<br/>mode=draft → requirement-analyst]
    Artifact -- features --> PhaseComplete[需求分析阶段完成<br/>等待阶段迁移或用户指令]
    Artifact -- stories --> AutoStoryMap[自动进入故事地图生成<br/>mode=generate → story-map-designer]
    Artifact -- 其他 --> Continue[检查索引与阶段记忆<br/>下一轮继续]

    Status -- validation-pass --> ShowResult[展示校验结果<br/>请求用户确认阶段迁移]
    Status -- validation-failed --> ShowFail[展示缺失项<br/>停留当前阶段]
    Status -- blocked --> Blocked([展示阻断原因<br/>停止推进])

    Status -- map-draft-ready --> ShowMap[展示地图草稿<br/>请求确认]
    Status -- map-persisted --> NextCapability[自动重新委派<br/>处理下一个能力或总览]
    Status -- map-complete --> MapDone([故事地图全部完成])

    Status -- fix-category-completed --> FixDone([展示修补摘要])
```

### 3. 需求分析阶段

```mermaid
flowchart TD
    Intake([委派 mode=intake]) --> Q1[逐轮追问<br/>背景收集 · 产品匹配 · 项目类型确认]
    Q1 --> Initialized{返回 intake-initialized}
    Initialized --> DraftEpisode[委派 mode=draft<br/>artifactScope=requirement-epic]

    DraftEpisode --> DraftQ[逐轮追问<br/>核心用户 · 目标 · 功能边界]
    DraftQ --> DraftReady{返回 draft-ready}
    DraftReady --> Confirm1[展示需求卡片 + Epic 预览<br/>请求用户确认]
    Confirm1 --> Persist1[调用 render-doc.sh<br/>写入产品库]

    Persist1 --> FeatureEpisode[委派 mode=draft<br/>artifactScope=features]
    FeatureEpisode --> FeatureQ[逐轮拆解每个 Feature<br/>能力分类 · 字段确认]
    FeatureQ --> FeatureReady{返回 draft-ready}
    FeatureReady --> Confirm2[展示 Feature 预览<br/>请求用户确认]
    Confirm2 --> Persist2[调用 render-doc.sh<br/>写入产品库]

    Persist2 --> PhaseDone[需求分析阶段完成<br/><br/>可迁移到 user-story-breakdown<br/>或等待其他指令]
```

### 4. 需求拆解 → 自动进入故事地图

```mermaid
flowchart TD
    StartSB([委派 mode=draft]) --> Q[逐轮追问每个 Feature<br/>→ 拆分为 User Story<br/>→ 编写 GWT 验收标准]
    Q --> DraftReady{返回 draft-ready}
    DraftReady --> ShowStory[展示 Story 草稿<br/>请求用户确认]
    ShowStory --> PersistStory[批量渲染用户故事<br/>写入产品库 用户故事/ 目录<br/>生成溯源矩阵]

    PersistStory --> AutoSM[**自动进入用户故事地图生成**<br/>mode=generate → story-map-designer<br/><br/>不询问用户去向<br/>如用户明确要求详细设计<br/>才执行阶段迁移]

    subgraph SM[用户故事地图生成]
        SM1[读取能力文档] --> SM2[自我分析 → 返回 needs-input]
        SM2 --> SM3[展示自检结论 + 提问]
        SM3 --> SM4[用户确认方向]
        SM4 --> SM5[生成能力地图草案]
        SM5 --> SM6[展示预览 → 用户确认]
        SM6 --> SM7[写入产品库 用户故事地图/]
        SM7 --> SM8{还有下一能力？}
        SM8 -- 是 --> SM1
        SM8 -- 否 --> SM9[生成总览地图]
    end

    AutoSM --> SM1
    SM9 --> MapDone([故事地图全部完成])
```

### 5. 详细设计四步路由

```mermaid
flowchart TD
    StartDD([委派 mode=draft]) --> StepRoute{定位当前 Step}

    StepRoute -->|无 Step 1 产物| Step1
    StepRoute -->|Step 1 未完成| Step1
    StepRoute -->|Step 1 完成 · 无原型| Step2
    StepRoute -->|Step 2 完成 · 无交互契约| Step3
    StepRoute -->|Step 3 完成 · 无 Sprint| Step4
    StepRoute -->|全部完成| AllDone([全部完成])

    subgraph Step1[Step 1: 功能架构与动线规划]
        S1_1[读取上游 User Story] --> S1_2[grilling 敲定决策域<br/>信息结构 · 导航]
        S1_2 --> S1_3[产出业务流文档]
        S1_3 --> S1_4[产出页面映射表]
        S1_4 --> S1_5[生成两张 HTML 图<br/>信息架构图 · 动线图]
        S1_5 --> S1_6[用户确认 → 直接写入产品库<br/>草稿即正式，不走 JSON 渲染]
    end

    subgraph Step2[Step 2: 原型设计与规范对齐]
        S2_1[读取 Step 1 产物] --> S2_2[grilling 决策域<br/>平台 · UI 风格 · 布局模式]
        S2_2 --> S2_3[生成方式固定<br/>交互式 HTML 唯一方式]
        S2_3 --> S2_4[构建交互式 HTML 原型<br/>含 prototype-framework.js 标注层]
        S2_4 --> S2_5[设计自检五维度]
        S2_5 --> S2_6[用户确认 → 写入产品库<br/>详细设计/原型/]
    end

    subgraph Step3[Step 3: 交互规则与边界补全]
        S3_1[读取 Step 1-2 产物] --> S3_2[穷举异常分支]
        S3_2 --> S3_3[编写交互契约<br/>状态机 · 权限 · 边界]
        S3_3 --> S3_4[编写规则摘要]
        S3_4 --> S3_5[用户确认 → 写入产品库<br/>render-doc.sh 渲染]
    end

    subgraph Step4[Step 4: Sprint 分解]
        S4_1[读取 Step 1-3 全部产出] --> S4_2[按弹性和依赖分解 Sprint]
        S4_2 --> S4_3[产出 Sprint 规划]
        S4_3 --> S4_4[用户确认 → 写入产品库<br/>render-doc.sh 渲染]
    end

    Step1 --> UserConfirm1{用户确认}
    UserConfirm1 -- 是 --> StepRoute
    UserConfirm1 -- 否 --> Step1

    Step2 --> UserConfirm2{用户确认}
    UserConfirm2 -- 是 --> StepRoute
    UserConfirm2 -- 否 --> Step2

    Step3 --> UserConfirm3{用户确认}
    UserConfirm3 -- 是 --> StepRoute
    UserConfirm3 -- 否 --> Step3

    Step4 --> UserConfirm4{用户确认}
    UserConfirm4 -- 是 --> StepRoute
    UserConfirm4 -- 否 --> Step4
```

### 6. 原型修改路由（独立模式）

```mermaid
flowchart LR
    Request([用户请求修改已有原型]) --> Route{有过程项目上下文？}

    Route -- 是 --> DDSimple[委派 detailed-design-designer<br/>传递 3 条 reference 路径]
    Route -- 否 --> ReadGate[读取 pm-prototype-prd/SKILL.md<br/>核对「修改模式执行前必读」4 步门禁]
    ReadGate --> DDComplex[委派 detailed-design-designer]

    DDSimple --> Step[修改模式 4 步流程]
    DDComplex --> Step

    subgraph Step[修改模式 4 步]
        S1[升版本号<br/>原型内版本栏更新] --> S2[加/改注释<br/>更新标注层]
        S2 --> S3[高亮标记改动区域<br/>框选坐标 + 描述]
        S3 --> S4[更新版本标注栏<br/>版本记录 + 变更说明]
    end

    Step --> DraftPreview[draft-ready → 展示修改方案]
    DraftPreview --> UserConfirm{用户确认}
    UserConfirm -- 是 --> Archive[旧版另存为快照<br/>写入过程文件夹]
    Archive --> WriteNew[新版写入产品库<br/>详细设计/原型/]
    UserConfirm -- 否 --> Revise[调整后重新预览]
```

### 7. 运行时识别与委派对比

```mermaid
flowchart TD
    Start([会话开始]) --> Detect{识别宿主}
    Detect -->|是 Claude Code| Claude[固化 RUNTIME=claude]
    Detect -->|是 ZCode| ZCode[固化 RUNTIME=zcode]

    Claude --> ClaudeSub[委派方式<br/>命名子 Agent<br/>pm-orchestrator:<name>]
    Claude --> ClaudeRef[Reference 解析<br/>相对 skillPath<br/>插件上下文直接解析]
    Claude --> ClaudePlugin[插件注册<br/>.claude-plugin/plugin.json<br/>自动命名空间]

    ZCode --> ZCodeSub[委派方式<br/>Agent 工具<br/>subagent_type=<裸名>]
    ZCode --> ZCodeRef[Reference 解析<br/>经 ${skillPath} 拼接]
    ZCode --> ZCodeSelf[Subagent 来源<br/>每次运行时自检自举<br/>agents/zcode/ → ~/.zcode/agents/]

    ClaudeSub --> Same[两运行时共用一套<br/>方法论 references/<br/>项目根统一<br/>产品库契约统一]
    ZCodeSub --> Same
```

---

## 产品库

每次使用 skill 前，主调度器都会确认一个产品库。自动发现规则：从当前目录向上最多 3 层查找 `product-library/`。

### 产品库结构

```
product-library/
├── 架构设计.md                      ← 根标识文档（唯一匹配 ^.+架构设计\\.md$）
├── 产品A全名/                       ← 按产品全名命名的目录
│   ├── 简称-需求卡片.md              ← 需求卡片（继承式 ID）
│   ├── 简称-Epic1.md                 ← Epic 文档
│   ├── 简称-能力文档-能力名.md        ← 能力文档
│   ├── 简称-F001-功能名.md            ← Feature 文档
│   ├── 用户故事/
│   │   ├── 名称故事.md               ← User Story
│   │   └── ...
│   ├── 详细设计/
│   │   ├── 结构与流程图/
│   │   ├── 原型/
│   │   └── ...
│   └── 用户故事地图/
│       ├── 能力名-能力地图.md
│       └── 总览-总览地图.md
└── 产品B全名/
    └── ...
```

- 产品目录使用全名，文件使用 2–6 个汉字的唯一简称前缀
- 正文使用 Wiki 链接 `[[文件名]]` 引用其他文档（兼容 Obsidian）
- 所有文档带 frontmatter（`id`、`product`、`type`、`capability`、`aliases`、`tags`）
- 架构设计文档是根标识和最高产品设计标准

---

## 项目记忆

项目数据不写入 skill 目录，而是保存在当前工作区：

```
<workspace>/.claude/product-design-projects/<project-id>/
```

每个项目包含：

| 文件 | 作用 |
|------|------|
| `progress.json` | 项目名片、`workflow.state`、项目类型、产品库选择、阶段状态和时间戳 |
| `refs.json` | 文档节点和引用关系图谱，含产品库 ID（`libraryId`）和内容哈希（`contentHash`） |
| `facts.json` | 已确认结构化事实 |
| `decision-log.md` | 决策、理由和被否定方案 |
| `tracking-log.md` | 假设、风险、未决问题 |
| `phase-summary.md` | 跨会话恢复摘要 |

正式文档目录：`docs/` 下存放草稿态数据（字段 JSON）和追溯矩阵。

---

## 快捷指令

| 指令 | 作用 |
|------|------|
| `!status` | 查看当前项目进度、当前阶段、最近文档 |
| `!list` | 列出当前工作区下的产品设计项目 |
| `!switch <project-id>` | 切换到指定项目 |
| `!doc <doc-id>` | 读取并展示指定文档 |
| `!next` | 校验并推进到下一阶段（需用户确认） |
| `!back` | 回退上一阶段（需用户确认） |
| `!graph` | 展示当前项目文档引用关系 |

---

## 关键脚本速查

| 脚本 | 作用 |
|------|------|
| **项目初始化** | |
| `scripts/prepare-intake.sh` | 创建 intake 目录和最小 `progress.json` |
| `scripts/init-project.sh` | 合并项目模板，初始化项目 |
| **写入产品库** | |
| `scripts/render-doc.sh` | 从字段 JSON 渲染需求卡片/设计文档/能力文档并直接写入产品库 |
| `scripts/render-story.sh` | 从 Story JSON 批量渲染用户故事并写入 `用户故事/` |
| `scripts/render-matrix.sh` | 从矩阵 JSON 渲染溯源矩阵 |
| **阶段迁移** | |
| `scripts/transition-project-state.sh` | 原子更新 `workflow.state`，只允许合法相邻迁移 |
| **校验** | |
| `scripts/validate-phase.sh` | 校验阶段产物和 frontmatter |
| `scripts/validate-product-library.sh` | 全量校验产品库 |
| `scripts/validate-product-library-lite.sh` | 快速校验产品库 |
| `scripts/validate-paradigm.sh` | 校验需求分析写作范式 |
| `scripts/validate-story.sh` | 校验用户故事写作规范 |
| **产品库管理** | |
| `scripts/acquire-product-library.sh` | 从 Git 仓库克隆或更新产品库 |
| `scripts/product-library-tools.mjs` | 对账工具（SHA-256 比对 + 变更报告） |
| `scripts/rename-product.sh` | 产品简称变更，失败自动回滚 |
| `scripts/backfill-library-ids.mjs` | 旧项目迁移：回填继承式 ID |

---

## 设计原则

- 主调度器只做流程管理，不替代阶段 agent 做专业分析。
- 每次只推进一个阶段，每轮只问一个主要问题。
- 草稿先确认，确认后直接写入产品库，落盘只有一次。
- 委派时传路径和状态，不复制大段产品库正文。
- 产品匹配渐进披露，不一次性读取全量产品库。
- 所有正式文档带产品库 frontmatter，通过 `refs.json` 建立追溯关系。
- `workflow.state` 是当前阶段的权威状态字段。
- 详细设计 4 个 Step 之间有严格因果关系（Step 1→2→3→4），不允许跳过。
- 原型修改必须先升版本号、加注释、高亮标记、更新版本栏；旧版另存为快照。
- `iteration`/`refactor` 项目不得修改已有产品库产物，只能引用、扩展或重新设计。
