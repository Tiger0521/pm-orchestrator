# pm-orchestrator 质量优先的效率重构规范

## 1. 文档目的

本文用于指导 `pm-orchestrator` 的后续重构。目标是在**不降低需求分析、需求拆解和详细设计质量**的前提下，显著降低主调度器的上下文规模、重复推理、错误状态迁移和用户无反馈等待时间。

本次重构不是针对某次错误增加局部禁止语，而是重新建立：

- 显式工作流状态机；
- 单一职责与能力所有权；
- 主调度器和阶段 agent 的稳定交接协议；
- 按需加载的 reference 结构；
- 可自动验证的质量与效率门禁。

本文是实施规范，不是运行时 reference。完成重构后，不要把本文整体复制进 `SKILL.md`。

---

## 2. 已确认的问题

### 2.1 性能问题不是脚本造成的

已观察到一次新项目 intake 在用户提交完整描述后，直到最终回答完整出现约耗时 7 分钟。会话记录显示：

- 主调度器使用 `glm-5.2`、`effort=high`；
- 两段主模型推理合计接近 6 分钟；
- 最后一次模型调用处理约 6.8 万 tokens 上下文；
- 本轮累计产生约 1.45 万 output tokens，但最终可见回答约 1900 个汉字；
- `validate-product-library.sh` 实测约 0.045 秒，目录创建脚本同样不是主要瓶颈。

因此，主要问题是主调度器承担了过多专业分析、读取了过多 reference，并在冲突规则之间反复规划。

### 2.2 流程错误不是简单“忘记步骤”

已观察到以下错误迁移：

1. 主调度器调用 `prepare-intake.sh` 创建背景目录；
2. 按流程应向用户展示目录，并等待用户提供材料或明确跳过；
3. 实际却把用户的初始需求描述当成背景材料已解决；
4. 未经用户明确回复便进入产品匹配和项目类型建议。

该错误的根因是：

- `initialDescription` 与 `backgroundMaterials` 没有独立状态；
- “没有材料时继续”允许模型自行推断用户已经跳过；
- 编号步骤没有持久化状态和可执行前置条件；
- 主调度器同时拥有信息收集和专业分析职责；
- “一次只问一个问题”“不要阻断”“继续推进”等要求存在竞争。

这属于**未授权的状态迁移**，不能通过追加一句“禁止提前产品匹配”根治。

---

## 3. 重构不可违反的原则

### 3.1 质量优先

不得通过以下方式换取速度：

- 不得把专业阶段 agent 换成更弱模型；
- 不得降低专业阶段 agent 的 reasoning effort；
- 不得删除需求字段、追问维度、用户确认节点或质量评分；
- 不得减少总体架构设计、产品资产、背景材料和上游文档的必要读取；
- 不得绕过范式校验、阶段 checklist、traceability 或正式落盘校验；
- 不得把未确认事实写入 `facts.json`；
- 不得把摘要草稿冒充完整落盘预览。

效率提升必须来自：减少重复读取、减少重复分析、缩短主提示、明确状态、确定性脚本化和正确职责分配。

### 3.2 用状态和前置条件替代局部禁止语

不要继续增加如下形式的规则：

```text
当发生 X 时，不要做 Y。
如果刚刚执行 A，禁止读取 B。
某一步之前不得运行 C。
```

改为定义：

- 当前状态是什么；
- 当前状态由谁处理；
- 处理器需要哪些输入；
- 成功后只能迁移到哪个状态；
- 哪些用户事件可以完成该状态。

当处理器没有某项能力、前置条件不成立时，错误路径自然不可达。

### 3.3 每项专业能力只有一个所有者

同一内容不得先由主调度器分析，再交给阶段 agent 重复分析。主调度器管理状态、确认与路由；阶段 agent 完成专业判断；脚本处理确定性写入和校验。

### 3.4 每轮只完成一个稳定状态迁移

一次用户回合可以：

- 收集并确认一个状态所需输入；或
- 启动一个专业处理器并返回其结果；或
- 完成一次确定性状态迁移。

不得在同一回合中为了“多推进一点”跨越多个需要用户确认的状态。

### 3.5 渐进式加载

主 `SKILL.md` 只保留调度内核。阶段方法、模板、范式和 checklist 由对应 agent 在需要时读取。规则只能有一个权威来源，不在多个文件中重复描述。

---

## 4. 目标架构

```text
用户
  │
  ▼
pm-orchestrator 主调度器
  ├─ 恢复 progress.json
  ├─ 根据 workflow.state 选择唯一处理器
  ├─ 组织用户确认
  ├─ 委派阶段 agent
  └─ 调用确定性脚本
        │
        ├───────────────┐
        ▼               ▼
阶段 agent           确定性脚本
  ├─ requirement       ├─ 产品库校验
  ├─ story             ├─ 状态迁移
  └─ detailed-design   ├─ 项目初始化
                       └─ 渲染与校验
```

### 4.1 主调度器只负责

- 恢复工作流状态；
- 选择当前状态的唯一处理器；
- 展示用户问题和用户确认；
- 启动对应阶段 agent；
- 调用确定性脚本；
- 更新阶段状态和项目指针；
- 处理快捷指令。

### 4.2 阶段 agent 负责

