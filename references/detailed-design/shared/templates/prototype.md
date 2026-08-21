---
id: "{{PROTOTYPE_ID}}"
type: "prototype"
projectId: "{{PROJECT_ID}}"
title: "原型文档"
status: "draft"
refs:
  - id: "{{FLOW_ID}}"
    relation: "references"
  - id: "{{STORY_ID}}"
    relation: "implements"
---

# 原型文档

## 原型生成方式

{{PROTOTYPE_METHOD}}

> 取值：交互式 HTML（含标注层）

## 页面列表

1. {{PAGE_1}}
2. {{PAGE_2}}

## 页面一：{{PAGE_1_TITLE}}

### 布局

> 此处填 HTML 文件路径 + 标注层开关说明（如"文件：`详细设计/原型/<简称>-原型.html`，URL 加 `?ann=1` 开启标注态"），不画 ASCII 示意

```
+----------------------------------+
|  标题栏                          |
+----------------------------------+
|  筛选区  |  操作按钮             |
+----------------------------------+
|                                  |
|  内容列表                         |
|                                  |
+----------------------------------+
|  分页 / 加载更多                  |
+----------------------------------+
```

### 元素说明

| 元素 | 类型 | 交互 | 反馈 | 备注 |
|------|------|------|------|------|
| {{ELEMENT_1}} | 按钮 | 点击跳转 | {{FEEDBACK_1}} | 主操作 |
| {{ELEMENT_2}} | 输入框 | 实时搜索 | {{FEEDBACK_2}} | 防抖 300ms |

### 异常状态

- **空状态**：{{EMPTY_STATE_COPY}}
- **加载中**：{{LOADING_STATE_COPY}}
- **错误状态**：{{ERROR_STATE_COPY}}

## 页面二：{{PAGE_2_TITLE}}

### 布局

```
+----------------------------------+
|  标题栏                          |
+----------------------------------+
|                                  |
|  内容区域                         |
|                                  |
+----------------------------------+
```

### 元素说明

| 元素 | 类型 | 交互 | 反馈 | 备注 |
|------|------|------|------|------|
| {{ELEMENT_3}} | 按钮 | 点击提交 | {{FEEDBACK_3}} | 主操作 |

### 异常状态

- **空状态**：{{EMPTY_STATE_COPY_2}}
- **加载中**：{{LOADING_STATE_COPY_2}}
- **错误状态**：{{ERROR_STATE_COPY_2}}

## 组件复用

| 组件名 | 使用页面 |
|--------|---------|
| {{COMPONENT_1}} | {{PAGE_1}}、{{PAGE_2}} |
| {{COMPONENT_2}} | {{PAGE_1}} |

## UI 规范引用

{{UI_SPEC_REF}}

> 如已有设计系统，引用对应规范编号（如 `引用 Ant Design Table 组件`）；如无已有设计系统，标注"无已有设计系统，原型中使用的组件样式为建议值，待 UI 设计师确认"

## 设计决策记录

> 核心页面的方案对比和推荐理由（借鉴 office-hours 结构：问题陈述 -> 方案对比 -> 推荐方案 -> 成功标准）

### 页面：{{CORE_PAGE_1}}

**问题陈述**：{{PROBLEM_STATEMENT_1}}

**方案 A：{{APPROACH_A_1}}**
- 优点：{{APPROACH_A_PROS_1}}
- 缺点：{{APPROACH_A_CONS_1}}

**方案 B：{{APPROACH_B_1}}**
- 优点：{{APPROACH_B_PROS_1}}
- 缺点：{{APPROACH_B_CONS_1}}

**推荐**：方案 {{RECOMMENDED_APPROACH_1}}，理由：{{RECOMMENDED_REASON_1}}

**成功标准**：{{SUCCESS_CRITERIA_1}}
