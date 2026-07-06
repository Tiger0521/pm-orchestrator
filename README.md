# pm-orchestrator Skill 说明文档

> 本文档是对已创建的 `pm-orchestrator` Skill 的完整说明，便于你审阅。

---

## 一、一句话定位

`pm-orchestrator` 是一个**产品全流程设计编排器**。它作为用户唯一入口，带用户走完从「模糊想法」到「可落地执行」的完整产品设计流程，并通过多文件记忆机制实现跨会话断点恢复。

整个流程分为三个阶段：

1. **需求分析**（requirement-analysis）— 灵魂拷问，还原问题本质，输出需求卡片 + Epic + Feature
2. **需求拆解**（user-story-breakdown）— 将 Feature 拆成 User Story + GWT 验收标准
3. **详细设计**（detailed-design）— 生成原型、交互契约、规则摘要和 Sprint 规划

---

## 二、设计原则

### 1. 单 Skill + reference + 项目模板 + 项目记忆 + 当前项目指针

整个体系由五个部分组成：

| 部分 | 职责 |
|------|------|
| **单 Skill**（`pm-orchestrator`） | 用户唯一入口，主流程编排、阶段路由、记忆管理 |
| **多阶段 reference** | 三阶段执行指令按需动态加载 |
| **项目记忆文件** | 每个项目 6 个独立记忆文件，按需读写，互不污染 |
| **当前项目指针** | `current-project.json` 只记录默认选中项，每次仍以实际扫描为准 |
| **校验脚本** | 阶段转换时辅助校验文件存在性和 frontmatter 完整性 |

### 2. 渐进式披露（Progressive Disclosure）

为防止上下文爆炸，按需加载，用多少读多少：

| 层级 | 位置 | 何时加载 | 内容 |
|------|------|---------|------|
| L0 常驻 | `SKILL.md` | 每次对话 | 主流程、阶段路由规则、输出规范、快捷指令 |
| L1 阶段指令 | `references/<phase>/instruction.md` | 进入该阶段时 | 角色设定、核心机制、执行流程、对话风格 |
| L2 工具文件 | `question-bank.md`、`checklist.md` | 指令明确需要时 | 问题库、质量门校验规则 |
| L3 模板 | `templates/*.md` | 产出文档时 | 带占位符的空白模板 |
| L4 示例 | `examples/*.md` | 需要质量标杆参照时 | 完整真实案例 |
| L5 跨阶段共享 | `shared/traceability-model.md` | 涉及追溯关系时 | 追溯模型定义（全局唯一） |

**加载时不对用户暴露机制**：不说"现在加载 instruction.md"，而是自然过渡到下一阶段工作。

### 3. 模板与项目分离

- Skill 目录包含所有阶段模板和项目骨架模板
- 调用 Skill 时复制项目骨架到工作区
- 后续所有记忆、文档、阶段状态都写入项目目录
- Skill 目录只允许更新当前项目指针，不写入项目内容

---

## 三、完整文件结构

