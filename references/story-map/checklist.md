# 故事地图阶段质量门

阶段完成并推进到「详细设计」或「Sprint 规划」前，必须逐条通过以下校验。校验项分为文件存在性、Frontmatter 完整性、User Story 质量、验收标准质量、旅程阶段与台账关联、覆盖度、溯源矩阵、审阅状态、用户确认、故事地图、记忆更新十一类。

---

## 文件存在性

- [ ] 至少一个 `docs/requirement-analysis/feature-*/story-*.md` 存在
- [ ] 至少一个 `docs/requirement-analysis/matrix-*.md` 存在
- [ ] 每条 Story 位于其唯一 `implements` 引用所指 Feature 的子目录；矩阵位于 `docs/requirement-analysis/` 根层
- [ ] 产品库 `<能力路径>/用户故事/` 下存在已落盘 Story；`用户故事地图/` 下存在能力级地图
- [ ] 需求拆解产物未写入 `docs/design/`、需求分析目录根层的 `story-*.md` 或其他 Feature 目录

---

## Frontmatter 完整性

每份文档必须包含：

- [ ] `id`
- [ ] `type`
- [ ] `projectId`
- [ ] `title`
- [ ] `status`
- [ ] `refs`（至少一条引用关系）
- [ ] User Story 的 `refs` 包含 `implements` 关系指向 Feature
- [ ] User Story 的 `refs` 包含 `addresses` 关系指向需求台账条目（`id` 为条目级 ID `<简称>-REQ-<序号>`）
- [ ] User Story 的 frontmatter 含 `journey_stage`（有值且属于已验证旅程叙事线节点）
- [ ] 溯源矩阵的 `refs` 包含 `references` 关系指向 Feature

---

## User Story 质量

写作规范判断依据见 `writing-paradigm/user-story-writing.md`。

- [ ] 每条 Story 采用三段式格式："作为 [角色]，我想要 [目标]，以便于 [价值]"
- [ ] 每条 Story 有明确角色（不使用笼统的"用户""管理员"，具体到角色名）
- [ ] 角色来源可追溯到 Epic 或 Feature 的用户角色字段
- [ ] 每条 Story 有明确用户价值（价值描述清晰、合理，不是功能描述的重复）
- [ ] 每条 Story 满足 INVEST 原则（独立、可协商、有价值、可估算、足够小、可测试）
- [ ] 每条 Story 工作量在一个 Sprint 内可完成（Story Points ≤ 13）
- [ ] 活动描述用户意图，不描述技术实现（无接口名、页面名、模块名）

---

## 验收标准质量

- [ ] 每条 Story 有 3-8 条 GWT 验收标准
- [ ] 每条 AC 以 `**加粗关键词**` 开头（关键词是场景判断词，不是"AC1"等编号）
- [ ] 验收标准覆盖正常路径（用户按预期流程操作，系统返回成功）
- [ ] 验收标准覆盖异常路径（权限不足、数据为空/超限、网络异常/超时、并发冲突、重复提交、输入格式错误）
- [ ] 验收标准覆盖边界场景（数据边界、状态边界、权限边界）
- [ ] GWT 格式规范（Given 前置状态 + When 触发动作 + Then 期望结果，齐全且不混淆）
- [ ] Given 描述前置状态（不是操作步骤）
- [ ] When 描述具体触发动作（不是"系统执行"等笼统描述）
- [ ] Then 写具体系统行为（含提示语或预期数据，不是"提示错误"等笼统描述）
- [ ] 提示语用引号标出（如"配置名称已存在"）
- [ ] 每条 AC 只覆盖一个场景
- [ ] 跳过的异常场景已说明理由

---

## 旅程阶段与台账关联

- [ ] 每条 Story 的 `journey_stage` 有值，且属于已确认并写入 `phase-summary.md` 的旅程叙事线节点白名单
- [ ] 每条 Story 的 `requirementEntryId` 指向需求台账中**实际存在**的条目（`<简称>-REQ-<序号>`）
- [ ] Story frontmatter refs 的 `addresses` 值与该 Story 的 `requirementEntryId` 一致
- [ ] Story 正文存在关联需求段落，使用文件链接 + 条目ID（`[[<简称>-需求台账|<条目ID>]]`）
- [ ] 每条 Story 的优先级**来自台账条目优先级（继承）**；条目缺失或未定的 Story 已标"待确认"且已向用户询问

---

## 覆盖度

- [ ] 每个 Feature 至少被一条 Story 实现
- [ ] 所有高优先级（P0）Feature 已被 Story 覆盖
- [ ] 关键业务规则在 Story 的验收标准中体现
- [ ] 异常场景有对应 Story 或 AC
- [ ] 体验型 Story 已识别和补充（哪些 Feature 需要体验型 Story 已评估）

