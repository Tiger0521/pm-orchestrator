---
id: "feature-001"
type: "feature"
projectId: "{{PROJECT_ID}}"
title: "{{TITLE}}"
status: "draft"
refs:
  - id: "epic-001"
    relation: "belongs-to"
  - id: "req-001"
    relation: "references"
---

# {{TITLE}}

## 需求背景

本 Feature 回应 [@req-001] 中的需求：{{REQUIREMENT_BACKGROUND}}

## 能力名称

{{CAPABILITY_NAME}}

## 能力描述

{{CAPABILITY_DESCRIPTION}}

## 能力目标

{{CAPABILITY_GOAL}}

## 用户角色

引用 [@epic-001] 中的角色：{{USER_ROLES}}

## 业务场景

1. {{BUSINESS_SCENARIO_1}}
2. {{BUSINESS_SCENARIO_2}}
3. {{BUSINESS_SCENARIO_3}}

## 业务价值

{{BUSINESS_VALUE}}

## 业务流程

```text
{{STEP_1}} → {{STEP_2}} → {{STEP_3}} → {{STEP_4}}
```

## 业务规则

| 规则项 | 规则说明 |
| --- | --- |
| {{RULE_1}} | {{RULE_DESC_1}} |
| {{RULE_2}} | {{RULE_DESC_2}} |

## 技术可行性

{{TECH_FEASIBILITY}}

## 资源投入

{{RESOURCE_INVESTMENT}}

## 优先级

{{PRIORITY}}（P0/P1/P2）

## 依赖

- {{DEPENDENCY_1}}
- {{DEPENDENCY_2}}

## 验收标准

1. {{ACCEPTANCE_CRITERIA_1}}
2. {{ACCEPTANCE_CRITERIA_2}}
3. {{ACCEPTANCE_CRITERIA_3}}
