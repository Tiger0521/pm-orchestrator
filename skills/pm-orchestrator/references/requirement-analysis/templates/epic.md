---
id: "epic-001"
type: "epic"
projectId: "{{PROJECT_ID}}"
title: "{{HUMAN_READABLE_TITLE}}"
status: "draft"
refs:
  - id: "req-001"
    relation: "derived-from"
---

# {{HUMAN_READABLE_TITLE}}

## 需求背景

本 Epic 派生自 [@req-001]：{{REQUIREMENT_BACKGROUND}}

## 产品名称

{{PRODUCT_NAME}}

## 产品定位

{{ONE_SENTENCE_POSITIONING}}

## 产品目标

{{PRODUCT_GOAL}}

## 端到端业务闭环

```text
{{LOOP_STEP_1}} → {{LOOP_STEP_2}} → {{LOOP_STEP_3}} → {{LOOP_STEP_4}} → {{LOOP_STEP_5}}
```

| 环节 | 责任角色 | 关键动作 | 产出/数据 | 当前问题 | 系统要改善的结果 |
| --- | --- | --- | --- | --- | --- |
| {{LOOP_NODE_1}} | {{OWNER_1}} | {{ACTION_1}} | {{OUTPUT_1}} | {{CURRENT_ISSUE_1}} | {{TARGET_RESULT_1}} |
| {{LOOP_NODE_2}} | {{OWNER_2}} | {{ACTION_2}} | {{OUTPUT_2}} | {{CURRENT_ISSUE_2}} | {{TARGET_RESULT_2}} |

## 产品闭环

- **同时解决的问题**：{{PROBLEMS_SOLVED_TOGETHER}}
- **共同用户/流程/数据对象/管理目标**：{{COMMON_LOOP_BASIS}}
- **关键依赖**：{{KEY_DEPENDENCIES}}
- **版本组织**：{{VERSION_ORGANIZATION}}

## 战略价值

{{STRATEGIC_VALUE}}

## 为什么现在做

{{WHY_NOW}}

## 目标用户 / 角色

| 角色 | 描述 | 核心诉求 |
| --- | --- | --- |
| {{ROLE_1}} | {{ROLE_DESC_1}} | {{ROLE_NEED_1}} |
| {{ROLE_2}} | {{ROLE_DESC_2}} | {{ROLE_NEED_2}} |

## 核心场景

### 场景一：{{SCENARIO_1_TITLE}}

{{SCENARIO_1_DESCRIPTION}}

### 场景二：{{SCENARIO_2_TITLE}}

{{SCENARIO_2_DESCRIPTION}}

## 边界

### 范围内

- {{IN_SCOPE_1}}
- {{IN_SCOPE_2}}

### 范围外（不做）

- {{OUT_OF_SCOPE_1}}
- {{OUT_OF_SCOPE_2}}

## 建设思路

| 阶段 | 建设内容 | 验证目标 |
| --- | --- | --- |
| 一期 | {{PHASE_1_SCOPE}} | {{PHASE_1_GOAL}} |
| 二期 | {{PHASE_2_SCOPE}} | {{PHASE_2_GOAL}} |
| 三期 | {{PHASE_3_SCOPE}} | {{PHASE_3_GOAL}} |

## 成功指标

1. {{SUCCESS_METRIC_1}}
2. {{SUCCESS_METRIC_2}}
3. {{SUCCESS_METRIC_3}}

## 主要风险与依赖

| 风险/依赖 | 影响 | 应对或验证方式 |
| --- | --- | --- |
| {{RISK_1}} | {{RISK_IMPACT_1}} | {{RISK_RESPONSE_1}} |
| {{RISK_2}} | {{RISK_IMPACT_2}} | {{RISK_RESPONSE_2}} |
