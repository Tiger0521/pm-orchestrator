---
id: "matrix-001"
type: "traceability-matrix"
projectId: "{{PROJECT_ID}}"
title: "Story-Feature 溯源矩阵"
status: "draft"
refs:
  - id: "feature-001"
    relation: "references"
---

# Story-Feature 溯源矩阵

## Feature 列表

| ID | Feature 名称 | 优先级 | 状态 |
|----|-------------|--------|------|
| feature-001 | {{FEATURE_1_NAME}} | {{PRIORITY_1}} | {{STATUS_1}} |
| feature-002 | {{FEATURE_2_NAME}} | {{PRIORITY_2}} | {{STATUS_2}} |

## Story 列表

| ID | Story 标题 | 角色 | 优先级 | Story Points |
|----|-----------|------|--------|-------------|
| story-001 | {{STORY_1_TITLE}} | {{ROLE_1}} | {{PRIORITY_1}} | {{SP_1}} |
| story-002 | {{STORY_2_TITLE}} | {{ROLE_2}} | {{PRIORITY_2}} | {{SP_2}} |

## 映射关系

| Story ID | 实现 Feature ID | 覆盖度 |
|----------|----------------|--------|
| story-001 | feature-001 | 完整 |
| story-002 | feature-001 | 完整 |

## 覆盖度检查

- [ ] feature-001 至少有一条 Story 实现
- [ ] feature-002 至少有一条 Story 实现
- [ ] 所有高优先级 Feature 已覆盖