---

## 溯源矩阵

- [ ] 矩阵包含所有需拆解的 Feature 和所有已拆解的 Story
- [ ] 矩阵 Story 列表包含「旅程阶段」「需求台账条目」两列，且与各 Story frontmatter 一致
- [ ] 每条 Story 与 Feature 的映射关系清晰（Story ID → Feature ID + 覆盖度）
- [ ] 矩阵显示覆盖度（完整/部分）
- [ ] 覆盖度检查清单完整（每个 Feature 至少一条 Story、所有 P0 Feature 已覆盖）

---

## 审阅状态

- [ ] 每条已选 Story 都有对应的 `docs/_extracted/.stories/story-<nnn>.json`，且顶层 Story/AC 字段可用于渲染
- [ ] 每个最终字段可追溯到 `interview.fact_checks` 的已核实事实或 `interview.decision_tree` 的用户确认节点
- [ ] 每条 Story 的三块内容（三段式 `story_card`、GWT `gwt`、边界异常 `boundary_exception`）均已确认；任何 `forced-skip` 都有用户明确跳过理由、受影响范围和验证条件
- [ ] 每条 Story 的 `shared_understanding` 均为 `confirmed`，不存在未处理的上游 Epic/Feature 冲突
- [ ] 优先级继承台账条目、Story Points 为 AI 建议值（标注"建议值，待团队确认"）、`journey_stage`/`requirementEntryId` 自动回填、溯源矩阵由脚本自动生成，未逐条向用户盘问
- [ ] `interview.qa_log` 已按轮次记录润色后的审阅问题和用户修正，保留全部业务信息量而非逐字照抄
- [ ] 审阅未越界到详细设计范畴（性能阈值、技术选型、数据模型、接口、延迟）；这类问题均记为"详细设计待定"而非审阅用户
- [ ] 会话恢复将从 `interview.current_node` 的已满足依赖之后继续，不重问已确认内容

---

## 用户确认

- [ ] 用户已按 Feature 分组确认 Story 拆分方案（每条 Story 的三段式 + GWT 验收标准 + 边界异常）
- [ ] 用户已确认旅程叙事线与各 Story 的 `journey_stage`
- [ ] 用户已确认每条 Story 的台账条目关联（`requirementEntryId`）
- [ ] 优先级为台账条目继承值，缺失时已按"待确认"询问用户
- [ ] 优先级与 Story Points 为自动附带建议值，用户已确认或认可（未逐条盘问）
- [ ] 用户已确认溯源矩阵覆盖度
- [ ] 用户已确认能力级地图方案（行走路径、跨能力衔接、覆盖空白）
- [ ] 用户看到并确认的是完整 Story 落盘预览与地图预览，不是摘要草稿

---

## 故事地图

- [ ] **矩阵形态**：能力级地图均为 Markdown 表格形式的 2D 矩阵（非一维列表、非 ASCII 画图）
- [ ] **横轴方向**：矩阵列标题按旅程节点/阶段从左到右排列，有明确时间/流程方向性
- [ ] **行走路径**：P0 行构成从左到右的连贯路径；P0 行空单元格标注"行走路径断裂"；⭐ 标记行走路径故事
- [ ] **故事覆盖**：产品库全部用户故事都出现在能力级地图；每条故事唯一归属一个旅程阶段
- [ ] **能力对齐**：所有能力都映射到全局旅程阶段
- [ ] **数据一致**：能力级地图故事总数之和 = 已落盘 Story 总数
- [ ] **链接有效**：地图 wikilink 指向的 Story 文件与能力级地图文件在产品库中实际存在
- [ ] **优先级完整**：每条故事都有明确的 P0/P1/P2 归属，且来自台账条目继承；"待确认"项已清零

---

## 记忆更新

- [ ] `refs.json` 已注册所有新文档节点（story-*/matrix-*，含 `libraryId`/`contentHash`/`lastSynced`）和引用边（Story `implements` Feature、Story `addresses` 台账条目、Matrix `references` Feature）
- [ ] `facts.json` 已记录已确认事实（角色、规则、流程步骤、旅程节点）
- [ ] `decision-log.md` 已记录拆分决策（拆分方案、颗粒度调整、旅程阶段划分、优先级排序及理由）
- [ ] `tracking-log.md` 已记录新发现的风险/假设/未决问题（依赖关系、待验证项）
- [ ] `phase-summary.md` 已维护旅程叙事线与本阶段摘要（产物清单、关键拆分决策、遗留问题）
- [ ] `progress.json` 已更新当前阶段和顶层 `lastUpdated`；`workflow.state` 和阶段状态由主调度器在校验通过后更新