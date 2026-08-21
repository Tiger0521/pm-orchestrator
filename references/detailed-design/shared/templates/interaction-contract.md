---
id: "{{CONTRACT_ID}}"
type: "interaction-contract"
projectId: "{{PROJECT_ID}}"
title: "交互契约"
status: "draft"
refs:
  - id: "{{PROTOTYPE_ID}}"
    relation: "references"
  - id: "{{STORY_ID}}"
    relation: "implements"
---

# 交互契约

## 状态机

```
[初始] -- 用户进入 --> [编辑中]
[编辑中] -- 提交成功 --> [成功]
[编辑中] -- 校验失败 --> [错误]
[错误] -- 用户修正 --> [编辑中]
```

## 交互规则表

| 触发动作 | 校验判断依据（前/后端） | 状态流转与反馈 | 异常兜底处理（GWT） |
|------|------|------|------|
| 点击提交 | 前端正则 + 后端唯一性校验 | 进入提交中 -> 成功 | Given [用户已填写表单] When [点击提交] Then [校验失败提示具体错误] |
| 网络超时 | 请求失败 | 停留在编辑中 | Given [用户已提交请求] When [请求超时] Then [保留表单内容并提示"网络异常，请重试"] |

## 错误提示

| 错误场景 | 提示文案 |
|----------|---------|
| {{ERROR_1}} | {{MESSAGE_1}} |
| {{ERROR_2}} | {{MESSAGE_2}} |

## API 约定（如有）

| 接口 | 方法 | 入参 | 出参 |
|------|------|------|------|
| {{API_1}} | POST | {{PARAM_1}} | {{RESPONSE_1}} |
