---
id: "{{PRODUCT_SHORT}}-REQ-LEDGER"
product: "{{PRODUCT_FULL_NAME}}"
type: "需求台账"
lastUpdated: "{{DATE}}"
aliases:
  - {{PRODUCT_SHORT}}需求台账
  - 需求登记台账
tags:
  - 需求台账
  - 需求登记
---

# {{PRODUCT_NAME}} 需求台账

> 台账按小功能登记需求条目：每个 Feature（能力）在拆解时拆成若干条，每条由 1-N 个用户故事落实。粒度阶梯：**能力 > 条目 > 故事**。追加式：只加行、不覆盖旧行，每次追加更新 `lastUpdated`。

| 条目ID | 登记日期 | 登记人 | 所属Feature | 优先级 | 需求内容 |
|---|---|---|---|---|---|
| {{ITEM_ID}} | {{DATE}} | {{REGISTERED_BY}} | {{FEATURE_NAME}}（{{FEATURE_ID}}） | {{PRIORITY}} | {{REQUIREMENT_CONTENT}} |

**行规则**：

- 条目ID：`<产品简称>-REQ-<三位序号>`（如 `{{PRODUCT_SHORT}}-REQ-001`），产品内唯一、连续累加，不随废弃回收；追加时取表内最大序号 +1。
- 需求内容：`**功能名**：做什么 + 给谁用/场景 + 关键组成或边界`，2-4 句自包含可读；不用三段式、不写验收要点（GWT 留给用户故事阶段）。
- 追加式：新增/修改/废弃需求均追加新行；修改/废弃行在需求内容中注明被修改条目的 ID（如"修改自 REQ-003"）。