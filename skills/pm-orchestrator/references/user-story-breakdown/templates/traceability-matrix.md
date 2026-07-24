---
id: "{{MATRIX_ID}}"
type: "traceability-matrix"
projectId: "{{PROJECT_ID}}"
title: "Story-Feature 溯源矩阵"
status: "draft"
refs:
  - id: "{{FEATURE_ID}}"
    relation: "references"
---

# Story-Feature 溯源矩阵

## Feature 列表

| ID | Feature 名称 | 优先级 | 状态 |
|----|-------------|--------|------|
| {{FEATURE_1_ID}} | {{FEATURE_1_NAME}} | {{FEATURE_1_PRIORITY}} | {{FEATURE_1_STATUS}} |
| {{FEATURE_2_ID}} | {{FEATURE_2_NAME}} | {{FEATURE_2_PRIORITY}} | {{FEATURE_2_STATUS}} |

## Story 列表

| ID | Story 标题 | 角色 | 优先级 | Story Points |
|----|-----------|------|--------|-------------|
| {{STORY_1_ID}} | {{STORY_1_TITLE}} | {{STORY_1_ROLE}} | {{STORY_1_PRIORITY}} | {{STORY_1_SP}} |
| {{STORY_2_ID}} | {{STORY_2_TITLE}} | {{STORY_2_ROLE}} | {{STORY_2_PRIORITY}} | {{STORY_2_SP}} |

## 映射关系

| Story ID | 实现 Feature ID | 覆盖度 |
|----------|----------------|--------|
| {{STORY_1_ID}} | {{FEATURE_1_ID}} | 完整 |
| {{STORY_2_ID}} | {{FEATURE_1_ID}} | 完整 |

## 覆盖度检查

- [ ] {{FEATURE_1_ID}} 至少有一条 Story 实现
- [ ] {{FEATURE_2_ID}} 至少有一条 Story 实现
- [ ] 所有高优先级（P0）Feature 已覆盖
