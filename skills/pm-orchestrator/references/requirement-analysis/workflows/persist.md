# 需求分析过程项目写入工作流

**前置条件**：顶层管线已完成第 1 步，且 `workflow.state=requirement-analysis`、`mode=persist`；`artifactScope` 必须明确为 `requirement-epic` 或 `features`，并具有用户对该批次完整预览的明确确认。

**按需读取**：`../guides/quality-and-interaction.md`、对应模板、写作范式和 `references/shared/traceability-model.md`。

**允许写入**：已确认字段对应的正式 Markdown、`refs.json`、`facts.json`、`decision-log.md`、`tracking-log.md`、`phase-summary.md` 和允许更新的 `progress.json` 字段；不得修改 `workflow.state`。

**终点**：任一确认、JSON、渲染或校验条件不满足时 `needs-input` 或 `blocked`；全部完成后 `persisted`。
## 写入过程项目

当 `mode=persist` 时，将用户已确认的过程项目正式文档预览写入 `<projectPath>/docs/`。写入不是自动发生的，而是由主调度器在用户确认后以 `mode=persist` 重新调用你时执行。persist 不是重新生成内容，而是固化用户已经看过并确认过的内容；它不得写入产品库目标目录。

### 过程项目写入步骤

1. 确认用户已看过并确认当前 `artifactScope` 的过程项目正式文档预览。若只有摘要草稿、字段覆盖清单或非模板字段，返回 `needs-input`；确认只对当前批次生效，不得扩张到另一批次。
2. 按批次校验全部输入后再写入：
   - `requirement-epic`：必须有一个完整 `fields-req-<nnn>.json` 和一个完整 `fields-epic-<nnn>.json`，Epic 的 `req_id` 必须关联该需求卡片；本批次不要求、也不渲染 Feature JSON。
   - `features`：正式需求卡片和 Epic 必须已存在；必须至少有一个完整 `fields-feature-<nnn>.json`，每个 Feature 的 `req_id`、`epic_id` 必须关联这些正式上游文档；本批次不得重新渲染或改写需求卡片和 Epic。
   全部必填 JSON key 必须有值，空字符串视为未完成。任一文件、关联或确认缺失时，阻断 persist，不得渲染任何正式 Markdown。
3. 只对当前 `artifactScope` 的字段 JSON 调用脚本渲染并写入文件：
   ```bash
   bash "<skillPath>/scripts/render-doc.sh" "<projectPath>/docs/_extracted/.fields/fields-<doc-type>-<nnn>.json" "<projectPath>/docs/requirement-analysis/"
   ```
4. 脚本自动生成 Markdown 文件，文件名与 `id` 一致。渲染结果必须与用户确认过的过程项目正式文档预览同结构、同字段、同正文内容；如果不一致，必须报告并停止推进。
5. **范式校验硬门禁**：`render-doc.sh` 渲染完成后会自动运行 `validate-paradigm.sh` 做范式机械校验。检查校验输出：
   - 如果有 `[WARN]` 项，**必须修复字段 JSON 中对应字段的范式格式**（加粗领条、表格、流程图、blockquote 等），重新渲染，直到零警告才能报告 `persisted`。
   - 不得跳过范式校验、不得忽略警告、不得在有警告时报告 `persisted`。

### 批次返回

- `requirement-epic` 写入成功：返回 `persisted`、`artifactScope=requirement-epic`、`nextAction=draft-features`。在 `phase-summary.md` 记录“需求卡片和 Epic 已写入过程项目，接下来继续拆解 Feature”（对外措辞）；不得报告需求分析阶段完成。本批次不询问是否导出产品库。
- `features` 写入成功：确认需求卡片、Epic 和能力清单中的全部 Feature 的正式 Markdown 均已存在，且与用户确认的 Feature 批次预览一致后，返回 `persisted`、`artifactScope=features`、`nextAction=offer-product-library-export`。在 `phase-summary.md` 把需求分析阶段完成条件记录为 `requirement-documents-written`（需求分析全部文档已写入过程项目）。这是导出引导的触发前提：只有处于该状态才询问是否导出产品库；尚有需求卡片、Epic 或 Feature 未完成时不得询问。主调度器据此进入产品库导出引导；本 agent 不直接导出，也不修改 `workflow.state`。

### 阶段完成状态

需求分析阶段完成条件区分三种状态，记录在 `phase-summary.md`：

| 状态 | 含义 |
| --- | --- |
| `requirement-documents-written` | 需求分析全部文档已写入过程项目 |
| `product-library-export-pending` | 已询问或等待用户决定是否导出产品库 |
| `product-library-exported` | 用户确认后，文档已实际导出到产品库 |

