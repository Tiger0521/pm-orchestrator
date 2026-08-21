---
id: "{{SPRINT_ID}}"
type: "sprint"
projectId: "{{PROJECT_ID}}"
title: "Sprint 规划"
status: "draft"
refs:
  - id: "{{STORY_ID}}"
    relation: "contains"
---

# Sprint 规划

## 项目总览

- 团队产能：{{CAPACITY}} 人天 / Sprint
- Sprint 长度：{{SPRINT_LENGTH}} 周
- 总缓冲比例：15-20%

## Sprint 列表

### Sprint 1：{{SPRINT_1_GOAL}}

| Story | 优先级 | Story Points | 风险 | 依赖 |
|-------|--------|-------------|------|------|
| story-001 | P0 | 3 | 低 | 无 |
| story-002 | P0 | 2 | 中 | story-001 |

### Sprint 2：{{SPRINT_2_GOAL}}

| Story | 优先级 | Story Points | 风险 | 依赖 |
|-------|--------|-------------|------|------|
| story-003 | P1 | 5 | 高 | story-002 |

## 风险标注

- {{RISK_1}}：影响 story-003，需提前确认依赖
- {{RISK_2}}：story-005 涉及外部接口，建议 mock 先行

## 关键依赖

- {{DEPENDENCY_1}}
- {{DEPENDENCY_2}}
