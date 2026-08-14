# 需求分析草稿工作流

**前置条件**：顶层管线已完成第 1 步，且 `workflow.state=requirement-analysis`、`mode=draft`。

**按需读取**：本文件所列步骤对应的 `../guides/question-bank.md`、`../guides/quality-and-interaction.md`、模板、写作范式和 `references/shared/traceability-model.md`；不读取过程项目写入和校验详情。

**允许写入**：仅 `docs/_extracted/.fields/fields-*.json`。不得写正式 Markdown、项目记忆或 `workflow.state`。

**用户问题**：每轮只提出一个问题；每次问题前按 `../guides/quality-and-interaction.md` 输出理解回执，并完整执行 `../guides/question-bank.md` 的“盘问式决策澄清协议”。

**终点**：信息不足或仍在当前批次澄清时返回 `needs-input`；当前批次产品库文档预览满足门禁时返回 `draft-ready`，并携带 `artifactScope=requirement-epic | features`。
## 产出顺序

本文件规定执行顺序和门禁。每一步需要追问时，去 `../guides/question-bank.md` 取对应字段的问题。展示格式遵守主调度器传入的 `interactionContract`。

需求分析按两个顺序批次执行：`requirement-epic` 先起草、确认并写入产品库需求卡片 + Epic；只有该批次返回 `persisted` 后，才进入 `features` 批次起草、确认并写入产品库 Feature。任一批次的 `draft-ready` 只表示该批次预览可确认，不表示整个需求分析阶段完成。

在字段顺序允许进入下一问前，先依照问题库的“盘问式决策澄清协议”核实可查事实、选择最上游未决节点，并在该节点获用户决断后才继续其下游字段。该协议的共同理解门禁优先于本工作流的草稿和落盘出口。

### 字段 JSON 文件

字段 JSON 是正式文档的数据源，一份文档对应一个 JSON：

- 需求卡片：`docs/_extracted/.fields/fields-req-<nnn>.json`
- Epic：`docs/_extracted/.fields/fields-epic-<nnn>.json`
- Feature：`docs/_extracted/.fields/fields-feature-<nnn>.json`

以上路径均相对于 `<projectPath>/`。字段 JSON 是中间状态文件，存放在 `docs/_extracted/.fields/` 子目录中，不与正式 Markdown 产物混放。

JSON 的字段名和结构见"写入产品库"章节。`mode=draft` 时必须创建并持续更新字段 JSON；同时在对话中展示用户可见的逐字段草稿。字段 JSON、对话草稿、模板章节三者必须保持一致。`mode=persist` 且用户确认完整草稿后，以字段 JSON 作为 `render-doc.sh` 的唯一数据源渲染正式 Markdown。

### 启动时：读取 JSON 恢复进度

每次被主调度器调用时，先检查 `<projectPath>/docs/_extracted/.fields/` 下是否有字段 JSON 文件。如果有，读取 JSON，检查哪些字段已填、哪些还空着，从中断处继续，不要从头问。

再确定唯一批次：正常委派必须传入 `artifactScope`；仅恢复旧项目且 handoff 缺失该字段时，才根据正式产物补推——需求卡片和 Epic 尚未同时存在则选择 `requirement-epic`，二者已存在则选择 `features`。`requirement-epic` 不读取或起草 Feature；`features` 必须先确认正式需求卡片和 Epic 均存在且可读，否则返回 `blocked`。

批次只路由一次：`artifactScope=requirement-epic` 执行第 1 至第 6 步并在第 6 步终止；`artifactScope=features` 跳过第一段，执行第 7 至第 10 步并在第 10 步终止。不得在一次调用中跨越两个批次。

### 每次回答后：更新 JSON

`mode=draft` 每轮用户回答后，必须立即做两件事：
1. **记录 Q&A**：将该轮的追问和用户回答（经润色优化，保留全部信息量，只能多不能少）追加到字段 JSON 的 `qa_log` 对应字段数组中。
2. **更新字段值**：基于已有 Q&A 素材，按 `../writing-paradigm/` 对应范式撰写该字段的最终润色值（丰富的、按范式结构化的多行 markdown 内容），写入字段 JSON 的对应字段。