- 读取本阶段所需 reference；
- 理解总体架构设计；
- 读取和分析产品资产、背景材料和上游文档；
- 追问、诊断、产品匹配、需求拆解或详细设计；
- 维护阶段过程状态；
- 返回一个合规问题、完整预览或校验结果。

### 4.3 脚本负责

- 路径规范化和越界校验；
- 产品库结构校验；
- intake/project 目录初始化；
- `progress.json` 的确定性状态迁移；
- 字段 JSON 到 Markdown 的确定性渲染；
- 范式、frontmatter、引用关系和阶段产物机械校验。

---

## 5. 能力所有权

| 能力 | 唯一所有者 | 主调度器传递的内容 |
|---|---|---|
| 产品库发现与结构校验 | 主调度器 + 脚本 | 校验后的库路径、校验结果 |
| Intake 基础信息收集 | 主调度器 | 用户原始回答 |
| 背景材料入口管理 | 主调度器 | 目录路径、用户事件 |
| 背景材料内容理解 | `requirement-analyst` | 经过路径校验的文件路径 |
| 总体架构内容理解 | 对应阶段 agent | 经过校验的架构文档路径 |
| 产品匹配与复用判断 | `requirement-analyst` | 产品库路径、manifest 路径、用户上下文 |
| 项目类型建议 | `requirement-analyst` | 覆盖点、差异点、架构影响 |
| 项目类型确认 | 主调度器 | agent 返回的完整建议 |
| 需求追问与草稿 | `requirement-analyst` | 当前字段状态、用户回答 |
| Story 拆分 | `story-breakdown-analyst` | 已确认 Feature 和引用路径 |
| 详细设计 | `detailed-design-designer` | 已确认 Story/Feature 和引用路径 |
| 正式文档渲染 | 主调度器 + 脚本 | 已确认字段 JSON |
| 阶段转换 | 主调度器 + 脚本 | checklist 和校验结果 |

主调度器不得读取阶段专业 reference 后自行完成对应专业工作。这里不是通过“禁止语”约束，而是通过路由协议和文件加载边界保证：主 `SKILL.md` 不提供专业方法，只提供 agent 路由。

### 5.1 产品匹配的当前违反与移主要求

§5 规定产品匹配所有者为 `requirement-analyst`，但当前 `SKILL.md` intake 流程第 7 步仍由主调度器读取 `references/requirement-analysis/instruction.md` 的"产品匹配与复用引导"小节自行做匹配，再委派 analyst。这是主调度器双重推理的主要来源。

产品匹配功能保留，只移主。主调度器在 `analyze-reuse` 状态只传路径，不读 `instruction.md` 产品匹配段，不读产品库文档正文：

| 主调度器做 | analyst 做 |
|---|---|
| 传 `productLibraryPath`、`productArchitectureDesignPath`、`manifestPath` | 读 `product-library-spec.md` §8 并执行全流程 |
| 不读 `instruction.md` 产品匹配段 | 返回候选清单 + 匹配度评分 + 项目类型建议 |

修改位置：`SKILL.md` intake 流程第 7 步、`requirement-analyst.md` Reference 加载段。这是成本最低、收益最快的改进，应优先实施。

实施改进 C 时必须同步处理以下三项，否则移主会失效：

**1. 覆盖范围**：改进 C 不只覆盖 `analyze-reuse` 状态。继续项目（`currentPhase=requirement-analysis`）的 `iteration`/`refactor` 项目同样需要读产品库文档（当前 `SKILL.md` 继续项目流程第 3 步）。所有需要产品库文档的状态都应由 analyst 读路径，主调度器不读产品库文档正文。

**2. analyst 上下文边界扩展**：当前 `requirement-analyst.md` 第 83 行"独立上下文规则"写明"只基于 handoff、`projectPath` 下的项目文件、主调度器传入的背景摘要，以及本轮读取的 reference 工作"。产品库在 `~/.product-library/`，不在 `projectPath` 下。若不改这条边界，analyst 拿到路径也不会去读，会回头问主调度器要内容。需在该规则中增加例外："由主调度器传入安全校验后路径的 `productLibraryPath` 和 `productArchitectureDesignPath` 视为已授权读取路径，agent 可直接读取，不受 `projectPath` 边界限制。"

**3. handoff 字段同步**：当前 `requirement-analyst.md` handoff 字段是 `productArchitectureDesign`（含 `content` 字段，主调度器已读正文）和 `productLibraryDocs`（含 `summary`，主调度器已读）。改进 C 要把这两个改为纯路径字段：

| 当前字段 | 改后字段 | 说明 |
|---|---|---|
| `productArchitectureDesign.path` + `.summary` + `.content` | `productArchitectureDesignPath` | 只传路径，不传 content/summary |
| `productLibraryDocs[].path` + `.summary` | `productLibraryDocsPath` | 只传产品库根路径，agent 自行枚举 |
| 无 | `manifestPath` | 新增，传 `_manifest.md` 路径 |

`requirement-analyst.md` 的"启动检查"（第 52 行）当前校验 `productArchitectureDesign` 是否存在；改为校验 `productArchitectureDesignPath` 是否存在且可读，缺失时返回 `needs-input`。

---

## 6. 工作流状态模型

### 6.1 统一状态源

