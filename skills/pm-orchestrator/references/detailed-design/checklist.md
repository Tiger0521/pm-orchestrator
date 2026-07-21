# 详细设计阶段质量门

阶段完成并标记为「完成」前，必须逐条通过以下校验。

---

## 文件存在性

- [ ] 至少一个 `docs/design/flow-*.md` 存在
- [ ] 至少一个 `docs/design/proto-*.md` 存在
- [ ] 至少一个 `docs/design/contract-*.md` 存在
- [ ] 至少一个 `docs/execution/rules-*.md` 存在
- [ ] 至少一个 `docs/execution/sprint-*.md` 存在

---

## Frontmatter 完整性

每份文档必须包含：id、type、projectId、title、status、refs。

---

## 结构与流程

- [ ] 页面映射表清晰，每个 Story 归属到页面
- [ ] 系统边界已定义
- [ ] 主业务流程图完整

---

## 原型质量

- [ ] 核心页面原型已覆盖
- [ ] 每个页面包含布局说明
- [ ] 关键交互元素有明确说明
- [ ] 异常状态有展示
- [ ] 组件复用已标注

---

## 交互契约质量

- [ ] 核心流程有状态机描述
- [ ] 交互规则表包含触发、校验、流转、兜底
- [ ] 错误提示文案已定义
- [ ] 关键 API 调用有约定

---

## 规则摘要

- [ ] 全局规则已汇总
- [ ] 业务规则已汇总
- [ ] 异常兜底规则已汇总
- [ ] 规则与 Story/Feature 无冲突

---

## Sprint 规划

- [ ] Sprint 目标明确
- [ ] 每个 Sprint 包含的 Story 已列出
- [ ] Story 优先级和依赖已标注
- [ ] 高风险 Story 已标注
- [ ] 总工作量未超过团队可用产能

---

## 用户确认

- [ ] 用户已确认页面结构和流程
- [ ] 用户已确认原型方案
- [ ] 用户已确认交互契约
- [ ] 用户已确认 Sprint 分解方案

---

## 记忆更新

- [ ] `refs.json` 已注册所有新文档节点和引用边
- [ ] `facts.json` 已记录已确认事实
- [ ] `decision-log.md` 已记录设计决策
- [ ] `tracking-log.md` 已记录新发现的风险/假设/未决问题
- [ ] `phase-summary.md` 已追加本阶段摘要
- [ ] `progress.json` 已更新当前阶段和顶层 `lastUpdated`（注：主调度器在校验通过后设置顶层 `status=completed`、`workflow.state=completed`，并完成阶段状态与时间戳）
