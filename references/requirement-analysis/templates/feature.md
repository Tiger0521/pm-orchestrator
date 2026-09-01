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
  │ 5 个字段                │ 9 个字段             │ 5 个字段
  │                        │                     │
  ├ 需求基本信息             ├ 产品名称             ├ 需求背景
  ├ 现状描述                ├ 产品定位             ├ 能力名称
  ├ 痛点                   ├ 产品目标             ├ 能力描述
  ├ 问题本质还原             ├ 用户角色             ├ 能力目标
  └ 需求评估结果             ├ 核心场景             └ 用户角色
                           ├ 产品价值
                           ├ 范围边界
                           └ 建设思路
```

> 业务价值、业务场景、业务流程、业务规则由《业务文档》按扁平 4 字段承载；技术可行性、资源投入已删除；优先级唯一来源为需求台账条目优先级。

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

## 关联业务文档

本 Feature 的业务价值、业务场景、业务流程、业务规则见 [[{{PRODUCT_SHORT}}-业务文档]]（业务场景与业务规则表按「所属能力」列定位本能力）。