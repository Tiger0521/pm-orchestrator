# 需求分析产品库写入工作流

**前置条件**：顶层管线已完成第 1 步，且 `workflow.state=requirement-analysis`、`mode=persist`；`artifactScope` 必须明确为 `requirement-epic`、`features` 或 `requirement-ledger`，并具有用户对该批次完整预览的明确确认。

**按需读取**：`../guides/quality-and-interaction.md`、对应模板、写作范式和 `references/shared/traceability-model.md`。

**允许写入**：已确认字段对应的正式 Markdown、`refs.json`、`facts.json`、`decision-log.md`、`tracking-log.md`、`phase-summary.md` 和允许更新的 `progress.json` 字段；不得修改 `workflow.state`。

**终点**：任一确认、JSON、渲染或校验条件不满足时 `needs-input` 或 `blocked`；全部完成后 `persisted`。
## 写入产品库

当 `mode=persist` 时，将用户已确认的产品库文档预览写入 `selectedProductLibraryPath/<产品全名>/`。写入不是自动发生的，而是由主调度器在用户确认后以 `mode=persist` 重新调用你时执行。

### 产品库写入步骤

1. 确认用户已看过并确认当前 `artifactScope` 的产品库文档预览。若只有摘要草稿、字段覆盖清单或非模板字段，返回 `needs-input`；确认只对当前批次生效，不得扩张到另一批次。
2. 按批次校验全部输入后再写入（校验目标路径改为产品库 `selectedProductLibraryPath/<产品全名>/`）：
   - `requirement-epic`：必须有一个完整 `fields-req-<nnn>.json` 和一个完整 `fields-epic-<nnn>.json`，Epic 的 `req_id` 必须关联该需求卡片；本批次不要求、也不渲染 Feature JSON。
   - `features`：正式需求卡片和 Epic 必须已存在；必须至少有一个完整 `fields-feature-<nnn>.json`，每个 Feature 的 `req_id`、`epic_id` 必须关联这些正式上游文档；本批次不得重新渲染或改写需求卡片和 Epic。
   全部必填 JSON key 必须有值，空字符串视为未完成。任一文件、关联或确认缺失时，阻断 persist，不得渲染任何正式 Markdown。
3. 如果目标产品库文档已存在：读取当前版本，与草稿对比，标注差异，按增量合并或提示用户确认全量覆盖。
4. 如果目标产品库文档不存在：调用渲染脚本直接写入产品库：
   ```bash
   bash "<skillPath>/scripts/render-doc.sh" \
     "<projectPath>/docs/_extracted/.fields/fields-<doc-type>-<nnn>.json" \
     "<selectedProductLibraryPath>/<产品全名>/" \
     "<产品简称>" "<产品全名>" "[能力路径]"
   ```
4.5. **（仅 features 批次）应用能力分类落盘**：
   - 读取 `phase-summary.md` 中的 `feature-categories` 字段（由 draft 阶段记录的分类方案）
   - 为每个 Feature 执行分类落盘：
     a. **读取字段 JSON 中的分类标记**：从 `_category` 和 `_category_folder` 临时字段获取分类信息
     b. **更新 frontmatter**：在已渲染的 Feature Markdown 文件中，在 frontmatter 添加 `category: "{分类名}能力"` 字段
     c. **添加同类引用**：在"## 能力描述"章节的内容之后、"## 能力目标"章节标题之前插入同类能力引用：
        ```markdown
        
        **同类能力**：
        - [[文件名1]]
        - [[文件名2]]
        ```
        使用简洁的 Obsidian 链接格式 `[[文件名]]`（文件名不含 .md 后缀），排除当前文档自身，按文件名字母顺序排列
     d. **直接在产品库创建能力目录**：渲染脚本根据能力路径直接在产品库中创建能力目录，能力文档写入对应能力目录下
     e. **禁止生成 README**：不得在任何阶段创建 README.md 或其他说明文件，分类文件夹只包含能力文档 .md 文件
   - 分类信息的添加只影响 frontmatter 和章节引用，不修改字段正文内容
5. 渲染脚本自动：分配继承式 ID、创建能力目录、生成产品库 frontmatter、用产品库文件名引用、写入产品库。渲染结果必须与用户确认过的产品库文档预览同结构、同字段、同正文内容；如果不一致，必须报告并停止推进。应用分类后的 frontmatter 和同类引用不影响内容一致性校验。
6. **范式校验硬门禁**：`render-doc.sh` 渲染完成后会自动运行 `validate-paradigm.sh` 做范式机械校验。检查校验输出：
   - 如果有 `[WARN]` 项，**必须修复字段 JSON 中对应字段的范式格式**（加粗领条、表格、流程图、blockquote 等），重新渲染，直到零警告才能报告 `persisted`。
   - 不得跳过范式校验、不得忽略警告、不得在有警告时报告 `persisted`。

### 需求台账落盘