建议让 `prepare-intake.sh` 在创建 intake 目录时同时创建最小 `progress.json`，使 intake 和正式项目从一开始就使用同一个状态源。`init-project.sh` 后续补全该文件，而不是重新创建另一套状态。

不要新增多个相互重叠的 runtime 文件。

建议结构：

```json
{
  "projectId": "address-hub-001",
  "projectName": "地址中台",
  "projectType": "pending",
  "status": "intake",
  "workflow": {
    "state": "collect-background",
    "revision": 1,
    "updatedAt": "<ISO-8601>"
  },
  "intake": {
    "selectedProductLibraryId": "network-resource-center-product-library",
    "selectedProductLibraryPath": "<canonical-path>",
    "initialDescription": "<用户原始需求描述>",
    "briefConfirmation": "pending",
    "background": {
      "status": "awaiting-user",
      "directory": "<projectPath>/docs/background",
      "files": [],
      "pastedContent": [],
      "explicitlySkipped": false
    },
    "reuseAnalysis": {
      "status": "not-started",
      "result": null
    },
    "projectTypeConfirmation": "pending"
  }
}
```

### 6.2 初始描述与背景材料必须分离

`initialDescription` 是用户提出项目时的原始需求，不属于背景材料事件。

只有在 `background.status=awaiting-user` 且主调度器已经向用户展示背景目录和选项后，用户的新回复才能产生以下事件之一：

- `background-provided-files`；
- `background-provided-text`；
- `background-skipped-explicitly`。

不得根据描述是否“足够完整”推断用户已跳过背景材料。

### 6.3 Intake 状态机

| workflow.state | 处理者 | 输入前置条件 | 成功输出 | 下一状态 |
|---|---|---|---|---|
| `select-library` | 主调度器 + 校验脚本 | 无已确认产品库 | 已确认且校验通过的库路径 | `collect-brief` |
| `collect-brief` | 主调度器 | 产品库已确认 | 项目名称、原始描述、项目 ID | `collect-background` |
| `collect-background` | 主调度器 | intake 目录已创建 | 用户提供材料或明确跳过 | `prepare-intake-summary` |
| `prepare-intake-summary` | `requirement-analyst` | 背景状态已解决 | 待确认需求描述 | `confirm-intake-summary` |
| `confirm-intake-summary` | 主调度器 | 完整 intake 摘要已生成 | 用户确认或修正 | `analyze-reuse` 或返回 `prepare-intake-summary` |
| `analyze-reuse` | `requirement-analyst` | intake 摘要已确认 | 覆盖点、差异点、候选产品、项目类型建议 | `confirm-project-type` |
| `confirm-project-type` | 主调度器 | 完整复用分析已返回 | 用户确认 `new/iteration/refactor` | `initialize-project` |
| `initialize-project` | 主调度器 + 脚本 | 项目类型已确认 | 完整项目结构 | `requirement-analysis` |
| `requirement-analysis` | `requirement-analyst` | 项目已初始化 | 需求卡片、Epic、Feature 流程 | 后续阶段 |

### 6.4 状态处理规则

调度器每轮执行固定算法：

```text
读取 progress.json
  → 校验 workflow.state
  → 查状态路由表
  → 加载唯一对应 handler
  → 执行一次 handler
  → 确定性更新状态或等待用户
  → 结束本轮
```

调度器不得根据“内容已经很丰富”“大概没有背景材料”“应该是新项目”等语义判断，越过需要显式用户事件的状态。

---

## 7. 用户交互模型

### 7.1 问题与状态绑定

每个用户问题都必须携带内部问题目标，例如：

```json
{
  "awaitingResponseTo": "background-materials",
  "state": "collect-background",
  "issuedAt": "<ISO-8601>"
}
```

下一轮用户回答只能用于完成该问题目标；如果用户同时补充其他信息，将其作为附加素材记录，但不得跳过当前状态。

### 7.2 长任务反馈

进入需要阶段 agent 的状态时：

1. 主调度器先用一句话说明已收到什么、将委派什么；
2. 启动后台阶段 agent；
3. 用户看到后台任务已启动；
4. agent 返回后再展示专业结果。

后台运行只改善可感知等待，不替代上下文精简和职责重构。

### 7.3 一轮一个问题

保留“一轮一个用户回答目标”，但不要在多个文件重复 UI 细节。交互契约只保留一个权威来源，由主调度器传入 agent。

信息组是提问单位，字段是输出单位。一个综合问题可以覆盖多个字段，但不得同时要求用户完成两个独立决策。

---

## 8. SKILL.md 精简目标

### 8.1 目标规模

- 主体建议控制在 120～200 行；
- 目标文件大小不超过约 15 KB；
- 不包含完整模板、产品匹配方法、字段写作范式或 checklist；
- 不重复 agent prompt 和阶段 reference 已经定义的内容。

### 8.2 只保留以下内容

1. Frontmatter：触发场景和不适用范围；
2. 主调度器职责；
3. 状态恢复算法；
4. 状态路由表；
5. agent 路由表；
6. 三至五条全局质量不变量；
7. 路径安全和不可信输入边界；
8. 状态返回协议；
9. 按需 reference 导航。

### 8.3 从主 SKILL.md 移出

