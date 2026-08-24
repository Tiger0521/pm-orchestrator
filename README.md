# pm-orchestrator

`pm-orchestrator` 是一套产品全流程设计 skill，**同时适配 Claude Code 与 ZCode**。它把产品设计工作拆成一个主调度 skill 和四个阶段 subagent：主调度器负责入口分流、项目恢复、产品库选择、阶段路由、用户确认和质量门；阶段 subagent 负责需求分析、需求拆解、详细设计和用户故事地图。

目标是把用户的模糊想法推进成可确认、可直接写入产品库、可追溯、可继续迭代的产品设计资产。

一份 skill 即插即用：同一个分发文件夹，装到 Claude Code 或 ZCode 的内容**逐字节一致**；运行时会话开始时识别宿主（`RUNTIME=claude` / `RUNTIME=zcode`），机制层自动切换，内容方法论共用。

---

## 架构总览：五层模型

```
┌─────────────────────────────────────────────────┐
│  ① 运行时识别层 (SKILL.md + runtime/)            │
│  会话开始 → 识别宿主 → 固化 RUNTIME              │
├─────────────────────────────────────────────────┤
│  ② 主 Skill 层 (SKILL.md)                       │
│  入口分流 · 产品库校验 · 项目状态 · 阶段路由      │
├─────────────────────────────────────────────────┤
│  ③ Agent 层 (agents/*.md)                       │
│  requirement-analyst                             │
│  story-breakdown-analyst                         │
│  detailed-design-designer                        │
│  story-map-designer                              │
├─────────────────────────────────────────────────┤
│  ④ Reference 层 (references/)                    │
│  阶段方法论 · 模板 · 质量门 · 共享追溯模型        │
├─────────────────────────────────────────────────┤
│  ⑤ 工具层 (scripts/ + project-template/)         │
│  项目骨架 · 机械校验 · 产品库规范                │
└─────────────────────────────────────────────────┘
```

---

## 核心调用流程图

### 一、主调度流程（入口 → 委派 → 返回）

```mermaid
flowchart TD
    Start([用户输入]) --> Shortcut{以 ! 开头？}
    Shortcut -- 是 --> Cmd[执行快捷指令<br/>!status / !list / !switch / !doc / !graph / !next / !back]
    Cmd --> Wait([等待下一轮输入])

    Shortcut -- 否 --> RuntimeDetect{运行时识别}
    RuntimeDetect -->|具备 Agent 工具 + ZCode 解析能力| ZCode[固化 RUNTIME=zcode<br/>运行 subagent 自检自举<br/>～/.zcode/agents/ 补全]
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

### 二、Subagent 返回状态路由（谁回来 → 做什么）

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

### 三、需求分析阶段（requirement-analyst）

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

### 四、需求拆解阶段（story-breakdown-analyst）

```mermaid
flowchart TD
    StartSB([委派 mode=draft]) --> Q[逐轮追问每个 Feature<br/>→ 拆分为 User Story<br/>→ 编写 GWT 验收标准]
    Q --> DraftReady{返回 draft-ready}
    DraftReady --> ShowStory[展示 Story 草稿<br/>请求用户确认]
    ShowStory --> PersistStory[批量渲染用户故事<br/>写入产品库 用户故事/ 目录<br/>生成溯源矩阵]

    PersistStory --> AutoSM[**自动进入用户故事地图生成**<br/>mode=generate → story-map-designer<br/><br/>不询问去向<br/>用户明确要求详细设计时<br/>才执行阶段迁移]

    AutoSM --> SMFlow[逐个能力迭代<br/>自检 → 提问 → 生成 → 确认 → 落盘]
    SMFlow --> Cap1[能力 1 地图完成]
    SMFlow --> Cap2[能力 2 地图完成]
    SMFlow --> CapN[...]
    SMFlow --> Overview[生成总览地图]

    Overview --> MapDone([故事地图全部完成])