```
.claude/skills/pm-orchestrator/
├── SKILL.md                                    # L0 常驻：主流程 + 阶段路由 + 输出规范
├── current-project.json                        # 唯一运行态记录：当前项目目录
├── references/
│   ├── shared/                                 # 跨阶段共享文件
│   │   └── traceability-model.md               #   追溯模型定义
│   ├── requirement-analysis/                   # 需求分析阶段包
│   │   ├── instruction.md                      #   L1 阶段指令
│   │   ├── question-bank.md                    #   L2 灵魂拷问六问 + 三关验证 + 前提挑战表
│   │   ├── checklist.md                        #   L2 质量门
│   │   ├── templates/                          #   L3 输出文档模板
│   │   │   ├── requirement-card.md
│   │   │   ├── epic.md
│   │   │   └── feature.md
│   │   └── examples/                           #   L4 完整示例（质量标杆）
│   │       └── network-resource-mgmt.md
│   ├── user-story-breakdown/                   # 需求拆解阶段包
│   │   ├── instruction.md                      #   L1 阶段指令（INVEST、GWT、拆分策略）
│   │   ├── checklist.md                        #   L2 质量门
│   │   ├── templates/                          #   L3 模板
│   │   │   ├── user-story.md
│   │   │   └── traceability-matrix.md
│   │   └── examples/                           #   L4 示例
│   │       └── model-config-stories.md
│   └── detailed-design/                        # 详细设计阶段包
│       ├── instruction.md                      #   L1 阶段指令（原型、交互契约、Sprint分解）
│       ├── checklist.md                        #   L2 质量门
│       ├── templates/                          #   L3 模板
│       │   ├── structure-flow.md
│       │   ├── prototype.md
│       │   ├── interaction-contract.md
│       │   ├── rules-summary.md
│       │   └── sprint.md
│       └── examples/                           #   L4 示例
│           └── model-config-design.md
├── scripts/
│   ├── validate-phase.ps1                      # 阶段转换校验脚本
│   └── export-doc-index.ps1                    # 文档索引导出脚本
├── project-template/                           # 新项目骨架模板（调用时复制到工作区）
│   ├── progress.json
│   ├── refs.json
│   ├── facts.json
│   ├── decision-log.md
│   ├── tracking-log.md
│   ├── phase-summary.md
│   └── docs/
│       ├── strategic/
│       ├── requirement/
│       ├── design/
│       └── execution/
└── evals/evals.json                            # 3 个测试用例
```

共 **35 个文件**，结构与架构设计文档完全一致。

---

## 四、SKILL.md 内容详解

### 1. frontmatter（触发机制）

```yaml
name: pm-orchestrator
description: |
  产品全流程设计编排器。当用户想做一个新产品、新功能、需求分析、需求拆解、
  详细设计、用户故事拆分、原型设计、Sprint规划，或说"帮我梳理需求"、"帮我做产品设计"、
  "从零设计一个产品"、"需求分析"、"拆用户故事"、"写PRD"、"画原型"、"做产品方案"时，使用这个 Skill。
  也适用于：...
  不适用于：纯项目管理排期、纯 PRD 写作、纯数据分析、纯技术架构设计。
```

description 同时包含「做什么」「何时触发」「不适用边界」，三段式覆盖各种触发场景。

### 2. 调用入口：先选项目

每次调用第一步永远是项目选择：

1. 扫描工作区下 `.claude/product-design-projects/` 目录
2. 已有项目 → 列出让用户选择：继续 / 新建
3. 没有项目 → 直接新建
4. 更新 `current-project.json`

**新建项目流程**：询问名称 → 复制 `project-template/` 骨架 → 初始化 `progress.json`（含三阶段状态）→ 进入需求分析

**继续项目流程**：读 `progress.json` + `phase-summary.md` → 汇报当前阶段和上次进展 → 按 `currentPhase` 进入对应阶段

### 3. 阶段路由规则

读取 `progress.json` 的 `currentPhase`，按表路由：

| currentPhase | 读取的 reference | 产出目录 |
|--------------|------------------|----------|
| `requirement-analysis` | `references/requirement-analysis/instruction.md` | `docs/strategic/` + `docs/requirement/` |
| `user-story-breakdown` | `references/user-story-breakdown/instruction.md` | `docs/design/` |
| `detailed-design` | `references/detailed-design/instruction.md` | `docs/design/` + `docs/execution/` |

**核心原则**：每次只加载当前阶段需要的 reference，不一次性读取所有 instruction。

### 4. 输出规范

#### 文档 Frontmatter（强制）

每份产出文档必须包含：

```yaml
---
id: "<doc-id>"
type: "requirement-card | epic | feature | user-story | ..."
projectId: "<project-id>"
title: "<文档标题>"
status: "draft | review | approved"
refs:
  - id: "<上游文档id>"
    relation: "derived-from | belongs-to | implements | contains"
---
```

正文引用其他文档用 `[@doc-id]` 语法。

#### ID 命名规则