`qa_log` 是 AI 写作的素材源，最终润色值是按范式写出的丰富产物。两者都必须实时更新。`mode=persist` 时，校验最终润色值与用户确认的产品库文档预览一致，然后渲染 Markdown。

### 产品库基线读取

当草稿涉及已有产品库文档时（如修改已有 Feature），必须先读取产品库当前版本作为基线：

- 字段 JSON 中的值只用于"未持久化的新字段"或"Q&A 上下文"。
- 已持久化字段以产品库文档实际内容为准，不从字段 JSON 重新渲染。
- 草稿预览中的正文引用使用产品库文件名（如 `[[网资-需求卡片]]`），不使用过程 ID。

---

### 第一段：需求卡片 + Epic

**第 1 步：创建字段 JSON 和对话内字段草稿，输出当前理解**

- 首次进入需求分析（`docs/_extracted/.fields/` 下尚无需求卡片或 Epic 字段 JSON）时，先向用户展示需求分析阶段会如何走完的流程预告，让用户知道后面的步骤与出口，不追加第二个问题：

  ```text
  需求分析完整流程会这样走完：
  完成需求卡片 + Epic（设计文档）
  -> 展示需求卡片 + Epic（设计文档） 产品库文档对话预览
  -> 用户确认内容正确
  -> 写入产品库，生成需求卡片和设计文档
  -> 继续 Feature 拆解
  -> 展示 Feature 产品库文档预览
  -> 用户确认内容正确
  -> 写入产品库，生成多个能力文档
  -> 检查需求分析阶段文档是否完整
  -> 需求分析阶段完成
  ```

  流程预告只展示一次；已有字段 JSON 恢复进度时（非首次）不重复展示。
- `iteration` 项目：先展示已有产品 Epic/Feature 清单，问"在这些已有能力基础上，你想新增什么？"
- `refactor` 项目：先展示已有产品完整能力清单，问"哪些能力的非功能性方面需要改进？"
- 为需求卡片和 Epic 各创建一个字段 JSON 文件（`docs/_extracted/.fields/fields-req-<nnn>.json`、`docs/_extracted/.fields/fields-epic-<nnn>.json`）和一份对话内字段草稿；两者字段集合必须完全一致，所有字段初始为空字符串。
- 去 `../guides/question-bank.md` → “广度优先问题库”，按”当前理解回执”格式输出。
- 内容包括：角色、场景、问题簇、能力候选、范围边界、待验证项。
- 用户确认后，进入第 2 步。

**第 2 步：追问需求卡片字段**

- 读取 `docs/_extracted/.fields/fields-req-<nnn>.json`，找出仍为空字符串的字段。
- 去 `../guides/question-bank.md` → “需求卡片字段追问”，逐个字段追问：
  - 需求基本信息
  - 现状描述
  - 痛点
  - 问题本质还原
  - 需求评估结果
- 每轮只问一个字段。用户回答后，立即更新对应字段 JSON 和对话内字段草稿。
- 回答不清时追问 1-2 轮，仍说不清标记为“待验证”（字段 JSON 和对话内字段草稿均记录 `[待验证]`）。
- 全部 5 个字段填写完毕后，进入第 3 步。

**第 3 步：追问 Epic 字段**

- 读取 `docs/_extracted/.fields/fields-epic-<nnn>.json`，找出仍为空字符串的字段。
- 去 `../guides/question-bank.md` → “Epic 字段追问”，逐个字段追问：
  - 需求背景（引用需求卡片，从 `docs/_extracted/.fields/fields-req-<nnn>.json` 的标题和一句话结论自动填入）
  - 产品名称（从 `progress.json` 的 `projectName` 和 `productShortName` 字段自动填入，格式：`{projectName}（{productShortName}）`，不追问用户）
  - 产品定位
  - 产品目标
  - 用户角色
  - 核心场景
  - 产品价值
  - 产品范围与边界
  - 建设思路
- 每轮只问一个字段。用户回答后，立即更新对应字段 JSON 和对话内字段草稿。
- 建设思路、产品范围与边界必须直接问用户，不靠 AI 推导。
- 全部 9 个字段填写完毕后，进入第 4 步。

**第 4 步：字段覆盖回执**