```

### 五、详细设计阶段（detailed-design-designer）—— 四步路由

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
        S1_5 --> S1_6[用户确认 → 直接写入产品库<br/>草稿即正式]
    end

    subgraph Step2[Step 2: 原型设计与规范对齐]
        S2_1[读取 Step 1 产物] --> S2_2[grilling 决策域<br/>平台 · UI 风格 · 布局模式]
        S2_2 --> S2_3[原型生成方式固定<br/>交互式 HTML 唯一方式]
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

    Step1 --> Step1Done{用户确认}
    Step1Done -- 是 --> StepRoute
    Step1Done -- 否 --> Step1

    Step2 --> Step2Done{用户确认}
    Step2Done -- 是 --> StepRoute
    Step2Done -- 否 --> Step2

    Step3 --> Step3Done{用户确认}
    Step3Done -- 是 --> StepRoute
    Step3Done -- 否 --> Step3

    Step4 --> Step4Done{用户确认}
    Step4Done -- 是 --> StepRoute
    Step4Done -- 否 --> Step4
```

### 六、独立模式：用户故事地图生成

```mermaid
flowchart LR
    Trigger[触发条件] --> T1[需求拆解落盘完成 → 自动进入]
    Trigger --> T2[用户明确要求"生成故事地图"]
    
    T1 --> SM
    T2 --> SM

    subgraph SM[故事地图生成流程]
        direction LR
        P1[Phase 1<br/>逐个能力迭代] --> P2[Phase 2<br/>生成总览]
        
        subgraph PerCapability[每个能力的迭代]
            Read[读取能力文档] --> Analysis[自我分析<br/>必返回 needs-input]
            Analysis --> ShowAnalysis[展示自检结论 + 提问]
            ShowAnalysis --> ConfirmAnalysis[用户确认方向]
            ConfirmAnalysis --> GenerateMap[生成能力地图草案]
            GenerateMap --> ShowMapPreview[展示地图预览<br/>map-draft-ready]
            ShowMapPreview --> PersistMap[用户确认 → 落盘<br/>map-persisted]
        end

        PerCapability --> Next[自动扫描 → 下一个能力]
        Next --> PerCapability
        Next -->|全部能力完成| P2
    end

    P2 --> MapDone([map-complete])
```

### 七、独立模式：原型修改路由

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
        S2 --> S3[高亮标记改动区域<br/>框选模式生成的坐标 + 描述]
        S3 --> S4[更新版本标注栏<br/>版本记录 + 变更说明]
    end

    Step --> DraftPreview[draft-ready → 展示修改方案]
    DraftPreview --> UserConfirm{用户确认}
    UserConfirm -- 是 --> Archive[旧版另存为快照<br/>写入过程文件夹]
    Archive --> WriteNew[新版写入产品库<br/>详细设计/原型/]
    UserConfirm -- 否 --> Revise[调整后重新预览]
