# 诊断报告模板

> 诊断报告只用于诊断阶段，不是正式需求卡片、Epic 或 Feature。用户确认本报告后，才能进入正式文档草稿产出。

## 问题本质还原

{{PROBLEM_REFRAME}}

## 需求转化记录

| 用户原始表述 | 识别的问题 | 转化后的需求 | 转化依据 |
| --- | --- | --- | --- |
| {{RAW_STATEMENT}} | {{IDENTIFIED_ISSUE}} | {{CONVERTED_NEED}} | {{CONVERSION_BASIS}} |

## 目标用户画像

- **核心用户**：{{CORE_USER}}
- **典型场景**：{{TYPICAL_SCENARIO}}
- **痛点强度**：{{PAIN_INTENSITY}}
- **切换阈值**：{{SWITCH_THRESHOLD}}

## 关键假设

1. {{ASSUMPTION_1}}
2. {{ASSUMPTION_2}}
3. {{ASSUMPTION_3}}

## 待验证事项

| 事项 | 验证方式 | 负责人/来源 | 阻塞程度 |
| --- | --- | --- | --- |
| {{VALIDATION_ITEM_1}} | {{VALIDATION_METHOD_1}} | {{OWNER_OR_SOURCE_1}} | {{BLOCK_LEVEL_1}} |
| {{VALIDATION_ITEM_2}} | {{VALIDATION_METHOD_2}} | {{OWNER_OR_SOURCE_2}} | {{BLOCK_LEVEL_2}} |

## 数据校验异常

| 数据项 | 来源 | 异常类型 | 处理方式 |
| --- | --- | --- | --- |
| {{DATA_ITEM}} | {{DATA_SOURCE}} | {{VALIDATION_ERROR}} | {{HANDLING}} |

## 项目类型判断

- **projectType**：{{PROJECT_TYPE}}
- **判断依据**：{{PROJECT_TYPE_REASON}}
- **七问路由**：{{QUESTION_ROUTE}}

## 需求成熟度评分

- **分数**：{{MATURITY_SCORE}}/10
- **评分依据**：{{MATURITY_REASON}}
- **低分补救计划**：{{RESEARCH_PLAN_IF_LOW_SCORE}}

## 诊断结论

{{DIAGNOSTIC_CONCLUSION}}
