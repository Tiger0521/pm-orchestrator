---
id: "{{FEATURE_ID}}"
type: "feature"
projectId: "{{PROJECT_ID}}"
title: "{{HUMAN_READABLE_TITLE}}"
status: "draft"
refs:
  - id: "{{EPIC_ID}}"
    relation: "belongs-to"
  - id: "{{REQUIREMENT_ID}}"
    relation: "references"
---

# {{HUMAN_READABLE_TITLE}}

## 需求背景

本 Feature 回应 [@{{REQUIREMENT_ID}}] 中的需求：{{REQUIREMENT_BACKGROUND}}

## 能力名称

{{CAPABILITY_NAME}}

## 能力描述

{{CAPABILITY_DESCRIPTION}}

## 能力目标

{{CAPABILITY_GOAL}}

## 用户任务

作为 {{USER_ROLE}}，我希望在 {{USER_CONTEXT}} 时，能够 {{USER_JOB}}，以便 {{USER_VALUE}}。

## 用户角色

引用 [@{{EPIC_ID}}] 中的角色：{{USER_ROLES}}

## 业务场景

1. {{BUSINESS_SCENARIO_1}}
2. {{BUSINESS_SCENARIO_2}}
3. {{BUSINESS_SCENARIO_3}}

## 业务价值

{{BUSINESS_VALUE}}

## 使用前后对比

| 对比项 | 当前方式 | 目标方式 | 改善结果 |
| --- | --- | --- | --- |
| {{COMPARE_ITEM_1}} | {{BEFORE_1}} | {{AFTER_1}} | {{IMPROVEMENT_1}} |
| {{COMPARE_ITEM_2}} | {{BEFORE_2}} | {{AFTER_2}} | {{IMPROVEMENT_2}} |

## 业务流程

```text
{{STEP_1}} → {{STEP_2}} → {{STEP_3}} → {{STEP_4}} → {{STEP_5}}
```

| 步骤 | 触发条件 | 操作角色 | 系统行为 | 输出结果 |
| --- | --- | --- | --- | --- |
| {{STEP_NAME_1}} | {{TRIGGER_1}} | {{OPERATOR_1}} | {{SYSTEM_BEHAVIOR_1}} | {{STEP_OUTPUT_1}} |
| {{STEP_NAME_2}} | {{TRIGGER_2}} | {{OPERATOR_2}} | {{SYSTEM_BEHAVIOR_2}} | {{STEP_OUTPUT_2}} |
| {{STEP_NAME_3}} | {{TRIGGER_3}} | {{OPERATOR_3}} | {{SYSTEM_BEHAVIOR_3}} | {{STEP_OUTPUT_3}} |

## 输入输出数据

| 数据 | 来源/去向 | 用途 | 质量要求 |
| --- | --- | --- | --- |
| {{DATA_1}} | {{DATA_SOURCE_1}} | {{DATA_USAGE_1}} | {{DATA_QUALITY_1}} |
| {{DATA_2}} | {{DATA_SOURCE_2}} | {{DATA_USAGE_2}} | {{DATA_QUALITY_2}} |

## 业务规则

| 规则项 | 规则说明 |
| --- | --- |
| {{RULE_1}} | {{RULE_DESC_1}} |
| {{RULE_2}} | {{RULE_DESC_2}} |

## 异常分支

| 异常情况 | 系统处理 | 用户提示/补救动作 |
| --- | --- | --- |
| {{EXCEPTION_1}} | {{EXCEPTION_HANDLING_1}} | {{RECOVERY_ACTION_1}} |
| {{EXCEPTION_2}} | {{EXCEPTION_HANDLING_2}} | {{RECOVERY_ACTION_2}} |

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

1. Given {{GIVEN_1}}, When {{WHEN_1}}, Then {{THEN_1}}
2. Given {{GIVEN_2}}, When {{WHEN_2}}, Then {{THEN_2}}
3. Given {{GIVEN_3}}, When {{WHEN_3}}, Then {{THEN_3}}