台账条目在 features 批次随 Feature 拆解产生（见 `draft.md` 第 8.5 步，草稿在 `docs/_extracted/.fields/requirement-ledger-draft.md`），变更条目由 `requirement-ledger` 批次追加。两种落盘均为"追加式写表格行"，不覆盖已有行：

1. **校验台账草稿**：读取台账草稿，逐行校验六列齐全（条目ID / 登记日期 / 登记人 / 所属Feature / 优先级 / 需求内容）；所属 Feature 必须是本批次（或产品库）已确认的能力文档；优先级非空；条目 ID（`<简称>-REQ-<序号>`）与产品库现有台账不冲突。
2. **追加式落盘**：按 `../templates/requirement-ledger.md` 结构，把已确认的条目行追加到产品库 `<简称>-需求台账.md` 表格——首次落盘时创建文件（frontmatter + 表头 + 条目行），非首次时按表内最大序号续加新行、重建表头结构不变、不覆盖已有行；更新 frontmatter `lastUpdated`。
3. **展示确认**：落盘前向用户展示台账表草稿（含本次新增行）；用户未确认前不得落盘对应行。
4. 落盘完成后在 `refs.json` 注册/更新 `requirement-ledger` 节点，edges 记录台账与所属能力的 `references` 关系。

### 业务文档落盘（features 批次）

Feature 批次写入时，业务文档与 Feature 同步确认落盘：

1. 读取 `docs/_extracted/.fields/business-doc-draft.md`（draft 阶段收集的扁平 4 字段草稿：业务价值 / 业务场景表 / 业务流程 / 业务规则表，场景与规则行带「所属能力」列）。
2. 渲染 Feature 后，向用户展示业务文档草稿（扁平 4 字段完整结构），用户确认/修改后落盘。
3. **重构式写入**产品库 `<简称>-业务文档.md`：以产品库现有文档为基线（业务价值默认保留现有版本不改写）、并入本次新增业务内容后**整体重写** 4 个字段，不按能力名增量打补丁；更新 frontmatter `lastUpdated`，并在「变更记录」表追加一行。
4. 场景编号（SC-XX）、规则编号（BR-XX）、流程编号（FL-XX）从现有文档取最大序号继续累加，不重排。

### 批次返回

- `requirement-epic` 写入成功：需求卡片 + Epic 均已落盘后，返回 `persisted`、`artifactScope=requirement-epic`、`nextAction=draft-features`。在 `phase-summary.md` 记录"需求卡片、Epic 已写入产品库，接下来继续拆解 Feature（拆解时产出需求台账条目）"（对外措辞）；不得报告需求分析阶段完成。
- `features` 写入成功：确认需求卡片、Epic、能力清单中的全部 Feature、业务文档与需求台账条目均写入产品库，且与用户确认的预览一致后，返回 `persisted`、`artifactScope=features`、`nextAction=phase-complete`。需求分析阶段即完成，可直接进入下一阶段或等待用户指令。本 agent 不修改 `workflow.state`。
- 台账草稿或业务文档草稿未获用户确认时，不得落盘对应文档；先返回 `draft-ready`（携带对应 `artifactScope` 标记）或 `needs-input` 展示草稿请求确认。

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
  "qa_log": {
    "capability_name": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "capability_description": [
      {"round": 1, "q": "...", "a": "..."}
    ],
    "capability_goal": [
      {"round": 1, "q": "...", "a": "..."}
    ]
  }
}
```

> **业务 4 字段**：`business_value`、`business_scenarios`、`business_process`、`business_rules` 已从 Feature 字段 JSON 删除——这些内容在 draft 阶段按扁平 4 字段收集到 `docs/_extracted/.fields/business-doc-draft.md`（场景/规则行带「所属能力」列），persist 阶段以产品库现有文档为基线、并入新增后整体重写产品库业务文档，不经 Feature 字段 JSON。

### 更新项目记忆

落盘后更新以下文件：

| 文件 | 更新内容 |
| --- | --- |
| `refs.json` | 只注册当前批次的新文档节点和引用关系（`path` 指向产品库路径，含 `libraryId`/`contentHash`/`lastSynced`）：第一批注册需求卡片 ← Epic，第二批追加 Epic ← Feature |
| `facts.json` | 记录用户已确认的事实，每条事实标注来源类型 |
| `decision-log.md` | 记录建设思路（设计理念）、范围边界等决策及理由 |
| `tracking-log.md` | 记录待验证假设、风险、未决问题 |
| `phase-summary.md` | 追加当前批次恢复摘要：第一批明确记录下一步为 Feature 拆解，第二批记录需求分析阶段完成，并可继续修改或发起阶段校验；不复制完整需求正文。摘要随写 `phase_status`（供 `references/phase-navigator.md` 读取）：`requirement-epic` 落盘完成及 `features` 批次成果确认后 `confirmed`，`features` 全部落盘（本阶段完成）后 `persisted` |
| `progress.json` | 更新当前阶段和顶层的 `lastUpdated`；`description` 是项目初始短描述，不承载完整需求正文；不修改 `workflow.state`、顶层 `status` 或阶段转换字段 |
---
