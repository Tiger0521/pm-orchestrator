---
id: "{{PRODUCT_SHORT}}-BIZ-DOC"
product: "{{PRODUCT_FULL_NAME}}"
type: "业务文档"
lastUpdated: "{{DATE}}"
aliases:
  - {{PRODUCT_SHORT}}业务文档
  - 业务说明
tags:
  - 业务文档
  - 持续更新
---

# {{PRODUCT_NAME}} 业务文档

## 业务价值

{{VALUE_DESC}}（价值类型：效率/营收/体验/合规）

不做会损失什么：{{LOSS_DESC}}

## 业务场景

（用户旅程提取的唯一输入，见用户故事阶段旅程提取指南；按「所属能力」列分组推导能力内旅程节点）

| 场景编号 | 场景名称 | 所属能力 | 参与角色 | 触发条件 | 用户目标 |
|---------|---------|---------|---------|---------|---------|
| SC-01 | {{SCENARIO_NAME}} | {{CAPABILITY_NAME}} | {{ROLES}} | {{TRIGGER}} | {{USER_GOAL}} |

## 业务流程

（产品级多条主线流程；流程编号按 FL-01、FL-02 递增，不按能力重排）

### 流程一：{{FLOW_NAME}}

{{FLOW_DESC}}（流程描述/图 + 关键步骤）

异常兜底：

- {{EXCEPTION_FALLBACK}}

## 业务规则

（业务规则是 story-map 阶段 GWT 生成与边界异常映射的输入；每行标注所属能力）

| 规则编号 | 规则说明 | 所属能力 | 适用范围 | 异常处理 |
|----------|---------|---------|---------|---------|
| BR-01 | {{RULE_DESC}} | {{CAPABILITY_NAME}} | {{APPLY_SCOPE}} | {{EXCEPTION}} |

## 变更记录

| 日期 | 变更内容 | 变更人 |
|------|---------|--------|
| {{DATE}} | {{CHANGE}} | {{AUTHOR}} |