```

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| V4.0.0 | 2026-08-21 | 支持 zcode 使用，完成详细设计 step1+step2，可生成原型 |
| V4.0.1 | 2026-08-21 | 修复产品库命名和 obsidian 引用格式 |

---

## 安装与更新

仓库地址：[github.com/Tiger0521/pm-orchestrator](https://github.com/Tiger0521/pm-orchestrator)

### 首次安装（拷文件夹即用）

**两种宿主都只要把整个 skill 文件夹拷到对应的 skills 目录，重启即可用。**

- **Claude Code**：把整个 `pm-orchestrator/` 文件夹拷到 `~/.claude/skills/pm-orchestrator`。目录自带 `.claude-plugin/plugin.json`，Claude 重启后自动把它识别为插件，`agents/` 下的 4 个 agent 自动获得 `pm-orchestrator:` 命名空间。
- **ZCode**：把整个 `pm-orchestrator/` 文件夹拷到 `~/.zcode/skills/pm-orchestrator`。ZCode 不扫描 skill 文件夹内的 agent 文件，所以 **每次运行本 skill 时自动自检自举**，把 `agents/zcode/` 的 4 个 `.md` 中缺失者自动补到 `~/.zcode/agents/`。

`install.ps1` 是**可选**便捷工具（用于预置 subagent、做干净的整包重装），不是必需步骤。

### 更新

```powershell
git pull --ff-only origin main
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target claude   # 或 -Target zcode
```

拉取后重装，重启目标客户端即可生效。

---

## 目录结构

```
pm-orchestrator/                          ← git 仓库 = skill 本体（SKILL.md 在根）
├── SKILL.md                              ← 主调度入口 + 运行时识别门
├── README.md
├── install.ps1                           ← 统一安装脚本
│
├── references/                           ← 阶段方法论（双平台共用）
│   ├── orchestrator/                     ← 主调度器操作协议
│   │   ├── operations.md                 ← 委派、返回、记忆协议
│   │   ├── output-format.md              ← 输出规范
│   │   ├── phase-transition.md           ← 阶段迁移
│   │   ├── product-library-context.md    ← 产品库确认流程
│   │   └── shortcut-commands.md          ← ! 快捷键
│   ├── product-library/
│   │   └── contract.md                   ← 产品库契约
│   ├── shared/
│   │   └── traceability-model.md         ← 共享追溯模型
│   ├── requirement-analysis/             ← 需求分析方法论
│   ├── user-story-breakdown/             ← 需求拆解方法论
│   ├── detailed-design/                  ← 详细设计方法论
│   │   ├── instruction.md                ← 整体调度 + 4 步路由
│   │   ├── shared/                       ← 跨 Step 共享机制
│   │   │   ├── grilling-protocol.md      ← 问答协议
│   │   │   ├── confirmation-method.md    ← 确认流程
│   │   │   ├── design-review.md          ← 设计审查五维度
│   │   │   ├── output-contract.md        ← 产出字段契约
│   │   │   ├── persist-guide.md          ← 落盘轨道
│   │   │   ├── design-writing.md         ← 设计写作规范
│   │   │   ├── checklist.md              ← 质量门清单
│   │   │   ├── scale-adaptation.md       ← 规模自适应
│   │   │   ├── templates/                ← 渲染模板
│   │   │   └── examples/                 ← 质量示例
│   │   ├── step1-功能架构与动线规划/      ← 业务流 → 页面映射 → HTML 图
│   │   ├── step2-原型设计与规范对齐/      ← 交互式 HTML 原型 + 标注层
│   │   │   ├── workflow.md               ← 执行流程
│   │   │   ├── prototype-method.md       ← 原型方式 + 局部迭代
│   │   │   ├── annotation-overlay.md     ← 内联标注层规范
│   │   │   ├── ui-design-style.md        ← 设计系统 + 风格预设
│   │   │   ├── ui-style-presets/         ← 20+ 套 UI 风格预设
│   │   │   └── pm-prototype-prd/         ← 自包含内嵌技能
│   │   ├── step3-交互规则与边界补全/
│   │   └── step4-Sprint分解/
│   └── story-map/                        ← 用户故事地图方法论
│
├── runtime/
│   ├── claude.md                         ← Claude Code 机制层
│   └── zcode.md                          ← ZCode 机制层
│
├── agents/
│   ├── requirement-analyst.md            ← Claude Code 版（平铺）
│   ├── story-breakdown-analyst.md
│   ├── detailed-design-designer.md
│   ├── story-map-designer.md
│   └── zcode/                            ← ZCode 版
│       ├── requirement-analyst.md
│       ├── story-breakdown-analyst.md
│       ├── detailed-design-designer.md
│       └── story-map-designer.md
│
├── scripts/                              ← 机械校验、渲染、产品库工具
│   ├── render-doc.sh                     ← 从字段 JSON 渲染并写入产品库
│   ├── render-story.sh                   ← 批量渲染用户故事
│   ├── validate-phase.sh                 ← 阶段产物校验
│   ├── validate-product-library.sh       ← 产品库全量校验
│   ├── product-library-tools.mjs         ← 对账工具
│   ├── transition-project-state.sh       ← 原子更新 workflow.state
│   └── ...
│
└── project-template/                     ← 过程项目骨架
    ├── progress.json
    ├── refs.json
    ├── facts.json
    ├── phase-summary.md
    ├── decision-log.md
    └── tracking-log.md
