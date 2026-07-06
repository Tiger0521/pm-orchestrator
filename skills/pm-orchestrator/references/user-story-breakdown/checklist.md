# 需求拆解阶段质量门

阶段完成并推进到「详细设计」前，必须逐条通过以下校验。

---

## 文件存在性

- [ ] 至少一个 `docs/design/story-*.md` 存在
- [ ] `docs/design/matrix-001.md` 存在

---

## Frontmatter 完整性

每份文档必须包含：

- [ ] `id`
- [ ] `type`
- [ ] `projectId`
- [ ] `title`
- [ ] `status`
- [ ] `refs`（至少一条引用关系）

---

## User Story 质量

- [ ] 每条 Story 采用三段式格式
- [ ] 每条 Story 有明确角色
- [ ] 每条 Story 有明确用户价值
- [ ] 每条 Story 满足 INVEST 原则
- [ ] 每条 Story 工作量在一个 Sprint 内可完成

---

## 验收标准质量

- [ ] 每条 Story 有 3-8 条 GWT 验收标准
- [ ] 验收标准覆盖正常路径
- [ ] 验收标准覆盖异常路径（权限、数据、网络、并发等）
- [ ] GWT 格式规范（Given/When/Then 齐全）

---

## 覆盖度

- [ ] 每个 Feature 至少被一条 Story 实现
- [ ] 关键业务规则在 Story 中体现
- [ ] 异常场景有对应 Story 或 AC

---

## 溯源矩阵

- [ ] 矩阵包含所有 Feature 和 Story
- [ ] 每条 Story 与 Feature 的映射关系清晰
- [ ] 矩阵显示覆盖度（已实现/未实现）

---

## 用户确认

- [ ] 用户已确认 Story 拆分方案
- [ ] 用户已确认优先级和 Story Points 建议
- [ ] 用户已确认 GWT 验收标准

---

## 记忆更新

- [ ] `refs.json` 已注册所有新文档节点和引用边
- [ ] `facts.json` 已记录已确认事实
- [ ] `decision-log.md` 已记录拆分决策
- [ ] `tracking-log.md` 已记录新发现的风险/假设/未决问题
- [ ] `phase-summary.md` 已追加本阶段摘要
- [ ] `progress.json` 已更新文档列表和阶段内进度（注：`currentPhase` 由主调度器在校验通过后更新）