| 文档类型 | ID 前缀 |
|----------|---------|
| 需求卡片 | `req-` |
| Epic | `epic-` |
| Feature | `feature-` |
| User Story | `story-` |
| 溯源矩阵 | `matrix-` |
| 结构与流程 | `flow-` |
| 原型 | `proto-` |
| 交互契约 | `contract-` |
| 规则摘要 | `rules-` |
| Sprint | `sprint-` |

#### 文档分层目录

| 层级 | 目录 | 文档类型 | 回答的问题 |
|------|------|---------|-----------|
| 战略层 | `docs/strategic/` | Epic | Why + What（高层） |
| 需求层 | `docs/requirement/` | 需求卡片、Feature | What（具体） |
| 设计层 | `docs/design/` | User Story、原型、交互契约 | How（体验） |
| 执行层 | `docs/execution/` | Sprint | When + Who |

### 5. 记忆机制（6 个文件）

| 文件 | 职责 | 何时读写 |
|------|------|---------|
| `progress.json` | 当前阶段 + 阶段状态 + 时间戳 | 每次会话必读/必写 |
| `refs.json` | 文档节点索引 + 引用关系图谱 | 产出文档时读/写 |
| `facts.json` | 已确认结构化事实 | 确认事实时写 |
| `decision-log.md` | 决策结论 + 理由 + 被否定的备选方案 | 做决策时追加 |
| `tracking-log.md` | 假设 + 风险 + 未决问题（三段式） | 发现假设/风险/问题时追加 |
| `phase-summary.md` | 每阶段一段摘要 | 阶段完成时追加 |

**按需读取原则**：
- 会话恢复：只读 `progress.json` + `phase-summary.md`
- 产出文档：读 `refs.json` 查上游文档
- 阶段转换：读 `checklist.md` 校验
- 不一次性加载所有记忆文件

### 6. 阶段转换

阶段转换必须通过对应阶段 `checklist.md` 校验：

1. 读取 `references/<phase>/checklist.md`
2. 逐条检查当前阶段产出
3. 全部通过 → 更新 `progress.json` 的 `currentPhase` 到下一阶段
4. 未通过 → 明确告知缺失项，停留在当前阶段

也可调用 `scripts/validate-phase.ps1` 辅助机械校验。

| 转换 | 关键校验项 |
|------|----------|
| 需求分析 → 需求拆解 | Epic 含定位/指标/角色/场景/边界；Feature 含描述/流程/规则/优先级；用户已确认 |
| 需求拆解 → 详细设计 | 每 Story 三段式；每 Story 3-8 条 GWT；覆盖正常+异常路径；用户已确认 |
| 详细设计 → 完成 | 核心页面原型完成；交互契约含状态机+规则表；Sprint 规划已输出；用户已确认 |

### 7. 快捷指令

| 指令 | 作用 |
|------|------|
| `!status` | 查看当前项目进度、当前阶段、最近文档 |
| `!list` | 列出 `product-design-projects/` 下所有项目 |
| `!switch <project-id>` | 切换到指定项目 |
| `!doc <doc-id>` | 读取并展示指定文档内容 |
| `!next` | 推进到下一阶段（需确认） |
| `!back` | 回退上一阶段（需确认） |
| `!graph` | 展示当前项目的文档引用关系图 |

### 8. 执行原则

1. 先问后写：不要急于输出文档
2. 一次只推进一个阶段
3. 用户确认后落盘
4. 保留诊断和备选（需求分析阶段先输出诊断报告）
5. 渐进式披露
6. 跨会话恢复

---

## 五、三阶段内容详解

### 阶段一：需求分析（requirement-analysis）

**角色**：资深产品合伙人（YC 式 Office Hours 导师）

**核心机制**：

1. **灵魂拷问六问**（一次一个问题，追问最多 3 轮）

| # | 问题 | 目的 |
|---|------|------|
| Q1 | 你要解决的真实问题是什么？用户现在怎么做的？ | 需求真实性 |
| Q2 | 现有替代方案为什么不够用？最痛的具体场景？ | 替代方案痛点 |
| Q3 | 这个痛点有多痛？不解决会怎样？ | 痛点强度 |
| Q4 | 如果只能做最小的一件事，从哪切入？ | 最小切入点 |
| Q5 | 你对这个需求最可能错误的假设是什么？ | 反直觉假设 |
| Q6 | 这件事 6 个月/1 年后会发生什么变化？ | 趋势判断 |

