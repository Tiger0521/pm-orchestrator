---
id: "sprint-001"
type: "sprint"
projectId: "{{PROJECT_ID}}"
title: "Sprint 规划"
status: "draft"
refs:
  - id: "story-001"
    relation: "contains"
---

# Sprint 规划

## 项目总览

- 团队产能：{{CAPACITY}} 人天 / Sprint
- Sprint 长度：{{SPRINT_LENGTH}} 周
- 总缓冲：{{BUFFER}}%

## Sprint 列表

### Sprint 1：{{SPRINT_1_GOAL}}

| Story | 优先级 | Story Points | 风险 |
|-------|--------|-------------|------|
| story-001 | P0 | 3 | 低 |
| story-002 | P0 | 2 | 中 |

### Sprint 2：{{SPRINT_2_GOAL}}

| Story | 优先级 | Story Points | 风险 |
|-------|--------|-------------|------|
| story-003 | P1 | 5 | 高 |

## 风险标注

- {{RISK_1}}：影响 story-003，需提前确认依赖
- {{RISK_2}}：story-005 涉及外部接口，建议 mock 先行

## 关键依赖

- {{DEPENDENCY_1}}
- {{DEPENDENCY_2}}
