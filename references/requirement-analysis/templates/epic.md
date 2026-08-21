---
id: "{{EPIC_ID}}"
type: "epic"
projectId: "{{PROJECT_ID}}"
title: "{{TITLE}}"
status: "draft"
refs:
  - id: "{{REQ_ID}}"
    relation: "derived-from"
---

# {{TITLE}}

```
需求卡片 ──────────────→ Epic ──────────────→ Feature
  │                        ▲                     │
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

本 Epic 派生自 [[{{REQ_ID}}]]：{{REQUIREMENT_BG}}

## 产品名称

{{PRODUCT_NAME}}

## 产品定位

{{POSITIONING}}

## 产品目标

{{PRODUCT_GOALS}}

## 用户角色

{{USER_ROLES}}

## 核心场景

{{CORE_SCENARIOS}}

## 产品价值

{{PRODUCT_VALUE}}

## 产品范围与边界

### 范围内

{{IN_SCOPE}}

### 范围外

{{OUT_OF_SCOPE}}

## 建设思路

{{BUILD_APPROACH}}