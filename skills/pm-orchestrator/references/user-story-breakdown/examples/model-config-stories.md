# 示例：模型配置管理 Story 拆分

本示例展示需求拆解阶段的完整产出质量标杆。包含两条 Story（创建模型配置 + 查看模型配置列表）和一份溯源矩阵，每条 Story 含完整的 GWT 验收标准，均采用加粗关键词领条格式。

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

作为 **算法工程师**，我想要 **创建新的模型配置**，以便于 **快速启用模型进行实验，无需手动编辑配置文件**。

### 优先级

P0

### Story Points 建议

3（建议值，待团队确认）

### 验收标准

1. **成功创建**：Given 算法工程师已登录系统，When 填写模型名称、版本、参数并点击提交，Then 系统创建配置并返回成功提示"创建成功"
2. **必填项校验**：Given 算法工程师未填写模型名称，When 点击提交按钮，Then 系统提示"模型名称不能为空"并阻止提交
3. **重复名称**：Given 已存在名称为"v1"的配置，When 再次创建名称为"v1"的配置并提交，Then 系统提示"配置名称已存在"并阻止提交
4. **权限不足**：Given 普通用户（非算法工程师）已登录，When 尝试访问配置创建页面，Then 系统提示"无操作权限"并隐藏创建入口
5. **参数超限**：Given 算法工程师在参数字段输入超过 500 字符的内容，When 点击提交，Then 系统提示"参数长度不能超过 500 字符"并阻止提交

### 关联 Feature

本 Story 实现 [[feature-001]]。

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

作为 **算法工程师**，我想要 **查看所有模型配置列表**，以便于 **快速定位需要修改的配置版本，减少人工翻页时间**。

### 优先级

P0

### Story Points 建议

2（建议值，待团队确认）

### 验收标准

1. **列表展示**：Given 系统存在多条模型配置，When 算法工程师进入配置列表页，Then 系统按创建时间倒序展示配置名称、版本、状态和操作按钮
2. **空列表**：Given 系统不存在任何模型配置，When 算法工程师进入配置列表页，Then 系统展示空状态提示"暂无配置，点击创建第一条"
3. **权限不足**：Given 普通用户（非算法工程师）已登录，When 尝试访问配置列表页，Then 系统提示"无访问权限"并跳转到首页
4. **分页加载**：Given 系统存在超过 20 条配置，When 算法工程师滚动到列表底部，Then 系统自动加载下一页 20 条配置并展示加载状态

### 关联 Feature

本 Story 实现 [[feature-001]]。

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
- [x] 所有高优先级（P0）Feature 已覆盖