- 产品匹配和复用方法；
- 需求卡片、Epic、Feature 字段说明；
- 用户故事拆分方法；
- 详细设计方法；
- 完整交互选项格式；
- 文档模板细节；
- 范式评分规则；
- checklist 全文；
- 脚本长命令示例；
- 多段重复的路径规则；
- Claude Code UI 使用说明的重复内容；
- 针对单次错误增加的特殊禁止语。

### 8.4 推荐主文件结构

```markdown
---
name: pm-orchestrator
description: ...
---

# 角色
# 调度算法
# 状态路由
# Agent 路由
# 全局不变量
# 安全边界
# 返回协议
# Reference 导航
```

---

## 9. Reference 重组

### 9.1 编排 reference

建议新增少量、一层可达的编排 reference：

```text
references/
├── orchestration-state-machine.md
├── orchestration-handoffs.md
└── orchestration-quality-gates.md
```

- `orchestration-state-machine.md`：状态 schema、迁移表和恢复规则；
- `orchestration-handoffs.md`：主调度器到三个 agent 的输入输出协议；
- `orchestration-quality-gates.md`：阶段转换和全局质量不变量。

不要为每个小状态创建一个只包含几行内容的 reference，避免文件碎片化。

### 9.2 需求分析 reference

将当前 687 行 `instruction.md` 改成简短入口，并拆出任务文件：

```text
references/requirement-analysis/
├── instruction.md          # 简短入口和核心不变量
├── intake.md               # 摘要确认、产品匹配、项目类型建议
├── requirement-card.md     # 需求卡片工作流
├── epic.md                 # Epic 工作流
├── feature.md              # Feature 工作流
├── question-bank.md
├── checklist.md
├── templates/
└── writing-paradigm/
```

`instruction.md` 只负责根据 handoff task 指向一个任务文件。每次调用最多加载：

```text
instruction.md
+ 当前任务文件
+ 当前任务需要的模板/范式/checklist
+ 项目事实和产品文档
```

### 9.3 去重原则

每条规则只能存在一个权威来源：

| 规则类型 | 权威来源 |
|---|---|
| 状态迁移 | `orchestration-state-machine.md` |
| Handoff 字段 | `orchestration-handoffs.md` |
| 用户交互展示 | 主调度器 interaction contract |
| 需求分析方法 | requirement-analysis 对应任务文件 |
| 字段写作范式 | `writing-paradigm/` |
| 阶段完成质量 | 对应 `checklist.md` |
| 文档结构 | 对应 `templates/` |
| 路径和渲染校验 | 脚本 |

发现重复时删除副本并保留链接，不要尝试同步两份文字。

---

## 10. Agent 合同调整

### 10.1 增加明确 task，而不是扩张 mode

保留现有：

```text
mode=draft | persist | validate
```

另增加专业任务字段：

```text
task=prepare-intake-summary
   | analyze-reuse
   | requirement-card
   | epic
   | feature
   | validate-phase
```

`mode` 表示是否草稿、落盘或校验；`task` 表示本轮专业工作。不要用一个字段同时承载两个维度。

### 10.2 Handoff 传路径，不重复传正文

优先传：

```yaml
projectPath: "<canonical-path>"
progressPath: "<projectPath>/progress.json"
productLibraryPath: "<canonical-library-path>"
productArchitectureDesignPath: "<validated-path>"
backgroundDirectory: "<projectPath>/docs/background"
upstreamDocPaths: []
task: "analyze-reuse"
mode: "draft"
interactionContract: "<compact-contract>"
```

不要让主调度器先读取并生成长摘要，再把摘要和原文路径同时传递。阶段 agent 应直接读取经过安全校验的源文件。

### 10.3 模型和 effort

- 主调度器只做确定性路由，主会话可使用 medium effort；
- 三个专业阶段 agent 保持当前质量模型，并显式使用 high effort；
- 不以更小模型替代专业 agent；
- 如果运行环境不支持分别设置 effort，优先通过职责与上下文精简提速，不降低全局 effort 作为首选方案。

### 10.4 Agent 输出

Agent 每轮只返回：

- 用户可见内容；
- `status`；
- `completedTask`；
- `suggestedNextState`；
- 必要的状态更新数据；
- 必要的文件更新建议。

主调度器验证 `suggestedNextState` 是否符合状态表，再调用状态脚本更新。Agent 不直接修改 `workflow.state`。

---

## 11. 脚本调整

### 11.1 `prepare-intake.sh`

调整为一次性完成：

- 校验项目 ID 和目标路径；
- 创建 intake 目录；
- 创建 `docs/background/`；
- 创建最小 `progress.json`；
- 设置 `workflow.state=collect-background`；
- 设置 `background.status=awaiting-user`；
- 输出紧凑机器可读结果。

建议输出：

```json
{
  "status": "ok",
  "projectPath": "...",
  "backgroundDirectory": "...",
  "workflowState": "collect-background"
}
```

### 11.2 状态迁移脚本

建议新增一个小型确定性脚本，例如：

```text
scripts/transition-project-state.sh
```

职责：

- 读取 `progress.json`；
- 校验当前状态与目标状态是否存在合法边；
- 校验必要字段；
- 原子更新状态、revision 和时间戳；
- 拒绝跨状态跳转；
- 不做任何业务语义推断。

