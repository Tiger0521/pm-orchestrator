<!--
  User Story 文档模板
  占位符 {{JOURNEY_STAGE}} 对应 Story JSON 顶层字段 journey_stage；
  占位符 {{REQ_ENTRY_ID}} 对应 requirementEntryId，且必须与 refs 的 addresses 值、正文文件链接一致。
-->

---
id: "{{STORY_ID}}"
type: "user-story"
projectId: "{{PROJECT_ID}}"
title: "{{TITLE}}"
status: "draft"
journey_stage: "{{JOURNEY_STAGE}}"
refs:
  - id: "{{FEATURE_ID}}"
    relation: "implements"
  - id: "{{REQ_ENTRY_ID}}"
    relation: "addresses"
---

# {{TITLE}}

## 用户故事

作为 **{{ROLE}}**，我想要 **{{GOAL}}**，以便于 **{{VALUE}}**。

## 优先级

{{PRIORITY}}

## Story Points 建议

{{STORY_POINTS}}（建议值，待团队确认）

## 旅程阶段

{{JOURNEY_STAGE}}

## 验收标准

1. **{{AC_1_KEYWORD}}**：Given {{AC_1_GIVEN}}，When {{AC_1_WHEN}}，Then {{AC_1_THEN}}
2. **{{AC_2_KEYWORD}}**：Given {{AC_2_GIVEN}}，When {{AC_2_WHEN}}，Then {{AC_2_THEN}}
3. **{{AC_3_KEYWORD}}**：Given {{AC_3_GIVEN}}，When {{AC_3_WHEN}}，Then {{AC_3_THEN}}
4. **{{AC_4_KEYWORD}}**：Given {{AC_4_GIVEN}}，When {{AC_4_WHEN}}，Then {{AC_4_THEN}}
5. **{{AC_5_KEYWORD}}**：Given {{AC_5_GIVEN}}，When {{AC_5_WHEN}}，Then {{AC_5_THEN}}

## 关联 Feature

本 Story 实现 [[{{FEATURE_ID}}]]。

## 关联需求

本故事落实 [[{{PRODUCT_SHORT}}-需求台账|{{REQ_ENTRY_ID}}]]。