# 需求拆解阶段质量门

阶段完成并推进到「详细设计」前，必须逐条通过以下校验。校验项分为文件存在性、Frontmatter 完整性、User Story 质量、验收标准质量、覆盖度、溯源矩阵、用户确认、记忆更新八类。

---

## 文件存在性

- [ ] 至少一个 `docs/design/story-*.md` 存在
- [ ] 至少一个 `docs/design/matrix-*.md` 存在
- [ ] 需求拆解阶段正式产物未分散写入 `docs/requirement-analysis/` 或其他目录

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

## 覆盖度

- [ ] 每个 Feature 至少被一条 Story 实现
- [ ] 所有高优先级（P0）Feature 已被 Story 覆盖
- [ ] 关键业务规则在 Story 的验收标准中体现
- [ ] 异常场景有对应 Story 或 AC
- [ ] 体验型 Story 已识别和补充（哪些 Feature 需要体验型 Story 已评估）

---

## 溯源矩阵

- [ ] 矩阵包含所有需拆解的 Feature 和所有已拆解的 Story
- [ ] 每条 Story 与 Feature 的映射关系清晰（Story ID → Feature ID + 覆盖度）
- [ ] 矩阵显示覆盖度（完整/部分）
- [ ] 覆盖度检查清单完整（每个 Feature 至少一条 Story、所有 P0 Feature 已覆盖）

---

## 用户确认

- [ ] 用户已确认 Story 拆分方案（主干 Story 清单 + 异常分支补充）
- [ ] 用户已确认优先级和 Story Points 建议
- [ ] 用户已确认 GWT 验收标准
- [ ] 用户已确认溯源矩阵覆盖度
- [ ] 用户看到并确认的是完整 Story 落盘预览，不是摘要草稿

---

## 记忆更新

- [ ] `refs.json` 已注册所有新文档节点（story-*/matrix-*）和引用边（Story implements Feature、Matrix references Feature）
- [ ] `facts.json` 已记录已确认事实（角色、规则、流程步骤）
- [ ] `decision-log.md` 已记录拆分决策（拆分方案、颗粒度调整、优先级排序及理由）
- [ ] `tracking-log.md` 已记录新发现的风险/假设/未决问题（依赖关系、待验证项）
- [ ] `phase-summary.md` 已追加本阶段摘要（产物清单、关键拆分决策、遗留问题）
- [ ] `progress.json` 已更新当前阶段和顶层 `lastUpdated`；`workflow.state` 和阶段状态由主调度器在校验通过后更新