- 读取两个 JSON 文件，按字段逐一列出已收集到的完整内容和状态。
- 问用户：”以上是否准确，哪里需要补充或纠正？”
- 有字段仍为空且用户暂时说不清时，写入 `[待验证]`。
- 同时执行 `../guides/question-bank.md` 的共同理解门禁；只有用户明确确认当前范围、已确认决定、待验证项及其阻塞影响均被共同理解后，才能进入第 4.5 步。

**第 4.5 步：范式自检**

输出草稿前，逐字段对照 `../writing-paradigm/` 范式速查表做格式自检。任一字段不合规，必须重写该字段后再进入第 5 步：

- 读取 `../writing-paradigm/general-rules.md` 的六条通用规律和 `../writing-paradigm/requirement-card.md`（或 `epic.md`）的字段范式速查表。
- 逐字段检查：
  1. 该字段是否用了范式速查表指定的范式（A/B/C/D/E/F）？
  2. 首句是否是总结性判断，不是"核心痛点：""具体表现："等标签？
  3. 分条列点是否每条以 `**加粗关键词**` 开头（不是 `1.` 编号、不是无加粗标签）？
  4. 该用表格的字段（C 范式）是否用了表格？该用流程图的字段（D 范式）是否用了流程图？
  5. 范式 B 的 blockquote 核心论断、范式 F 的"先事实后结论"结构是否到位？
- 不合规的字段必须当场重写，不得带着格式问题进入草稿预览。

**第 5 步：输出需求卡片 + Epic 交互草稿**

- 读取 `../templates/requirement-card.md` 和 `../templates/epic.md`。
- 按"质量评分门禁"做预输出评分。任一维度低于 5 分时，不输出草稿，返回评分、缺口和下一轮最关键问题。
- 做范围漂移检查：如果草稿只覆盖初始大问题的子问题，先向用户确认切入范围。
- 按模板结构输出完整落盘预览，每个字段写出完整内容，不写摘要或"详见上文"。预览必须包含 `../templates/requirement-card.md` 和 `../templates/epic.md` 中的全部章节、表格和字段；字段名必须使用模板字段，不得改成自造字段。
- 可选：在对话中预览草稿时，可运行 `bash "<skillPath>/scripts/validate-paradigm.sh" "<output_file>"` 做范式机械校验，提前发现格式问题。落盘时 `render-doc.sh` 会自动运行校验。

**第 6 步：返回第一批次预览**

需求卡片 + Epic 的产品库文档预览满足门禁后，返回 `draft-ready`、`artifactScope=requirement-epic`。主调度器展示该预览并请求确认写入产品库；用户确认后，下一轮以 `mode=persist`、`artifactScope=requirement-epic` 写入产品库。本次调用在此终止，不进入第二段。

---

### 第二段：Feature

第二段只在第一段已正式写入产品库后开始。进入时必须能读取正式需求卡片和 Epic；只有字段 JSON 或对话确认、不存在产品库文档时，不得开始 Feature 拆解。

**第 7 步：问出能力清单**

- 去 `../guides/question-bank.md` → “Feature 字段追问” → “能力清单”。
- 基于已确认的 Epic，问用户拆成哪些产品能力，每个能力解决哪类用户任务。
- 用户确认能力清单后，为每个能力创建一个 `docs/_extracted/.fields/fields-feature-<nnn>.json` 和一份对话内 Feature 字段草稿；两者字段集合必须完全一致，所有字段初始为空字符串。

**第 7.5 步：能力分类判断与确认**

能力清单确认后、详细字段追问前，必须执行能力分类判断：

1. **读取分类指南**：
   - 读取 `../guides/capability-classification.md`
   - 按其中的”分类判断流程 → 阶段 1”执行

2. **AI 自主判断分类**：
   - 输入：能力清单（能力名称 + 简要任务描述）
   - 根据能力名称和任务类型判断分类
   - 可参考常见分类（数据管理类、服务输出类、质量反馈类、运营支撑类），也可根据产品特点提出新分类
   - 检查分类粒度（每类 3-8 个能力文档为宜）