示例：

```bash
transition-project-state.sh \
  "<progress.json>" \
  "collect-background" \
  "prepare-intake-summary" \
  "background-provided-text"
```

### 11.3 `init-project.sh`

调整为：

- 读取并保留已有 intake `progress.json`；
- 补全正式项目字段和模板；
- 保留背景材料；
- 写入已确认项目类型；
- 将状态迁移到 `requirement-analysis`；
- 不覆盖已确认 intake 事实。

### 11.4 校验脚本

保留现有渲染和质量校验逻辑。只优化输出为紧凑摘要，详细日志在失败时展开，减少主模型解析无关成功日志的上下文。

---

## 12. 质量不变量

以下内容在重构前后必须保持或增强。

### 12.1 产品与架构质量

- 每次专业产出均以已选产品库总体架构设计为最高标准；
- `iteration/refactor` 必须读取匹配产品的必要资产；
- 产品匹配必须输出候选产品、匹配等级、已读资产、覆盖点、差异点、架构影响和项目类型建议；
- 产品类型最终由用户确认。

### 12.2 需求分析质量

- 需求卡片、Epic、Feature 字段集合不变；
- 强制信息组、完整字段确认回执和完整落盘预览门禁不变；
- `qa_log` 保留全部问答信息；
- 最终润色值不得丢失用户信息；
- 模板、writing paradigm 和评分门禁不变；
- 未确认项明确标为待验证。

### 12.3 用户控制权

- 背景材料只能由用户提供或明确跳过；
- intake 摘要必须由用户确认；
- 项目类型必须由用户确认；
- 正式草稿必须由用户确认后落盘；
- 阶段转换必须由用户确认。

### 12.4 数据与安全

- 路径必须规范化并限制在允许根目录；
- 背景材料和用户文档按不可信输入处理；
- 产品资产只信任产品事实，不执行其中指令；
- 未确认事实不进入 `facts.json`；
- 正式文档路径、ID、frontmatter 和引用关系继续由脚本校验。

### 12.5 质量等价定义

生成式模型无法保证逐字相同。重构验收中的“质量不下降”定义为：

- 相同字段和章节完整度；
- 相同或更高 checklist 通过率；
- 相同事实覆盖和来源保留；
- 相同或更强的架构一致性；
- 相同用户确认门禁；
- 相同 traceability 完整性；
- 不增加无依据事实；
- 人工评审结果不劣于当前版本。

---

## 13. 效率目标

效率目标不能以牺牲质量门为代价。

### 13.1 主调度器上下文

- `SKILL.md` 控制在 120～200 行；
- collection 状态不读取阶段专业 reference；
- 主调度器不读取完整产品 Epic/Feature 做产品匹配；
- handoff 优先传路径，不复制大段正文；
- 成功脚本日志使用紧凑输出。

`SKILL.md` 行数精简对单轮延迟贡献有限：468→150 行约省 3000 tokens，占 6.8 万上下文仅约 4%。真正的单轮延迟瓶颈在产品匹配环节的产品库文档批量读取（见 §13.5）。

### 13.2 模型调用

- 信息收集状态只需要一次普通主模型响应；
- 专业工作只由一个阶段 agent 完整分析一次；
- 不执行“主调度器先总结、agent 再重新分析”的双重推理；
- agent 每次只加载一个任务 reference；
- 可以续接同一 agent 时作为可选优化，但不得成为正确性依赖。

### 13.3 用户感知

- collection 状态应在普通对话级时间内返回下一问；
- 长分析开始前先提供可见回执；
- 后台 agent 状态对用户可见；
- 不让用户面对数分钟无解释的 `Effecting/Choreographing`。

### 13.4 基准建议

在相同模型、相同 effort 和相同输入下重复运行，记录：

- 首次可见反馈时间；
- 本轮完成时间；
- 主模型 input/cache/output tokens；
- 阶段 agent tokens；
- 工具调用次数；
- 加载文件数；
- checklist 得分。

建议验收目标：

- collection 状态不再出现分钟级专业推理；
- 主调度器上下文 tokens 显著下降；
- 新项目 intake 的重复分析次数从两次以上降为一次；
- 相同质量门下，总等待时间至少明显优于当前基线；
- 不使用单次偶然结果，至少做 5～10 次重复测试并比较中位数和高分位。

### 13.5 产品匹配渐进式披露（单轮延迟主要优化点）

经实际文件验证，产品匹配是单轮延迟的主要来源。按 `product-library-spec.md` §8 当前流程，一次匹配对每个通过初筛的候选都要读 `requirement-cards/` 全部卡片 + `epics/` 全部 Epic；N 个候选 = N 份卡片 + N 份 Epic 全量加载，约占 6.8 万 tokens 中的 2-4 万。候选导览表（Step 6）又需读卡片正文填表，形成重复读取；且无早停机制，即使首候选明显不匹配也要读完所有候选才能排序。

当前流程两个渐进式披露缺口：

1. **候选导览过度读取**：`instruction.md` 候选导览表"它解决的问题/重叠闭环/扩展方向"需读需求卡片正文才能生成，导致用户选定候选前已读完所有候选卡片。
2. **无早停机制**：当前是"全读完→全评分→全排序→给用户选"，而非"读一个→判→不匹配即跳"。