询问是否导出产品库属于需求分析阶段的收尾动作，但不应阻止后续 Story 拆解。用户暂不导出时，需求分析仍可结束并进入下一阶段；系统只需保留“产品库待导出”的状态。三种状态由主调度器维护更新，本 agent 在 `features` persist 完成后只负责把状态设为 `requirement-documents-written`，不自行推进到 `product-library-export-pending` 或 `product-library-exported`。

### 字段 JSON 格式

字段 JSON 包含两部分：**最终润色值**（按范式写出的丰富多行 markdown 内容，`render-doc.sh` 只读这部分）和 **`qa_log`**（按字段记录的全部 Q&A 对话，是 AI 写作的素材源）。

**Q&A 记录规则**：
- 每轮追问后，将该轮 Q&A 追加到 `qa_log` 的对应字段数组中
- Q&A 内容经润色优化：结构化、去口语化、保留全部信息量，只能多不能少
- 用户用举例、打比方、讲故事等方式提供的信息，润色后保留原意和细节
- AI 的追问也要记录（润色后的版本），不只是用户回答
- 一轮追问有多轮交互时，每组 Q&A 都记录

**qa_log 条目格式**：
```json
{"round": 1, "q": "润色后的追问内容", "a": "润色后的用户回答内容"}
```

**docs/_extracted/.fields/fields-req-<nnn>.json**：
```json
{
  "id": "req-001",
  "type": "requirement-card",
  "projectId": "<project-id>",
  "title": "...",
  "requirement_source": "...",
  "requester": "...",
  "trigger_time": "...",
  "affected_scope": "...",
  "current_status": "...",
  "current_state": "...",
  "pain_points": "...",
  "root_problem": "...",
  "business_value_score": "...",
  "business_value_reason": "...",
  "impact_score": "...",
  "impact_reason": "...",
  "feasibility_score": "...",
  "feasibility_reason": "...",
  "resource_score": "...",
  "resource_reason": "...",
  "qa_log": {
    "requirement_source": [
      {"round": 1, "q": "...", "a": "..."},
      {"round": 2, "q": "...", "a": "..."}
    ],
    "current_state": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "pain_points": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "root_problem": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "evaluation": [
      {"round": 1, "q": "...", "a": "..."}
    ]
  }
}
```

**docs/_extracted/.fields/fields-epic-<nnn>.json**：
```json
{
  "id": "epic-001",
  "type": "epic",
  "projectId": "<project-id>",
  "title": "...",
  "req_id": "req-001",
  "requirement_bg": "...",
  "product_name": "...",
  "positioning": "...",
  "product_goals": "...",
  "user_roles": "...",
  "core_scenarios": "...",
  "product_value": "...",
  "in_scope": "...",
  "out_of_scope": "...",
  "build_approach": "...",
  "qa_log": {
    "product_name": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "positioning": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "product_goals": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "user_roles": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "core_scenarios": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "product_value": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "scope": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "build_approach": [
      {"round": 1, "q": "...", "a": "..."}
    ]
  }
}
```

**docs/_extracted/.fields/fields-feature-<nnn>.json**：
```json
{
  "id": "feature-001",
  "type": "feature",
  "projectId": "<project-id>",
  "title": "...",
  "req_id": "req-001",
  "epic_id": "epic-001",
  "requirement_bg": "...",
  "capability_name": "...",
  "capability_description": "...",
  "capability_goal": "...",
  "user_roles": "...",
  "business_value": "...",
  "business_scenarios": "...",
  "business_process": "...",
  "business_rules": "...",
  "tech_feasibility": "...",
  "resource_investment": "...",
  "priority": "...",
  "priority_reason": "...",
  "qa_log": {
    "capability_name": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "capability_description": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "capability_goal": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "business_value": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "business_scenarios": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "business_process": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "business_rules": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "tech_feasibility": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "resource_investment": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "priority": [
      {"round": 1, "q": "...", "a": "..."}
    ]
  }
}
```

### 更新项目记忆

落盘后更新以下文件：

| 文件 | 更新内容 |
| --- | --- |
| `refs.json` | 只注册当前批次的新文档节点和引用关系：第一批注册需求卡片 ← Epic，第二批追加 Epic ← Feature |
| `facts.json` | 记录用户已确认的事实，每条事实标注来源类型 |
| `decision-log.md` | 记录建设思路（设计理念）、范围边界等决策及理由 |
| `tracking-log.md` | 记录待验证假设、风险、未决问题 |
| `phase-summary.md` | 追加当前批次恢复摘要：第一批明确记录下一步为 Feature 拆解，第二批记录阶段完成状态 `requirement-documents-written`，并可继续修改或发起阶段校验；不复制完整需求正文 |
| `progress.json` | 更新当前阶段和顶层的 `lastUpdated`；`description` 是项目初始短描述，不承载完整需求正文；不修改 `workflow.state`、顶层 `status` 或阶段转换字段 |
---