3. **展示分类建议**：
   ```markdown
   ### 能力分类建议

   根据 {n} 个能力的任务特征，建议按以下方式分类：

   #### {产品简称}-{分类名1}能力（{数量1}个）
   - **{能力名称}**：{任务类型和分类依据}
   - **{能力名称}**：{任务类型和分类依据}
   - ...

   #### {产品简称}-{分类名2}能力（{数量2}个）
   - **{能力名称}**：{任务类型和分类依据}
   - **{能力名称}**：{任务类型和分类依据}
   - ...

   **分类原则说明**：
   - {分类名1}：{该分类的判断标准和包含能力的共同特征}
   - {分类名2}：{该分类的判断标准和包含能力的共同特征}
   - ...

   以上分类是否合理？后续会按分类分组追问各能力的详细字段。
   
   **提示**：现在确定分类框架，后续会按分类分组追问详细字段。同类能力一起追问，可以保持粒度和风格的一致性。
   ```

4. **等待用户确认**：
   - 用户确认：记录分类方案，进入第 8 步
   - 用户调整：根据用户意见修改分类，重新展示，直到确认
   - 分类方案记录到 `<projectPath>/docs/phase-summary.md` 的 `feature-categories` 字段

5. **更新字段 JSON**：
   在每个 `fields-feature-<nnn>.json` 中添加临时字段：
   ```json
   {
     “id”: “feature-001”,
     ...
     “_category”: “{分类名}”,
     “_category_folder”: “{产品简称}-{分类名}能力”
   }
   ```
   - `_category`：分类名（不含产品简称）
   - `_category_folder`：完整文件夹名（含产品简称）
   - 这两个字段是临时标记，不进入 `render-doc.sh` 的模板渲染

**第 8 步：按分类分组追问 Feature 字段**

建议按分类分组追问，同类能力一起处理：
- 先完成 {分类名1} 下的所有能力字段追问
- 再完成 {分类名2} 下的所有能力字段追问
- 以此类推

分组追问的好处：
- 同类能力一起追问，用户可以对比思考
- 保持同类能力的粒度和风格一致
- 可以强调”这几个能力都属于 {分类名}，目标应该聚焦 {该分类的核心特征}”

追问方式保持不变：
- 读取当前 Feature 的 JSON 文件，找出仍为空字符串的字段。
- 去 `../guides/question-bank.md` → “Feature 字段追问”，逐个 Feature、逐个字段追问：
  - 需求背景（引用需求卡片，从 `docs/_extracted/.fields/fields-req-<nnn>.json` 自动填入）
  - 能力名称
  - 能力描述
  - 能力目标
  - 用户角色（引用 Epic，从 `docs/_extracted/.fields/fields-epic-<nnn>.json` 自动填入）
  - 业务价值
  - 业务场景
  - 业务流程
  - 业务规则
  - 技术可行性
  - 资源投入
  - 优先级
- 每轮只问一个字段。用户回答后，立即更新对应字段 JSON 和对话内字段草稿。
- 业务流程、业务规则、资源投入、优先级必须直接问用户，不靠 AI 推导。
- 全部 12 个字段填写完毕后，做一次字段覆盖回执（列出完整内容和状态），并执行 `../guides/question-bank.md` 的共同理解门禁；未获用户明确确认不得进入第 9 步。

**第 9 步：输出 Feature 交互草稿**

- 读取 `../templates/feature.md`，按模板结构输出产品库文档预览。预览必须包含模板中的全部章节、表格和字段；字段名必须使用模板字段，不得改成自造字段。
- 按”质量评分门禁”做预输出评分。任一维度低于 5 分时，不输出草稿。
- 每个字段写出完整内容，不写摘要或”详见上文”。

**第 10 步：全部 Feature 输出完成**

输出本批次全部 Feature 的产品库文档预览。任一 Feature 未完成字段确认、质量门或预览时，回到对应步骤，并返回 `needs-input`。

仅当至少一个 Feature 且能力清单中的全部 Feature 均已完成时，才返回 `draft-ready`、`artifactScope=features`。主调度器展示 Feature 批次预览并请求确认；用户确认后，下一轮以 `mode=persist`、`artifactScope=features` 进入 `persist.md`。

**注意**：能力分类已在第 7.5 步确认，此步骤无需再次判断分类。

---
