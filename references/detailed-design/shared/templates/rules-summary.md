---
id: "{{RULES_ID}}"
type: "rules-summary"
projectId: "{{PROJECT_ID}}"
title: "规则摘要"
status: "draft"
refs:
  - id: "{{CONTRACT_ID}}"
    relation: "references"
  - id: "{{FEATURE_ID}}"
    relation: "references"
---

# 规则摘要

## 全局规则

1. {{GLOBAL_RULE_1}}
2. {{GLOBAL_RULE_2}}

## 业务规则

| 规则编号 | 定义与约束摘要 | 影响范围/研发关注点 |
|----------|---------|---------|
| BR-{{BR_NUM_1}} | {{RULE_1}} | {{IMPACT_SCOPE_1}} |
| BR-{{BR_NUM_2}} | {{RULE_2}} | {{IMPACT_SCOPE_2}} |

## 数据字典

| 规则编号 | 定义与约束摘要 | 影响范围 |
|----------|---------|---------|
| DD-{{DD_NUM_1}} | {{DD_RULE_1}} | {{DD_SCOPE_1}} |
| DD-{{DD_NUM_2}} | {{DD_RULE_2}} | {{DD_SCOPE_2}} |

## 权限控制

| 权限编号 | 定义与约束摘要 | 影响范围 |
|----------|---------|---------|
| NFR-Auth-{{AUTH_NUM_1}} | {{AUTH_RULE_1}} | {{AUTH_SCOPE_1}} |
| NFR-Auth-{{AUTH_NUM_2}} | {{AUTH_RULE_2}} | {{AUTH_SCOPE_2}} |

## 安全审计

| 编号 | 定义与约束摘要 | 影响范围 |
|----------|---------|---------|
| NFR-Sec-{{SEC_NUM_1}} | {{SEC_RULE_1}} | {{SEC_SCOPE_1}} |
| NFR-Sec-{{SEC_NUM_2}} | {{SEC_RULE_2}} | {{SEC_SCOPE_2}} |

## 异常兜底规则

| 异常场景 | 兜底策略 | 提示文案 |
|----------|---------|---------|
| {{EXCEPTION_1}} | {{FALLBACK_1}} | {{MESSAGE_1}} |
| {{EXCEPTION_2}} | {{FALLBACK_2}} | {{MESSAGE_2}} |
