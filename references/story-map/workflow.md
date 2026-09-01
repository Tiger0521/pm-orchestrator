# 故事地图阶段执行流程（旅程提取 + 用户故事拆解 + 故事地图组装）

本文件在 `mode=draft` 执行 story-map 阶段时读取，定义合并后的 6 步工作流（Step 0 - Step 5）、上游质量门、新鲜度检查和项目类型自适应规则。本阶段**一次完成**旅程提取 → Story 拆解 → 溯源矩阵 → 故事地图组装，不再有独立的地图生成模式。

## 总体流程

```
Step 0: 固定必读与新鲜度检查（业务文档 + 需求台账 + refs.json 对账）
Step 1: 旅程提取（业务文档业务场景表按所属能力列分组 -> 能力内旅程节点 -> 全局旅程叙事线，写入 phase-summary.md）
Step 2: 角色规则（角色来自能力文档用户角色，Story 角色具体化）
Step 3: 按 Feature 批量生成 Story + 审阅（每条含 journey_stage / requirementEntryId / 三块内容，按 Feature 分组确认）
Step 4: 故事地图组装（从已确认 Story 的 journey_stage 组装能力级地图）
Step 5: 全部落盘（Story -> 产品库，矩阵 -> 过程项目，地图 -> 产品库 用户故事地图/，叙事线更新 phase-summary.md，refs.json 注册 edges）
```

第 1 步旅程确认、第 2 步角色规则、第 3a 步候选总表选择、每组 Feature 的三块内容审阅、第 4 步地图方案展示，以及整批落盘确认需要用户确认。确认方法见 `confirmation-method.md`。

## 第 0 步：固定必读与新鲜度检查

- 按 `instruction.md`"每轮固定必读"读取：`businessDocPath`（业务文档）、`requirementLedgerPath`（需求台账）、`productArchitectureDesignPath`、项目 `progress.json` 与 `phase-summary.md`。
- 对 `refs.json` 与业务文档、需求台账做**对账与新鲜度检查**：运行 `product-library-tools.mjs reconcile`，比对 `contentHash`，只读变更报告中的 `changed`/`new` 文档。
- **迭代旅程场景**：当 `phase-summary.md` 已存在旅程叙事线时，比对业务文档「业务场景表」与台账条目是否有新增/修改；有更新时必须增量提取，不得沿用旧叙事线组织新 Story。
- 业务文档或需求台账缺失、不可读，或对账失败时返回 `blocked`；业务场景表或台账条目为空时返回 `needs-input`，附注缺失清单。

## 第 1 步：旅程提取

- 读取业务文档「业务场景」字段的业务场景表（SC-XX 编号，含「所属能力」列），**按所属能力列分组**，从每个能力的场景推导该能力内的**旅程节点**（能力级横轴）。
- 将各能力内旅程节点对齐为**全局旅程叙事线**（3-6 个全局阶段），阶段命名简短动宾结构（如"建址""维址"）。提取方法见 `guides/journey-extraction.md`。
- 旅程叙事线写入 `phase-summary.md`；已存在于该文件时按新增/变更**增量更新**，不覆盖已验证节点。
- 向用户确认一次全局旅程叙事线与能力映射（先展示摘要，再给理解回执，最后提聚焦问题）。
- `journey_stage` 值格式约定：默认 `<全局旅程阶段>-<能力内节点>`（如 `建址-审核核准`）；当能力仅映射单一全局阶段时可为全局阶段名（如 `维址`）。所有 Story 的 `journey_stage` 必须取自已确认的叙事线节点。

## 第 2 步：梳理角色和规则

- 角色来自能力文档的用户角色字段（上游 Feature 事实），不从业务侧凭空新增；发现能力文档未覆盖的角色时先追问用户确认为待确认项。
- Story 角色必须是具体角色名（如"地址管理员"），不使用笼统的"用户""管理员"。
- 输出"角色-规则-流程"摘要回执，按确认流程向用户确认一次。此步只确认一次，不逐条 Story 确认。

## 第 3 步：候选选择 + 按 Feature 批量生成与审阅

这是本阶段的核心操作。候选生成与范围选择先读取 `core-mechanisms.md`、`writing-paradigm/user-story-writing.md` 和 `confirmation-method.md`；用户选定候选后才读取 `grilling-protocol.md`。不得跳过候选总表而直接要求用户从空白开始编写 Story。

1. **自主生成候选**：基于 Feature 的能力目标、业务流程、业务规则和所属旅程节点，先由 AI 为每个 Feature 拆出主干 Story 候选。每个候选必须明确来源 Epic、来源 Feature、来源能力、角色、用户目标、业务价值和拟覆盖的旅程节点；先做 INVEST 与颗粒度自检。此时不编写 GWT。
2. **展示候选总表**：按 `core-mechanisms.md` 的"主干 Story 候选总表"格式输出概述表。表格必须写清每条候选由哪个 Feature/能力拆出，不能只给 Story 名称；候选标签使用大写字母。
3. **让用户初步选择讨论范围**：展示总表和理解回执后，只问一个聚焦问题：请用户选择本轮值得深入讨论的一个或多个候选标签。未选候选保留在总表中，不得擅自当作已确认或删除。
4. **按 Feature 分组生成完整草稿**：为已选候选按 Feature 分组，同一 Feature 下全部 Story 的完整草稿一次生成。每条 Story 固定三块内容：三段式（故事卡）、GWT 验收标准、边界异常，均完整列出不缩写。每条 Story 自动附带：
   - **优先级**：继承对应需求台账条目的优先级（`requirementEntryId` 指向的条目）；条目缺失或优先级未定时标"待确认"并向用户询问。
   - **`requirementEntryId`**：指向台账实际条目（`<简称>-REQ-<序号>`），与 frontmatter refs 的 `addresses` 及正文块引用 wikilink 保持一致。
   - **`journey_stage`**：取自已确认旅程叙事线的节点。
   - **Story Points**：AI 给建议值（标注"建议值，待团队确认"）。
   每条 Story 创建或恢复 `story-<nnn>.json`，写入来源信息后按 `grilling-protocol.md` 批量审阅。
