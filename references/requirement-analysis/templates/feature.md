---
id: "{{FEATURE_ID}}"
type: "feature"
projectId: "{{PROJECT_ID}}"
title: "{{TITLE}}"
status: "draft"
refs:
  - id: "{{EPIC_ID}}"
    relation: "belongs-to"
  - id: "{{REQ_ID}}"
    relation: "references"
---

# {{TITLE}}

```
需求卡片 ──────────────→ Epic ──────────────→ Feature
  │                        │                     ▲
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

## 需求背景

本 Feature 回应 [[{{REQ_ID}}]] 中的需求：{{REQUIREMENT_BG}}

## 能力名称

{{CAPABILITY_NAME}}

## 能力描述

{{CAPABILITY_DESCRIPTION}}

## 能力目标

{{CAPABILITY_GOAL}}

## 用户角色

引用 [[{{EPIC_ID}}]] 中的角色：{{USER_ROLES}}

## 业务价值

{{BUSINESS_VALUE}}

## 业务场景

{{BUSINESS_SCENARIOS}}

## 业务流程

{{BUSINESS_PROCESS}}

## 业务规则

{{BUSINESS_RULES}}

## 技术可行性

{{TECH_FEASIBILITY}}

## 资源投入

{{RESOURCE_INVESTMENT}}

## 优先级

{{PRIORITY}}（排序依据：{{PRIORITY_REASON}}）