2. **三关验证**：具体性验证 → 反证验证 → 替代验证，不过就追问，3 轮说不清标记「伪需求嫌疑」

3. **前提挑战**：对「做平台」「AI 赋能」「领导要求」等高危信号主动质疑

4. **强制替代方案**：输出文档前生成至少 2 个替代方案逼用户选择

5. **诊断报告先行**：先输出「你以为的问题 vs 实际的问题」，确认后再写正式文档

**产出**：需求卡片（`docs/strategic/req-001.md`）+ Epic（`docs/strategic/epic-001.md`）+ Feature（`docs/requirement/feature-001.md`）

**示例标杆**：`examples/network-resource-mgmt.md`（网络资源管理系统完整产出）

### 阶段二：需求拆解（user-story-breakdown）

**角色**：敏捷需求分析师

**核心机制**：

1. **INVEST 检查**：Independent / Negotiable / Valuable / Estimable / Small / Testable

2. **三段式格式**：`作为 [角色]，我想要 [目标]，以便于 [价值]`

3. **GWT 验收标准**：每条 Story 3-8 条，Given-When-Then 格式

4. **异常分支枚举**：权限不足、数据为空/超限、网络异常、并发冲突、重复提交、输入格式错误

**产出**：User Story 清单（`docs/design/story-001.md`）+ 溯源矩阵（`docs/design/matrix-001.md`）

**示例标杆**：`examples/model-config-stories.md`（模型配置管理 Story 拆分）

### 阶段三：详细设计（detailed-design）

**角色**：产品设计师 + 交互设计师

**核心机制**：

1. **页面映射**：Story 按页面归类，输出页面映射表
2. **原型草案**：布局 + 交互说明 + 组件复用 + 异常状态
3. **穷举异常**：触发/校验/流转/服务端/兜底
4. **交互契约**：状态机 + 交互规则表 + API 约定 + 错误文案
5. **Sprint 分解**：按优先级+依赖分配，预留 15-20% 缓冲

**产出**（5 份文档）：
- 结构与流程图（`docs/design/flow-001.md`）
- 原型文档（`docs/design/proto-001.md`）
- 交互契约（`docs/design/contract-001.md`）
- 规则摘要（`docs/execution/rules-001.md`）
- Sprint 规划（`docs/execution/sprint-001.md`）

**示例标杆**：`examples/model-config-design.md`（模型配置管理完整设计）

---

## 六、校验脚本说明

### 1. `scripts/validate-phase.ps1`

阶段转换时辅助校验，做三层机械检查：

- **文件存在性**：检查各阶段关键文档是否已生成
- **frontmatter 完整性**：检查每份文档是否含 id/type/projectId/title/status/refs
- **refs.json 注册**：检查产出文档的 id 是否已注册到 refs.json

> 注意：脚本只做机械校验，内容质量判断仍需结合各阶段 `checklist.md` 人工评估。

调用方式：

```powershell
.\validate-phase.ps1 -projectPath "<项目路径>" -phase requirement-analysis
```

### 2. `scripts/export-doc-index.ps1`

扫描项目 `docs/` 目录，提取每份文档的 frontmatter，生成按四层分组的文档索引清单。

调用方式：

```powershell
.\export-doc-index.ps1 -projectPath "<项目路径>"          # 输出到 stdout
.\export-doc-index.ps1 -projectPath "<项目路径>" -outputPath index.md  # 写入文件
```

---

## 七、项目模板说明

`project-template/` 是新项目骨架，调用 Skill 新建项目时整体复制到 `.claude/product-design-projects/<project-id>/`。

包含 6 个记忆文件（含占位符）+ 4 个空 docs 子目录（用 .gitkeep 占位）：