5. **逐组展示与批量修正**：**一次只展示一个 Feature 组**的全部 Story 完整草稿清单，让用户整体审阅。默认不逐条问；仅当某条 Story 的三块内容说不清、无法从上游推导时才针对该条提一个聚焦问题。
6. **共同理解后确认该组，进入下一组**：该组所有 Story 经用户确认或修正后，写回 JSON；然后展示下一个 Feature 组。**绝不一次全量返回所有 Feature**。
7. **进入落盘的条件**：所有已选 Feature 组的决策组均通过共同理解门禁后，进入地图组装与完整预览。未选候选不生成 GWT、不进入落盘。

## 第 4 步：故事地图组装

从**已确认 Story 的 `journey_stage`** 组装故事地图（不再从架构设计文档核心场景推导）：

1. **能力级地图（逐个能力迭代）**：为每个 Feature 所属能力，读取已确认 Story 及其 `journey_stage`，按 `guides/story-placement.md` 放置到"能力内旅程节点 × 优先级（P0/P1/P2）"的 2D 矩阵；识别该能力的 MVP 行走路径并标注 ⭐；撰写能力级行走路径叙事；标注覆盖空白与路径断裂。
2. **逐个能力迭代**：能力级方案按能力逐个展示确认，每个方案确认后其内容进入落盘清单。不批量一次展示全部能力的完整地图。
3. 地图方案的质量自检按 `core-mechanisms.md` 第 14 节执行：矩阵形态、横轴方向、行走路径、故事覆盖、能力对齐、数据一致、链接有效、优先级完整。

## 第 5 步：全部落盘

当 `mode=persist` 且用户已确认时，读取 `persist-guide.md` 执行落盘流程：

- Story 写入产品库 `<能力路径>/用户故事/<简称>-<能力路径>-<标题>故事.md`，由 `render-story.sh` 渲染（自动分配继承式 ID、自动写作规范校验，零警告才报告 `persisted`）。
- 溯源矩阵写入过程项目 `docs/requirement-analysis/matrix-<nnn>.md`，由 `render-matrix.sh` 渲染。
- 能力级地图写入产品库 `用户故事地图/`。
- 旅程叙事线更新 `phase-summary.md`（含最新节点、能力映射与变更记录）。
- `refs.json` 注册 edges：Story `implements` Feature、Story `addresses` 需求台账条目、Matrix `references` Feature。
- 更新 `facts.json`、`decision-log.md`、`tracking-log.md`、`phase-summary.md`；`progress.json` 只更新当前阶段和顶层 `lastUpdated`。

## 上游质量门

本阶段开始前检查上游文档质量：

- 业务文档含「业务场景」字段的业务场景表（SC-XX 编号，含「所属能力」列），场景表非空且含能力内流程步骤。
- 需求台账条目存在且含优先级；条目缺失或优先级未定必须标"待确认"，不得从 Feature/能力文档继承优先级。
- Feature 的业务流程字段非空，含关键步骤和触发条件；Feature 的业务规则字段非空，含异常处理。
- 如果上游文档存在字段缺失或内容空洞，向主调度器返回 `needs-input`，附注缺失字段清单。
- 若 Feature 的 `status` 为 `draft`，向主调度器报告 `needs-input`。

## 规模自适应

项目类型在需求分析 intake 中收敛，写入 `progress.json` 的 `projectType` 字段。本阶段读取该字段决定流程深度：

| 环节 | 全新项目 (`new`) | 迭代项目 (`iteration`) | 重构项目 (`refactor`) |
| ---- | -------- | -------- | -------- |
| 新鲜度检查 | 全量对账业务文档与台账 | 重点比对本轮涉及能力的业务场景表与台账条目更新 | 全量对账，标记受影响能力 |
| 旅程提取 | 从全部业务场景表推导完整叙事线 | 增量提取新增能力的旅程节点并入现有叙事线 | 沿旧叙事线校验，聚焦受影响能力节点 |
| 角色梳理 | 完整列出所有角色 | 聚焦新增能力涉及的角色 | 聚焦受影响角色和权限变化 |
| Story 拆分 | 完整拆分全部 Feature | 聚焦新增 Feature 的 Story 拆分 | 只产出非功能性需求的 Story（性能、安全、兼容性等） |
| 地图组装 | 逐能力全量组装 | 新增能力的 Story 并入已有能力级地图 | 受影响能力的地图局部更新 |
| 覆盖度检查 | 全部 Feature 覆盖 | 新增 Feature 覆盖 | 已有 Feature 覆盖 |

路由不是机械省略。若拆解过程中暴露上游 Feature 信息不足，返回主调度器要求补问或回退。

规模较大时（Story 数量很多），仍按 Feature 分组逐组批量审阅，避免逐条逐节点盘问；**一次只展示一个 Feature 组**，组内每条 Story 三块内容完整列出不缩写，该组确认后再展示下一组，用户滚动确认，不要求一次确认全部 Feature。