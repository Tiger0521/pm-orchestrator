---
id: "story-001"
type: "user-story"
projectId: "{{PROJECT_ID}}"
title: "{{TITLE}}"
status: "draft"
refs:
  - id: "feature-001"
    relation: "implements"
---

# {{TITLE}}

## 用户故事

作为 **[{{ROLE}}]**，我想要 **[{{GOAL}}]**，以便于 **[{{VALUE}}]**。

## 优先级

{{PRIORITY}}（P0/P1/P2）

## Story Points 建议

{{STORY_POINTS}}（1/2/3/5/8/13）

## 验收标准

### AC1：正常路径

```
Given {{PRECONDITION_1}}
When {{ACTION_1}}
Then {{EXPECTED_RESULT_1}}
```

### AC2：异常路径

```
Given {{PRECONDITION_2}}
When {{ACTION_2}}
Then {{EXPECTED_RESULT_2}}
```

### AC3：边界场景

```
Given {{PRECONDITION_3}}
When {{ACTION_3}}
Then {{EXPECTED_RESULT_3}}
```

## 关联 Feature

本 Story 实现 [@feature-001]。