改进要求（实施时改 `product-library-spec.md` §8 和 `instruction.md` 对应段）：

改进 A/B 不是独立"加分支"，而是 §8 Step 3 与 Step 6 的整体流程重排。当前 Step 3 对所有候选批量读 cards+epics、Step 6 复用 Step 3 数据生成导览。重排后导览前置、只读 `_product.md`，用户选定候选后再读该候选卡片并做早停，不匹配即停不读 Epic。若只加 if 分支而不重排，Step 3 仍批量读取，不省 token。

#### 改进 A：候选导览前置并只读 `_product.md`

将 §8 Step 6 导览前移到 Step 2（D6 领域初筛）之后，作为新 Step 2.5。导览数据源从"读需求卡片正文"改为"复用 Step 2 已读的 `_product.md`"，不额外读卡片、不重复读 `_product.md`。

导览表因数据源限制需同步删列：`_product.md` 的 `summary`/`businessDomain`/`keywords` 三字段只能支撑"候选产品 / 它解决的问题 / 建议优先级"三列。当前导览表"可能重叠的业务闭环""可能扩展的方向"两列需读 Epic/Feature 正文才能填，必须删除，留到用户选定候选后的解读阶段再展示。

| 列 | `_product.md` 能否填 | 处理 |
|---|---|---|
| 候选产品 | ✓（id/name） | 保留 |
| 它解决的问题 | ✓（summary） | 保留 |
| 可能重叠的业务闭环 | ✗（需 Epic） | 删除，移到选定候选后 |
| 可能扩展的方向 | ✗（需 Feature） | 删除，移到选定候选后 |
| 建议优先级 | ✓（D6 领域） | 保留 |

**显式降级声明**：导览阶段的"建议优先级"从原"语义深度匹配（D1-D5）"降级为"领域初筛（D6）"，深度匹配留到用户选定候选后。这是用户接受的取舍（用户在卡片层即可自行判断不匹配）。实施者不得在导览阶段尝试算 D1/D2/D3，否则又需读卡片。

#### 改进 B：单个候选需求卡片层早停（3a 与 3b 之间）

当前 §8 Step 3 结构是"3a 读 cards 评 D1/D2/D3 → 3b 读 epics 评 D4/D5"。早停分支必须插在 **3a 与 3b 之间**（不是 Step 3 与 Step 4 之间），否则 3b 已读完 Epic，早停无效。

用户选定候选后只读该候选卡片（3a），完成 D1/D2/D3 评分后执行早停判断：

| 条件 | 动作 |
|---|---|
| D1 < 50 且 D2 < 50（问题本质和痛点均不匹配） | 告知用户该候选不匹配，**不执行 3b（不读该候选 Epic/Feature）**，提供"看下一个候选"选项 |
| D1 ≥ 50 或 D2 ≥ 50 | 继续执行 3b 读该候选 Epic 评 D4/D5 |

**早停候选全耗尽 fallback**：若所有候选均早停（全部 D1<50 且 D2<50），建议项目类型为 `new`，向用户展示"所有候选均不匹配，建议新建项目"并等待确认，不阻断流程。

早停的候选不参与 Step 5 排序。效果：不匹配候选只读到卡片层即停，省 Epic + Feature 读取。

#### 改进 C：产品匹配移主（见 §5.1）

已在 §5.1 定义。与改进 A/B 配合，主调度器单轮上下文从"加载 instruction 片段 + 产品库文档"降到"只传路径"。

#### 验收指标

| 指标 | 目标 |
|---|---|
| 单次产品匹配读取的产品库文档数 | 从"所有候选卡片+Epic"降到"所有候选 `_product.md`（Step 2 已读复用）+ 选中候选卡片 + 可能匹配候选 Epic" |
| 导览表列数 | 从 5 列降为 3 列 |
| 主调度器在 `analyze-reuse` 状态加载的 reference | 不加载 `instruction.md` 产品匹配段 |
| 单轮 input tokens | 从约 6.8 万可观测下降 |

#### 实施顺序

1. 先做改进 C（移主，§5.1）：成本最低，立即消除主调度器双重推理
2. 再做改进 A（导览前置并只读 `_product.md`）：改 `product-library-spec.md` §8 Step 2.5/6 和 `instruction.md` 导览段，同步删导览表两列
3. 最后做改进 B（早停）：在 §8 Step 3a 与 3b 之间加分支，同步调整 Step 5 排序逻辑（早停候选从候选列表移除）和全耗尽 fallback

---

## 14. 文件级改造清单

### 14.1 `skills/pm-orchestrator/SKILL.md`

- 重写为调度内核；
- 使用显式状态路由表；
- 删除阶段专业方法；
- 删除重复 UI 规则；
- 删除重复脚本说明和长命令；
- 只保留全局不变量、安全边界和 reference 导航；
- 目标 120～200 行。

### 14.2 `agents/requirement-analyst.md`

- 墂加 `task` 路由；
- 接管 `prepare-intake-summary` 和 `analyze-reuse`；
- 直接读取经过校验的架构、产品库和背景路径；
- 保持 high effort；
- 不直接修改主工作流状态；
- 返回建议状态，由主调度器验证后更新。

### 14.3 其他两个 agent