```

---

## 运行时机制对比

| 项目 | Claude Code (RUNTIME=claude) | ZCode (RUNTIME=zcode) |
|------|------|------|
| Subagent 来源 | `agents/` 平铺，插件自动识别 | `agents/zcode/` 分发 → 自检自举到 `~/.zcode/agents/` |
| 委派方式 | 命名子 agent：`pm-orchestrator:<name>` | Agent 工具：`subagent_type=<裸名>` |
| 项目根 | `<workspace>/.claude/product-design-projects/` | 统一同上 |
| Reference 解析 | 相对 skillPath，subagent 在插件上下文内直接解析 | 经 `${skillPath}` 拼接 |
| Subagent tools | `Read Write Grep Glob LS Bash` | 同左 |
| 安装步骤 | 拷文件夹即可 + `.claude-plugin/plugin.json` 自动注册 | 拷文件夹即可，其余每次运行时自举 |

---

## 阶段制品落点

| 阶段 | 制品 | 落点 |
|------|------|------|
| 需求分析 | 需求卡片、Epic、Feature | 产品库 `<产品名>/` |
| 需求拆解 | User Story、GWT | 产品库 `<产品名>/用户故事/` |
| 需求拆解 | 溯源矩阵 | 过程项目 `docs/requirement-analysis/` |
| 详细设计 Step 1 | 业务流文档、页面映射、HTML 图 | 产品库 `详细设计/结构与流程图/` |
| 详细设计 Step 2 | 交互式 HTML 原型（含标注层） | 产品库 `详细设计/原型/` |
| 详细设计 Step 3 | 交互契约、规则摘要 | 产品库 `详细设计/`（render-doc.sh 渲染） |
| 详细设计 Step 4 | Sprint 规划 | 产品库 `详细设计/`（render-doc.sh 渲染） |
| 用户故事地图 | 能力地图、总览地图 | 产品库 `用户故事地图/` |

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

## 关键脚本

| 脚本 | 作用 |
|------|------|
| `scripts/prepare-intake.sh` | 创建 intake 目录和最小 `progress.json` |
| `scripts/init-project.sh` | 合并项目模板，初始化正式项目记忆 |
| `scripts/render-doc.sh` | 从字段 JSON 渲染需求卡片/设计文档/能力文档并直接写入产品库 |
| `scripts/render-story.sh` | 从 Story JSON 批量渲染用户故事并写入 `用户故事/` |
| `scripts/render-matrix.sh` | 从矩阵 JSON 渲染溯源矩阵 Markdown |
| `scripts/transform-project-state.sh` | 原子更新 `workflow.state`，只允许合法相邻迁移 |
| `scripts/validate-phase.sh` | 校验阶段产物和 frontmatter |
| `scripts/validate-product-library.sh` | 全量校验产品库（中文目录、命名、frontmatter、文件唯一性、链接完整性） |
| `scripts/product-library-tools.mjs` | 产品库对账（SHA-256 比对 `refs.json` 输出变更报告） |
| `scripts/acquire-product-library.sh` | 从 Git 仓库克隆或更新产品库 |
| `scripts/rename-product.sh` | 预览或应用产品简称变更，失败自动回滚 |
| `scripts/backfill-library-ids.mjs` | 旧项目迁移：为已落盘文档回填继承式产品库 ID |
| `scripts/export-doc-index.sh` | 导出文档索引或 Mermaid 引用图 |

---

## 产品库说明

产品库是主调度器每次运行前必须确认的容器目录。自动发现规则：从当前目录向上最多 3 层查找 `product-library/`。

产品库包含：
- **架构设计文档**：根标识，唯一匹配 `^.+架构设计\.md$`，含 5 个章节（建设背景、目标、设计原则、总体架构图、产品矩阵）
- **产品目录**：按产品全名命名的中文目录
- **能力文档 / 需求卡片 / Epic / Feature / 用户故事**：按名称和能力路径组织

产品库兼容 Obsidian 链接语法（`[[文件名]]`），也支持文件管理器直接浏览。

---

## 设计原则

- 主调度器只做流程管理，不替代阶段 agent 做专业分析。
- 每次只推进一个阶段，每轮只问一个主要问题。
- 草稿先确认，确认后直接写入产品库，落盘只有一次；过程空间只保留草稿态数据和项目记忆。
- 委派时传路径和状态，不复制大段产品库正文。
- 产品匹配渐进披露，不一次性读取全量产品库。
- 所有正式文档带产品库 frontmatter（`id`、`product`、`type`、`capability`、`aliases`、`tags`），并通过 `refs.json` 建立追溯关系。
- `workflow.state` 是当前阶段的权威状态字段。
- `iteration`/`refactor` 项目不得修改已有产品库产物，只能引用、扩展或重新设计。
- 详细设计 4 个 Step 之间有严格因果关系：Step 1 → Step 2 → Step 3 → Step 4，不允许跳过。
- 原型修改必须先升版本号、加注释、高亮标记、更新版本栏；旧版本另存为快照。
