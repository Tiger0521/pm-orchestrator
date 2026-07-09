---
id: "{{FLOW_ID}}"
type: "structure-flow"
projectId: "{{PROJECT_ID}}"
title: "结构与流程图"
status: "draft"
refs:
  - id: "{{STORY_ID}}"
    relation: "references"
---

# 结构与流程图

## 系统边界

{{SYSTEM_BOUNDARY}}

## 页面映射表

| 页面 | 包含 Story | 入口 | 出口 |
|------|-----------|------|------|
| {{PAGE_1}} | story-001, story-002 | {{ENTRY_1}} | {{EXIT_1}} |
| {{PAGE_2}} | story-003 | {{ENTRY_2}} | {{EXIT_2}} |

## 业务流程图

```mermaid
flowchart TD
    A[用户进入] --> B[页面1]
    B --> C{条件判断}
    C -->|分支1| D[页面2]
    C -->|分支2| E[错误提示]
    D --> F[完成]
```