- 保持专业质量配置；
- 使用相同的 `task/mode/status/suggestedNextState` 合同；
- 不承担阶段转换；
- 按任务加载最小 reference。

### 14.4 `references/requirement-analysis/instruction.md`

- 缩成阶段入口和核心质量不变量；
- 删除完整工作流长文；
- 根据 task 指向 `intake.md`、`requirement-card.md`、`epic.md`、`feature.md` 或 `checklist.md`；
- 解决“信息组提问”与“逐字段提问”的冲突，统一为：信息组是提问单位，字段是输出单位。

### 14.5 `scripts/prepare-intake.sh`

- 创建最小 `progress.json`；
- 初始化明确状态；
- 输出紧凑 JSON；
- 保持跨平台和路径安全。

### 14.6 `scripts/init-project.sh`

- 合并而非覆盖 intake 状态；
- 保留背景材料、原始描述和用户确认结果；
- 完成合法状态迁移。

### 14.7 新状态迁移脚本

- 实现合法迁移表；
- 校验前置条件；
- 原子更新 JSON；
- 为状态迁移提供单元测试。

### 14.8 `project-template/progress.json`

- 增加 `workflow` 和 `intake` schema；
- 保持现有阶段状态字段兼容；
- 定义 schema version，便于旧项目迁移。

### 14.9 Evals

- 保留现有 routing、status、story breakdown grader；
- 新增 intake 状态机、职责边界、质量等价和性能 trace grader。

### 14.10 `product-library-spec.md` §8 匹配流程

- 新增 Step 2.5（导览前置）：从 Step 6 移到 Step 2 之后，数据源复用 Step 2 已读的 `_product.md`，不额外读卡片、不重复读 `_product.md`（§13.5 改进 A）；
- 原有 Step 6 导览逻辑删除（已前移到 Step 2.5），原 Step 6 位置改为"用户选定候选后进入 Step 3"；
- Step 3a 与 3b 之间新增早停分支：D1 < 50 且 D2 < 50 的候选不执行 3b（不读其 Epic/Feature），不参与 Step 5 排序（§13.5 改进 B）；
- Step 5 排序逻辑同步调整：早停候选从候选列表移除，只对通过早停的候选排序；
- 新增全耗尽 fallback：所有候选均早停时建议 `new`，不阻断。

### 14.11 `references/requirement-analysis/instruction.md` 候选导览段

- 候选导览表删除"可能重叠的业务闭环""可能扩展的方向"两列（需 Epic/Feature 正文，导览阶段无数据源），保留"候选产品 / 它解决的问题 / 建议优先级"三列；
- 删除的两列内容移到"用户选定候选后的单个已有产品解读"阶段展示；
- 导览"建议优先级"降级为 D6 领域初筛，不计算 D1-D5；
- 与 `product-library-spec.md` §8 Step 2.5 保持单一权威来源，不重复定义导览字段来源。

---

## 15. 兼容旧项目

不得删除或重置现有项目状态。

建议迁移规则：

1. `projectType` 已是 `new/iteration/refactor`：根据现有 `currentPhase` 恢复，不重新进入 intake；
2. `projectType=pending` 且已有明确背景确认记录：恢复到对应后续状态；
3. `projectType=pending` 但无法证明用户已经提供或明确跳过背景材料：恢复到 `collect-background`；
4. 仅存在 intake 目录、没有 `progress.json`：创建最小状态并设为 `collect-background`；
5. 不把目录为空自动解释为用户已跳过；
6. 迁移前备份或使用原子写入，失败时保留原文件。

---

## 16. 测试与验收

### 16.1 必测流程

#### 新项目、长初始描述

输入完整需求描述后：

- 创建 intake 目录；
- 返回背景目录路径和“提供/粘贴/明确跳过”选项；
- 状态为 `collect-background + awaiting-user`；
- 不把初始描述当作背景材料事件；
- 不在本轮产生产品匹配或项目类型建议。

#### 用户明确跳过背景材料

- 记录 `explicitlySkipped=true`；
- 状态迁移到 `prepare-intake-summary`；
- 需求分析 agent 基于原始描述生成待确认摘要；
- 不虚构背景事实。

#### 用户提供文件

- 读取固定目录中的文件；
- 保留来源；
- 按不可信输入处理；
- 完成摘要后等待用户确认；
- 用户确认前不进入产品匹配。

#### 用户直接粘贴背景材料

- 只有在系统正等待背景材料时，才记录到 `background.pastedContent`；
- 初始需求消息不能自动归类为背景材料回复。

#### Intake 摘要被用户修正

- 修正内容进入下一版摘要；
- 产品匹配使用用户确认后的摘要；
- 不使用已被用户否定的旧内容。

#### 产品匹配

- 由 `requirement-analyst` 完成；
- 主调度器不加载完整需求分析方法和产品 Epic；
- 输出覆盖点、差异点和架构影响；
- 项目类型由用户确认。

#### 旧项目恢复

- 不重复 intake；
- 不丢失已有阶段状态；
- 不因缺少新 schema 而重置项目；
- 无法证明背景步骤已完成时采用安全恢复状态。

### 16.2 质量回归

使用相同输入对旧版和新版进行盲评或结构化评分：