| 文件 | 初始内容 |
|------|---------|
| `progress.json` | 三阶段状态机，初始 currentPhase=requirement-analysis |
| `refs.json` | 空 nodes + edges 数组 |
| `facts.json` | 空 facts 数组 |
| `decision-log.md` | 决策格式说明（含 D### 模板） |
| `tracking-log.md` | 三段式：假设 / 风险 / 未决问题 |
| `phase-summary.md` | 摘要格式说明 |

---

## 八、追溯模型说明

`references/shared/traceability-model.md` 定义了全局唯一的追溯规则。

### 文档节点类型

`requirement-card` / `epic` / `feature` / `user-story` / `traceability-matrix` / `structure-flow` / `prototype` / `interaction-contract` / `rules-summary` / `sprint`

### 引用关系类型

| 关系 | 含义 | 方向 |
|------|------|------|
| `derived-from` | 派生自 | 下游 → 上游 |
| `belongs-to` | 归属于 | 子 → 父 |
| `implements` | 实现 | 实现 → 被实现 |
| `contains` | 包含 | 容器 → 成员 |
| `references` | 一般引用 | 任意 → 任意 |

标准追溯链：

```
需求卡片 ──derived-from──▶ Epic
Feature  ──belongs-to────▶ Epic
User Story ──implements──▶ Feature
原型/契约 ──implements──▶ User Story
Sprint   ──contains─────▶ User Story
```

---

## 九、测试用例（evals/evals.json）

已创建 3 个测试用例：

| ID | 场景 | 预期 |
|----|------|------|
| 1 | 用户描述模糊的网络资源管理需求 | 进入需求分析阶段，亮明身份，开始 Q1 灵魂拷问，一次只问一个问题，不直接输出完整文档 |
| 2 | 用户已有 Feature 想拆成 User Story | 识别为需求拆解阶段，引导选项目，按 INVEST + GWT 拆分，提示确认后落盘 |
| 3 | `!status` 查看进度 | 识别为快捷指令，读 current-project.json + progress.json + phase-summary.md，汇报进展 |

---

## 十、使用方式

### 首次使用

1. 用户调用 pm-orchestrator
2. Skill 扫描 `.claude/product-design-projects/`（首次为空）
3. 进入新建项目流程：询问名称 → 复制骨架 → 初始化 progress.json
4. 自动进入需求分析阶段，开始灵魂拷问

### 继续已有项目

1. 用户调用 pm-orchestrator
2. Skill 列出所有项目让用户选择
3. 读 progress.json + phase-summary.md 恢复上下文
4. 按 currentPhase 接续上次工作

### 运行中

- 直接对话推进工作
- 或用快捷指令：`!status` / `!list` / `!switch` / `!doc` / `!next` / `!back` / `!graph`

---

## 十一、待确认事项（需你审阅）

创建过程中有几处设计决策，请确认是否符合预期：

1. **工作区路径**：项目目录默认放在 `.claude/product-design-projects/<project-id>/`，与架构文档第 7 节一致。是否需要改到其他位置？

2. **脚本是 PowerShell**：架构文档第 4 节写的是 `.ps1`，已按 Windows 环境实现。如果需要在跨平台环境运行，可考虑补充 Python 版本。

3. **模板占位符风格**：使用 `{{PLACEHOLDER}}` 大括号占位符。是否需要改为其他风格（如 `[占位符]`）？

4. **示例内容**：需求分析用「网络资源管理系统」、需求拆解和详细设计用「模型配置管理」两个示例。是否需要换成你更熟悉的业务场景？

5. **测试用例**：当前 3 个测试用例覆盖新建项目、阶段路由、快捷指令三种场景。是否需要补充更多边界用例？

6. **frontmatter 中 refs 字段**：模板里写的是数组形式（`- id / relation`）。是否需要支持单字符串简写？

---

审阅完如有调整意见，告诉我具体改哪份文件、改成什么样，我来逐个修改。审阅通过后，可以进入 skill-creator 的测试流程：用 3 个 evals 跑 with-skill / 无 skill 对比，再根据反馈迭代。
