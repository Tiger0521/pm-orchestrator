---
id: "{{REQ_ID}}"
type: "requirement-card"
projectId: "{{PROJECT_ID}}"
title: "{{TITLE}}"
status: "draft"
refs: []
---

# {{TITLE}}

```
需求卡片 ──────────────→ Epic ──────────────→ Feature
  ▲                        │                     │
  │ 5 个字段                │ 9 个字段             │ 12 个字段
  │                        │                     │
  ├ 需求基本信息             ├ 产品名称             ├ 能力名称
  ├ 现状描述                ├ 产品定位             ├ 能力描述
  ├ 痛点                   ├ 产品目标             ├ 能力目标
  ├ 问题本质还原             ├ 用户角色             ├ 业务价值
  └ 需求评估结果             ├ 核心场景             ├ 业务场景
                           ├ 产品价值             ├ 业务流程
                           ├ 范围边界             ├ 业务规则
                           └ 建设思路             ├ 技术可行性
                                                  ├ 资源投入
                                                  └ 优先级
```

## 需求基本信息

| 字段 | 内容 |
| --- | --- |
| 需求来源 | {{REQUIREMENT_SOURCE}} |
| 提出人/角色 | {{REQUESTER}} |
| 触发时间/时机 | {{TRIGGER_TIME}} |
| 影响范围 | {{AFFECTED_SCOPE}} |
| 当前状态 | {{CURRENT_STATUS}} |

## 现状描述

{{CURRENT_STATE}}

## 痛点

{{PAIN_POINTS}}

## 问题本质还原

{{ROOT_PROBLEM}}

## 需求评估结果

| 维度 | 评分/结论 | 理由 |
| --- | --- | --- |
| 业务价值 | {{BUSINESS_VALUE_SCORE}} | {{BUSINESS_VALUE_REASON}} |
| 影响 | {{IMPACT_SCORE}} | {{IMPACT_REASON}} |
| 可行性 | {{FEASIBILITY_SCORE}} | {{FEASIBILITY_REASON}} |
| 资源 | {{RESOURCE_SCORE}} | {{RESOURCE_REASON}} |