- 需求字段覆盖；
- 事实保真；
- 问题深度；
- 架构一致性；
- 产品复用判断质量；
- 边界与待验证项；
- 文档结构和范式；
- traceability；
- 用户确认点。

任何核心维度下降都不能以“速度更快”为理由接受。

### 16.3 Trace 验收

新增 grader 检查工具轨迹和文件加载边界：

- `collect-background` 期间只允许 intake 状态和目录相关操作；
- 主调度器不读取需求分析专业 reference 完成产品匹配；
- `analyze-reuse` 必须由 `requirement-analyst` 执行；
- 每个状态只发生合法迁移；
- 用户确认事件能够对应到 `awaitingResponseTo`；
- 正式落盘仍经过现有脚本和校验。

产品匹配渐进式披露的 trace 检查（对应 §13.5）：

- 候选导览阶段（Step 2.5）只读取 `_product.md`，不读取 `requirement-cards/` 正文；
- 导览表只有 3 列（候选产品 / 它解决的问题 / 建议优先级），无"重叠闭环""扩展方向"列；
- D1 < 50 且 D2 < 50 的候选在 Step 3a 后未进入 3b，未被读取其 `epics/` 和 `features/`；
- 所有候选均早停时触发 fallback，建议项目类型 `new`；
- 主调度器在 `analyze-reuse` 状态未加载 `instruction.md` 产品匹配段；
- 继续项目的 `iteration`/`refactor` 状态同样由 analyst 读产品库路径，主调度器不读正文；
- 单轮加载的产品库文档数符合 §13.5 验收指标。

这里检查的是架构边界，不是在 prompt 中增加局部“禁止语”。

---

## 17. 推荐实施顺序

### 阶段 A：冻结质量基线

1. 保存当前真实案例输入和产出；
2. 运行现有 evals；
3. 记录字段覆盖、checklist、tokens、耗时和文件读取轨迹；
4. 确定不可下降的质量指标。

### 阶段 B：建立状态源

1. 扩展 `progress.json` schema；
2. 修改 `prepare-intake.sh`；
3. 实现状态迁移脚本；
4. 为状态迁移编写单元测试；
5. 完成旧项目兼容逻辑。

### 阶段 C：重写主调度器

1. 把 `SKILL.md` 重写成内核；
2. 建立状态路由和 agent 路由；
3. 删除专业方法和重复规则；
4. 将 handoff 改为路径和 task；
5. 确保每轮只执行当前状态处理器；
6. 删除 intake 流程第 7 步中主调度器读取 `instruction.md` 产品匹配段的逻辑，改为只传路径（§5.1 改进 C）。

### 阶段 D：重组需求分析 agent

1. 拆分 687 行 instruction；
2. 增加 `prepare-intake-summary` 和 `analyze-reuse` task；
3. 统一信息组/字段提问口径；
4. 保持现有模板、范式和 checklist；
5. 设置专业 agent 的质量配置；
6. 重组产品匹配流程：候选导览前置并只读 `_product.md`（§13.5 改进 A），在 Step 3a/3b 之间新增 D1/D2 早停分支（§13.5 改进 B）；
7. 同步修改 `product-library-spec.md` §8 Step 2.5/3/5/6（§14.10）。

### 阶段 E：验证与灰度

1. 运行全部现有 evals；
2. 运行新增状态机和 trace evals；
3. 对旧版和新版做质量对比；
4. 重复运行性能基准；
5. 先用测试项目灰度，不直接迁移唯一生产项目；
6. 只有质量不下降且状态错误消失后再正式替换。

---

## 18. 实施时应避免的反模式

- 为每个观察到的问题追加一条禁止语；
- 在 `SKILL.md`、agent prompt 和 reference 中复制同一规则；
- 同时让主调度器和 agent 理解相同产品文档；
- 用“描述已经很完整”推断用户跳过明确确认；
- 用自然语言猜测状态，而不是读取状态字段；
- 为了少一次用户交互合并两个独立确认；
- 让 agent 直接修改主工作流状态；
- 为追求速度降低阶段模型质量；
- 一次加载整个 reference 目录；
- 创建大量只有几行内容的碎片 reference；
- 用摘要替代完整字段确认或完整落盘预览；
- 只测最终文案，不检查工具轨迹和状态迁移。

---

## 19. 最终完成标准

只有同时满足以下条件，重构才算完成：

1. 主 `SKILL.md` 已精简为状态调度内核；
2. Intake 使用持久化显式状态，不依赖模型猜测；
3. 初始描述和背景材料完全分离；
4. 产品匹配只由 `requirement-analyst` 完成；
5. 主调度器不重复读取和分析阶段专业文档；
6. 阶段 agent 保持高质量模型、方法、模板和 checklist；
7. 所有用户确认点仍然存在；
8. 正式文档结构、字段、traceability 和校验不下降；
9. 旧项目可安全恢复；
10. 新增状态机、trace、质量和性能测试全部通过；
11. 新项目 intake 不再发生分钟级主调度器空转；
12. 不依赖任何针对单一案例的局部补丁。

重构完成后的核心判断标准是：**主调度器更小、更确定；专业 agent 的输入更完整、职责更集中；质量门保持不变；用户等待来自真正必要的专业分析，而不是重复编排和规则冲突。**
