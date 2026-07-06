# 示例：模型配置管理 Story 拆分

本示例展示需求拆解阶段的完整产出质量标杆。

---

## Story：story-001

---
id: "story-001"
type: "user-story"
projectId: "model-config"
title: "创建模型配置"
status: "approved"
refs:
  - id: "feature-001"
    relation: "implements"
---

### 用户故事

作为 **算法工程师**，我想要 **创建新的模型配置**，以便于 **快速启用模型进行实验**。

### 优先级

P0

### Story Points 建议

3

### 验收标准

#### AC1：成功创建配置

```
Given 算法工程师已登录系统
When 填写模型名称、版本、参数并提交
Then 系统创建配置并返回成功提示
```

#### AC2：必填项校验

```
Given 算法工程师提交空表单
When 点击提交按钮
Then 系统提示"模型名称不能为空"并阻止提交
```

#### AC3：重复名称校验

```
Given 已存在名称为"v1"的配置
When 再次创建名称为"v1"的配置
Then 系统提示"配置名称已存在"并阻止提交
```

---

## Story：story-002

---
id: "story-002"
type: "user-story"
projectId: "model-config"
title: "查看模型配置列表"
status: "approved"
refs:
  - id: "feature-001"
    relation: "implements"
---

### 用户故事

作为 **算法工程师**，我想要 **查看所有模型配置列表**，以便于 **管理和选择配置**。

### 优先级

P0

### Story Points 建议

2

### 验收标准

#### AC1：列表展示

```
Given 系统存在多条模型配置
When 算法工程师进入配置列表页
Then 系统按创建时间倒序展示配置名称、版本、状态和操作按钮
```

#### AC2：空数据展示

```
Given 系统不存在任何模型配置
When 算法工程师进入配置列表页
Then 系统展示空状态提示"暂无配置，点击创建"
```

---

## 溯源矩阵：matrix-001

---
id: "matrix-001"
type: "traceability-matrix"
projectId: "model-config"
title: "Story-Feature 溯源矩阵"
status: "approved"
refs:
  - id: "feature-001"
    relation: "references"
---

### Feature 列表

| ID | Feature 名称 | 优先级 | 状态 |
|----|-------------|--------|------|
| feature-001 | 模型配置管理 | P0 | approved |

### Story 列表

| ID | Story 标题 | 角色 | 优先级 | Story Points |
|----|-----------|------|--------|-------------|
| story-001 | 创建模型配置 | 算法工程师 | P0 | 3 |
| story-002 | 查看模型配置列表 | 算法工程师 | P0 | 2 |

### 映射关系

| Story ID | 实现 Feature ID | 覆盖度 |
|----------|----------------|--------|
| story-001 | feature-001 | 完整 |
| story-002 | feature-001 | 完整 |

### 覆盖度检查

- [x] feature-001 至少有一条 Story 实现
- [x] 所有高优先级 Feature 已覆盖
