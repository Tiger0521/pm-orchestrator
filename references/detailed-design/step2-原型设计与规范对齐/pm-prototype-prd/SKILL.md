---
name: pm-prototype-prd
description: >
  **产品需求文档（PRD）+ 交互原型 一体化工作流。** 当用户提出"需求说明/需求说明书/写需求/业务需求/输出需求文档/需求分析/整理需求/PRD/需求规格说明书"等请求时，**优先使用本技能**，因为本技能覆盖了从结构化需求文档（背景→目标→详细需求→功能价值）到高保真HTML交互原型（墨刀式页面内嵌标注、框选迭代、参考图复刻）的完整链路，产出物远超纯文档生成。
  核心能力：阶段一（用户说"需求说明/写需求"时触发）→ 生成Word格式业务需求文档；用户确认后进入阶段二 → 生成可交互HTML原型，所有功能注释、业务逻辑、边界说明直接标注在页面组件上（墨刀/Axure批注样式），基于标注可一键输出完整详细设计PRD。
  额外支持：画原型/HTML原型/交互原型/页面设计/设计界面/墨刀样式/框选修改/原型修改/版本号升版/美化原型/改样式/参考图复刻/原型→输出PRD/页面迭代/局部修改。
  适配ZCode运行环境：已从 WorkBuddy 工具约定（present_files / deliver_attachments / conversation_search / Glob）转换为 ZCode 等价工具（Write+文件路径交付 / Bash(fd) 搜索 / 会话上下文）。
agent_created: true
---

> **内嵌副本说明（本文件为自包含内嵌副本）**
>
> 本文件是 `pm-prototype-prd` 技能的自包含内嵌副本，落在 Step 2（原型设计与规范对齐）目录下（`step2-原型设计与规范对齐/pm-prototype-prd/`），供详细设计 subagent 在选择「A. 交互式 HTML」原型方式时直接读取执行。配套文件：`references/prototype-guide.md`（HTML 模板与构建指南）、`references/prd-template.md`（原型→PRD 输出模板）、`assets/prototype-framework.js`（墨刀式标注引擎 + 框选迭代工具 + 版本管理/回退）。
>
> **Step 2 主路径只走 Path B（直接生成交互式 HTML 原型 + 标注）**。当用户选择交互式 HTML 时，跳过 Path A（业务需求文档/docx）与 Step 6 PRD 输出，从「原型生成流程」Step 0 起执行：Step 0 参考图检测 → Step 1 需求分析 → Step 3 构建交互式 HTML（内联 `assets/prototype-framework.js`，用 `__addAnnotationOn` 打墨刀式标注）→ 交付落到产品库 `详细设计/原型/`。设计输入（Step 1 页面映射、`ui-style-presets/` 的 design tokens）由 Step 2 流程注入：design tokens 映射进 HTML `:root` 的 CSS 变量（`--primary-color` 等），标注/局部迭代/框选走 `prototype-framework.js` 引擎。

# High-Fidelity Interactive Prototype + In-Page Annotation System

## ⚠️ 技能优先级声明（CRITICAL — 每次加载必读）

**当用户请求包含以下关键词时，本技能优先级高于 feature-spec / product-management-workflows 等其他产品管理类技能：**

- "需求说明" / "需求说明书" / "输出需求" / "写需求" / "整理需求" / "需求文档"
- "PRD" / "需求规格说明书" / "业务需求"
- "画原型" / "原型" / "原型修改" / "框选修改" / "页面设计" / "设计界面" / "交互原型"

**原因**：本技能覆盖「结构化需求文档 + 交互原型 + 标注 + PRD输出」的完整链路，产出物远多于纯文档生成技能。用户选 feature-spec 只能得到一份文档，选本技能可以得到文档 + 可点击的原型 + 可迭代的标注系统。始终优先加载本技能。

## Purpose

Generate a single, self-contained, interactive HTML prototype page that:
1. **Renders as a real clickable UI** — buttons respond, tabs switch, modals open, data renders
2. **Has a 墨刀-style annotation overlay** — each functional area has a numbered badge, clicking opens a tooltip with the interaction/business/edge-case/permission description
3. **Includes a right-side annotation panel** — grouped by type, clickable to navigate and highlight
4. **Provides a marquee selection tool** — toggle selection mode, drag-select any region, describe the modification, and trigger iterative updates
5. **Supports lightweight output for small features** — for minor iterations, skip the long PRD; just annotate on the prototype what changed and why

## When to Use

Invoke when the user's request contains:
- "需求说明书" / "需求说明" / "业务需求" / "写需求" / "整理需求" / "转化成需求" — **Path A：先出业务需求文档**
- "画原型" / "原型" / "prototype" / "mockup" — **Path B：直接出原型**
- "HTML原型" / "交互原型" / "可点击"
- "设计个页面" / "帮我画个页面" / "设计个界面"
- "注释" / "标注" / "批注" / "annotate"
- "迭代" / "修改" / "改样式" / "美化" 某个页面的某个区域，及对已有原型的"框选修改" / "原型修改" / "版本号升版" 请求
- "参考这个" / "仿照这个" / "复刻"
- "需求文档" / "PRD" / "需求规格说明书" / "输出需求文档" / "需求文档导出"
- "基于原型输出文档" / "根据这个原型写文档" / "出个需求文档"
- Any request describing a new page, feature, or UI change

---

## 入口分流：需求说明书 vs 直接原型

技能加载后，**第一步必须判断用户意图**，决定走哪条路径。

### 判断规则

| 用户请求关键词 | 路径 |
|--------------|------|
| "需求说明书" / "需求说明" / "业务需求" / "需求文档" / "写需求" / "整理需求" / "转化成需求" / "需求说明文档" | **Path A：先出业务需求文档 → 确认 → 再出原型** |
| "原型" / "画原型" / "prototype" / "生成原型" / "设计页面" / "交互原型" / "HTML原型" / "做原型" | **Path B：跳过需求文档，直接生成原型 + 注释** |

> **关键区分**：用户说"帮我写个需求说明" → Path A；用户说"帮我画个原型" → Path B。
> 如果用户同时提到"需求"和"原型"（如"帮我整理需求然后出原型"），走 Path A。
> Path A 仅适用于**全新需求 (0→1)** 场景。小功能迭代、局部修改、参考图复刻、原型→输出PRD 等场景直接走 Path B。

---

## Path A：业务需求文档 → 用户确认 → 原型 + PRD

当用户意图是"先出需求说明书"时，按以下流程执行。

### Step A0：已有系统截图检测与分析

在执行需求要素检查之前，**先检查用户是否上传了已有系统的截图**。

#### A0.1 截图检测规则

| 用户输入形式 | 如何处理 |
|-------------|---------|
| 消息中直接附带了截图文件（如 @image, PNG/JPG） | **必须使用 Read 工具读取该图片**，分析已有系统模块 |
| 消息中提到了"原来系统"/"现有系统"/"目前系统"等字眼，但没看到图片 | **主动询问"能否把现有系统的截图发一下？"** |
| 用户明确说"没有截图"/"全新功能" | 跳过 A0，直接进入 A1 |

#### A0.2 已有系统分析输出

用 Read 工具读取截图后，**必须先输出两份分析**，再进入需求要素检查：

**第一份：功能分析**

```
📸 已有系统分析

整体布局: {导航/侧边栏/内容区的大致结构}
核心模块: {列表出页面中现有的功能模块，如筛选栏、数据表格、操作按钮等}
当前支持的实体/规则: {截图里看得到的业务实体及其参数}
存在的问题/可改进点: {从截图中可见的不足，如缺少字段、无人数限制等}
```

**第二份：设计规范提取（关键！后续原型复用）**

从系统截图中提取 UI 设计规范，**格式与下方「Step 0.2 参考图设计提取清单」完全一致**（CSS 变量表 + 组件样式摘要）。这批样式数据将在后续原型生成时直接复用，无需用户再提供参考图。

```
📐 从系统截图提取的设计规范

主色: #1677ff | 背景: #f0f2f5 | 文字: #262626
字体: PingFang SC 14px | 圆角: 6px | 阴影: 0 2px 8px rgba(0,0,0,0.08)

组件样式:
- 导航栏: 高度56px, 白色背景, 底部1px边框
- 筛选区: 白色卡片, 圆角8px, padding 20px
- 按钮: 蓝色填充(主色) / 白色边框(次), 圆角6px, 高度32px
- 表格: 表头灰底#fafafa, 行悬浮变灰
- 输入框: 高度32px, 边框#d9d9d9, focus蓝色边框+阴影
- 分页: 白色按钮+边框, active蓝色填充
```

> **⚠️ 关键规则：系统截图 = 原型样式参考**
>
> 用户在 Path A 中提供的系统截图具有**双重用途**：
> 1. 功能分析：了解当前系统有什么、缺什么 → 用于需求文档
> 2. **样式参考：提取 UI 设计规范** → 后续生成原型时，原型的视觉风格必须与系统截图保持一致
>
> 后续进入原型生成阶段（Step A4 → Step 0）时，**系统截图自动作为参考图**，无需重复询问用户。如果原型的某个功能在截图中没有对应的组件样式（如截图里没有弹窗），则用截图中已有的组件风格（颜色、圆角、字号）推断。

### Step A1：需求要素检查与收集（必须执行）

在生成业务需求文档之前，检查用户是否提供了以下需求要素。分为**必问要素**（①②，缺一不可）和**条件要素**（③④，可推断时跳过）。

| # | 要素 | 要求 | 缺失时的追问 |
|---|------|------|-------------|
| ① | 新增需求说明 | **必问**，用户必须提供 | "要新增或改造什么功能？具体有哪些规则、实体或参数？" |
| ② | 业务背景/痛点 | **必问**，用户必须亲口确认 | "当前系统存在什么问题或痛点？为什么需要做这个需求？" |
| ③ | 目标用户/角色 | **条件追问**——用户消息中已隐含角色（如"考勤模块"→HR/管理员）则跳过；否则追问 | "谁会使用这个功能？是管理员统一配置，还是员工自助操作？" |
| ④ | 使用频率/规模 | **条件追问**——用户消息中已隐含规模（如"全公司排班"→大规模）则跳过；否则追问 | "大概涉及多少人？多久操作一次？（如每月排一次200人，还是每周10人）" |

#### 要素判断规则

| 要素 | 已提供（跳过追问）的条件 |
|------|----------------------|
| ① 需求说明 | 用户消息中描述了具体功能、实体、规则 |
| ② 业务背景 | 用户消息中明确描述了痛点或为什么做（如"手动排班太慢，每周花半天"） |
| ③ 目标用户 | 用户消息中隐含了角色（如"考勤模块""后台管理""员工端"等可推断受众） |
| ④ 使用频率 | 用户消息中隐含了规模（如"全公司""日常排班""月度排班"等可推断量级） |

> **关键规则：要素② 必须由用户亲口确认，不允许用截图分析代替**
>
> 截图分析（Step A0）只能看到"当前系统有什么"，看不出"用户真正痛在哪里、为什么需要改"。
> 即使截图分析已经列出了系统层面的可改进点，**也必须向用户追问业务背景/痛点**，不得跳过。

**如果用户未完整提供必问要素（①②）或无法推断的条件要素（③④）** → 使用 AskUserQuestion 收集缺失信息：

- 仅缺① → 追问需求说明（提供 3-4 个选项 + 自定义输入框）
- 仅缺② → 追问业务背景（提供 3-4 个具体业务场景选项，**必须贴合用户已描述的需求领域**）
- 仅缺③ → 追问目标角色（提供 3-4 个选项，如"HR/管理员统一配置""部门组长各自管理""员工自助排班""多角色混合使用"）
- 仅缺④ → 追问使用规模（提供 3-4 个选项，如"每周排班，10-50人""每月排班，50-200人""一次性配置，200人以上""规则配置后自动运行，很少手动干预"）
- 缺多个要素 → 合并为一轮追问（最多 4 个问题），**先问必问①②，再问条件③④**

**AskUserQuestion 使用规则（必须遵守）**：
1. **每个问题必须提供 3-4 个具体选项**，不能只让用户手动输入
2. **选项必须贴合用户已描述的需求场景**，不能是如"效率不高""体验不好"等泛泛表述
3. 选项应覆盖最可能的情况 + 一个"其他"自由输入通道（由 AskUserQuestion 工具自动提供）
4. 问题 header 不超过 12 字符，选项 label 不超过 8 字符

**禁止行为**：要素不齐就跳过直接生成文档。禁止只用一行文字提问而不提供选项。

### Step A2：生成业务需求文档（Word 格式）

根据用户提供的需求信息（如 Step A0 有截图分析则结合分析结果），生成结构化的**业务需求文档**，**输出为 Word 文档（`.docx` 格式）**。

#### 输出格式

必须使用 **docx skill**（python-docx）生成 Word 文档，固定使用以下四章结构：

**标题**：`{需求标题}功能需求说明`

| 章节 | 标题 | 内容要求 |
|------|------|---------|
| 一 | 需求背景 | 当前系统缺少什么？为什么需要做？从问题切入，不堆砌功能。1-2段讲清楚。如有原有系统截图分析（Step A0），必须结合分析结果描述。 |
| 二 | 需求目标 | 1. 核心能力升级 / 2. 新增/改造内容 / 3. 约束与规范 |
| 三 | 详细功能需求 | （一）核心系统能力 / （二）新增/改造内容及差异化规则 / （三）通用约束规则 |
| 四 | 功能价值 | 1-3条价值点 |

#### Word 文档排版规范

| 元素 | 格式 |
|------|------|
| 文档标题 | 宋体, 18pt, 加粗, 居中 |
| 一级标题（一、二、三、四） | 宋体, 16pt, 加粗 |
| 二级标题（（一）（二）（三）） | 宋体, 14pt, 加粗 |
| 正文 | 宋体, 12pt |
| 表格 | 有边框, 表头加粗灰底 |
| 页边距 | 上下 2.54cm, 左右 3.18cm |

#### 生成步骤

1. **加载 docx skill**：`Skill({ skill: "docx" })`（ZCode 中该技能别名为 `docx`，完整名 `document-skills:docx`，二者等价）
2. 创建文档，按 Word 排版规范设置标题、段落、表格
3. 保存为 `.docx` 文件到项目目录
4. 交付给用户：在回复中给出生成的 `.docx` 文件的绝对路径（ZCode 直接展示生成的文件），供用户打开查看

**写作规范（必须严格遵守）**：

| 规范 | 说明 |
|------|------|
| 从问题切入 | 先讲"当前系统缺什么"再讲"要做什么"，不堆砌功能 |
| 核心能力前置 | 核心系统能力作为独立一节描述，不要埋没在具体实体配置中 |
| 分层描述 | 实体类需求按"通用规则 + 各实体差异化参数"分层 |
| 不私自扩展 | 只写用户给的规则，不猜测未提及的边界条件 |
| 不塞待确认 | 不出现"待确认列表""建议"等；如需确认某点，在文档输出后单独提问 |
| 结合截图 | 如有原有系统截图，需求背景中必须具体指出截图里看到的不足 |
| 结构精简 | 严格四章：背景→目标→详细需求→功能价值，不额外增加章节 |

### Step A3：用户确认

文档输出后，**等待用户确认**。典型交互：

- 用户说"没问题"/"确认"/"OK"/"可以" → 进入 Step A4，开始原型生成
- 用户说"有个地方不对"/"XX改成YY" → 按用户反馈修改文档后重新确认
- 用户提出补充内容 → 在文档中追加后重新确认

**确认前不进行任何原型相关工作。**

### Step A4：进入原型生成流程

用户确认业务需求文档后，**跳转到下方「原型生成流程」**，从 Step 0 开始执行。

> **⚠️ 样式传递规则**：如果 Path A 中用户提供了系统截图（Step A0），进入原型生成流程时：
> - **Step 0 中的参考图检测自动命中**——A0 的系统截图即视为参考图，跳过"询问参考图"环节
> - **原型样式直接复用 A0.2 中已提取的设计规范**（CSS 变量 + 组件样式），与系统截图保持视觉一致
> - 仅在以下情况才重新询问参考图：用户明确说"原型不用系统样式，换个风格"或"另外给个参考图"

---

## Path B：直接生成原型（跳过需求文档）

当用户意图是"直接出原型"时，**跳过 Path A 全部步骤**，直接跳转到下方「原型生成流程」从 Step 0 开始执行。

---

## 原型生成流程（Path A 确认后 & Path B 共用）

以下 Step 0 ~ Step 6 为原型生成的标准流程，Path A 确认后和 Path B 均进入此流程。

### Step 0: 检查参考图 (REFERENCE CHECK — 必须最先执行)

在开始任何分析之前，**第一步必须检查用户是否上传或提及了参考截图**。

#### 0.1 参考图检测规则

| 用户输入形式 | 如何处理 |
|-------------|---------|
| 当前会话中已通过 Path A Step A0 读取过系统截图（上下文中已有 📐 设计规范） | **自动复用 A0 提取的设计规范作为参考图**，跳过图片读取，直接进入 Step 1。这是最常见的情况，不要再问用户要参考图。 |
| 消息中直接附带了截图文件（如 @image, 或上传的 PNG/JPG） | **必须使用 Read 工具读取该图片**，从中提取 UI 设计规范 |
| 消息中提到了"参考图/参照图/原来系统/类似"等字眼，但没看到图片文件 | 检查本会话上下文是否已有关联截图（若用户在另一个会话提供过，可用 `ReadSessionContext` 按会话引用）；如果找不到，**必须主动询问用户"能否把参考截图发一下？"**，不跳过此步骤 |
| 消息中有 `@image#` 标记但图片路径不可访问 | **坦诚告知用户图片已无法访问，请重新上传**，然后等待用户重新发送 |
| 用户明确说"没有参考图"或"你自己设计" | 使用默认 Ant Design 5.x 样式，跳过 Step 0.2 |

**禁止行为**：用户明确提供了参考图但不读取就直接用默认样式生成。**有图就必须读图。**

#### 0.2 参考图设计提取清单

用 Read 工具打开图片后，用眼睛逐项提取以下视觉规格，**必须输出为结构化的 CSS 变量表**：

```css
/* ===== 从参考图提取的设计规范 ===== */
--ref-primary-color: /* 主色，如 #1677ff */
--ref-primary-hover: /* 主色悬浮态，如 #4096ff */
--ref-success-color: /* 成功色，如 #52c41a */
--ref-warning-color: /* 警告色，如 #faad14 */
--ref-danger-color: /* 危险色，如 #ff4d4f */
--ref-bg-color:      /* 页面背景色，如 #f5f5f5 */
--ref-card-bg:       /* 卡片/容器背景色，如 #ffffff */
--ref-text-primary:  /* 主文字色，如 #262626 */
--ref-text-secondary:/* 次要文字色，如 #595959 */
--ref-text-muted:    /* 辅助文字色，如 #8c8c8c */
--ref-border-color:  /* 边框色，如 #d9d9d9 */
--ref-border-light:  /* 浅边框色，如 #f0f0f0 */
--ref-font-family:   /* 字体族，如 '-apple-system, PingFang SC, ...' */
--ref-font-size-sm:  /* 小字号(辅助)，如 12px */
--ref-font-size:     /* 正文字号，如 14px */
--ref-font-size-lg:  /* 大字号(副标题)，如 16px */
--ref-font-size-xl:  /* 标题字号，如 18px */
--ref-radius:        /* 组件圆角，如 6px */
--ref-radius-lg:     /* 卡片圆角，如 8px */
--ref-shadow:        /* 卡片阴影，如 0 1px 2px rgba(0,0,0,0.06) */
--ref-shadow-hover:  /* 悬浮阴影，如 0 4px 12px rgba(0,0,0,0.08) */
--ref-nav-height:    /* 导航栏高度，如 56px */
--ref-nav-bg:        /* 导航栏背景色 */
--ref-nav-text:      /* 导航栏文字色 */
--ref-table-header-bg:  /* 表格表头背景色 */
--ref-table-hover-bg:   /* 表格行悬浮背景色 */
--ref-btn-padding:   /* 按钮 padding，如 4px 16px */
--ref-btn-radius:    /* 按钮圆角 */
--ref-input-height:  /* 输入框高度，如 32px */
--ref-sidebar-width: /* 侧边栏宽度，如 220px */
```

**逐项检查要求**：
- 截图里有什么就提取什么，**不要凭空编造不存在的值**
- 颜色值用取色器逻辑近似匹配：从截图肉眼判断主色 → 对照常见色值表给出最接近的标准色值
- 如果截图中某些样式看不清楚或不存在（如没有表格），提取表中对应项标注为 `N/A（参考图中未出现）`
- 按钮、表格、弹窗、导航、输入框等组件，**逐个截图比对**

#### 0.3 提取后的输出格式

提取完成后，必须以如下格式输出一份**可执行规范摘要**，作为后续原型生成的直接依据：

```
📐 从参考图提取的设计规范摘要

主色: #1677ff | 背景: #f0f2f5 | 文字: #262626
字体: PingFang SC 14px | 圆角: 6px | 阴影: 0 2px 8px rgba(0,0,0,0.08)

组件样式:
- 导航栏: 高度56px, 白色背景, 底部1px边框
- 筛选区: 白色卡片, 圆角8px, padding 20px
- 按钮: 蓝色填充(主色) / 白色边框(次), 圆角6px, 高度32px
- 表格: 表头灰底#fafafa, 行悬浮变灰, 条纹行交替
- 输入框: 高度32px, 边框#d9d9d9, focus蓝色边框+阴影
- 分页: 白色按钮+边框, active蓝色填充

样式复刻标注:
- 注释 #①: "搜索框样式复刻自参考图（圆角6px，高度32px，focus蓝色阴影框）"
- 注释 #⑤: "表格样式复刻自参考图（表头灰底#fafafa，行悬浮变色，12px表头字号）"
```

这个摘要必须**在图片读取完成后立即输出**，供用户确认是否符合预期。用户确认后再进入 Step 1。如果用户说"不对"或"有些颜色不对"，按用户反馈修正。

#### 0.4 无参考图时的默认设计系统

当没有参考图时，使用以下 Ant Design 5.x 默认值（作为 `:root` CSS 变量注入）：
- 主色: #1677ff | 成功: #52c41a | 警告: #faad14 | 危险: #ff4d4f
- 背景: #f5f5f5 | 卡片背景: #ffffff
- 文字主色: #262626 | 次要: #595959 | 辅助: #8c8c8c
- 边框: #d9d9d9 / #f0f0f0
- 圆角: 6px (组件) / 8px (卡片)
- 字号: 12px(辅助) / 14px(正文) / 16px(副标题) / 18px(标题)
- 阴影: 0 1px 2px rgba(0,0,0,0.06) (默认) / 0 4px 12px rgba(0,0,0,0.08) (hover)

### 输出模式选择
| Input Type | Mode | Output |
|-----------|------|--------|
| **全新需求 (0→1)** | 完整模式 | HTML原型 + 完整注释 + 右侧注释面板 + 框选工具 |
| **小功能迭代** | 轻量模式 | HTML原型 + 精简注释（只标注变更点）+ 版本标注栏 |
| **参考图+复刻** | 复刻模式 | CSS变量注入 → 严格对齐样式 → HTML原型(已对齐参考图) + 复刻标注注释(type:note,标注样式来源) |
| **局部修改** | 修改模式 | 定位框选区域 → 更新对应组件 + 更新/新增注释 → 版本号升级（**执行前必须先读下方「修改模式执行前必读」门禁**） |
| **原型→输出PRD** | PRD输出模式 | 读取原型HTML → 提取注释数据 → 分类映射 → 输出完整需求规格说明书(.md) |
| **原型→输出精简PRD** | 精简PRD模式 | 读取原型HTML → 提取注释数据 → 输出变更需求说明(.md) |

#### 🔒 修改模式执行前必读（强制门禁）

进入「局部修改 / 框选修改 / 修改模式」时，**动手改 HTML 前必须逐条核对下表**；未核对完不得直接编辑组件。下表把「Step 4: Handle Iteration / Selection-Based Modification」的修改执行规则提前为强制项：

| # | 修改模式 4 步 | 执行要求 |
|---|--------------|---------|
| 1 | 升版本号 | 版本号递增（V1.0 → V1.1 → V1.2…），不得漏升。**浏览器内框选确认修改时框架自动升版**（工具条「📜 版本」可查台账）；AI 直接改 HTML 文件时仍须手动升版 |
| 2 | 加/改注释 | 修改区域对应的标注卡**更新或新增**：只写"改了啥 + 为什么改"（≤3 行），未改区域不添注释 |
| 3 | 高亮标记 | 被修改的区域用**高亮边框**标记修改后的区域 |
| 4 | 更新版本标注栏 | 页面顶部版本标注栏新增一条变更记录（含版本号与日期）。**版本标注栏容器统一用 `id="aptVersionBar"`（或 `data-apt-version-bar`），框选确认时框架自动追加记录**；AI 直接改文件时手动追加 |

> **门禁判据**：四条全部完成才允许交付更新后的 HTML；漏掉任一条视为修改未完成，须补齐后重新交付。
>
> **v1.2 框架代管版本号**：框选确认修改时，框架已自动完成「升版本号 + 记录版本台账 + 保存页面快照」，AI 只需补齐注释与高亮，并把请求文本中的 `version` 字段同步进 HTML 文件（aptVersion 标注 + 版本标注栏，**不要重复升号**）。工具条「📜 版本」可查看台账、导出快照文件（Chrome/Edge 可直选保存位置，建议存进产品库 `详细设计/原型/` 过程文件夹）、回退（有快照 → 新标签打开该版本快照；无快照 → 生成回退指令粘贴给 AI）。localStorage 不可用（file:// 下常见）时自动降级为会话内存。**直接改文件（非框选路径）仍按门禁手动执行 4 步**。
>
> **v1.5 快照落盘约定**：AI 每次迭代落盘交付新版本前，先把**当前（修改前）版本**另存为 `<简称>-原型-vX.X.html` 快照文件写入产品库 `详细设计/原型/`（过程文件夹），与新版并存 —— 项目文件夹里的快照文件才是正式版本史（可进 git），浏览器导出/下载只是应急通道。

#### 轻量模式规则 (小功能迭代)
1. 页面顶部显示"版本标注栏"：`[v1.1 - 2026-06-12] 新增/修改/删除`
2. 只用注释标注变更部分，未改区域不添加注释
3. 每个注释只写：**改了啥** + **为什么改**，3行以内
4. 不输出任何文档，不输出流程图
5. 版本号递增（V1.0 → V1.1 → V1.2...）

#### 完整模式规则 (0→1)
- 每个功能区域至少覆盖：交互说明 + 业务逻辑 + 边界异常
- 有权限拆解的，额外添加权限规则注释
- 复杂业务逻辑（≥3步流程）在页面底部生成 Mermaid 流程图

### Step 1: Requirement Analysis

Before building the prototype, analyze:

1. **用户角色 & 权限**：区分管理员/运营/用户/访客 → 后续转为权限注释
2. **使用场景**：用户在什么情况下访问此页面，要达到什么目的
3. **页面结构**：导航/侧边栏/内容区/弹窗/底部
4. **功能模块**：列表/筛选/表单/操作按钮/详情弹窗
5. **操作链路**：用户从进入到完成的核心路径
6. **边界场景**：空数据/加载态/错误态/权限不足 → 后续转为边界异常注释

### Step 2: 参考图样式已在前序提取

执行到这一步时，参考图提取已在 **Step 0** 完成。如果 Step 0 判定有参考图并完成了提取：
- 本步骤跳过（提取的 CSS 变量已在 Step 0 输出并确认）
- 转到 **Step 3** 直接用提取的样式构建原型

如果 Step 0 判定无参考图：
- 本步骤也跳过，使用 Step 0.4 中的默认 Ant Design 样式
- 转到 Step 3

### Step 3: Build the Interactive HTML Prototype

Follow the template pattern in `references/prototype-guide.md`. The output is a single self-contained HTML file.

#### Build Sequence

**Phase 0 — 框架嵌入**：
1. 读取 `assets/prototype-framework.js` 文件内容
2. 将内容直接内联到 HTML 的 `<script>` 标签中（不使用 data URI）
3. 框架脚本必须放在**所有其他脚本之前**，且在 `</body>` 之前

**Phase A — Layout & UI**:
1. **CSS 变量注入（关键）**：
   - 如果 Step 0 提取了参考图样式 → 在 HTML 的 `:root` 中注入 `--ref-*` CSS 变量，**所有组件样式使用这些变量值，而非 Ant Design 默认值**
   - 如果没有参考图 → 使用 Step 0.4 的 Ant Design 5.x 默认值注入 `:root`
   - **禁止做法**：有参考图但不使用提取的值，仍然用 Ant Design 默认样式
2. Build the visual layout (navigation, sidebar, content area, footer) using the injected CSS variables
3. Implement all UI components with proper CSS based on the design system (extracted reference styles OR Ant Design defaults)
4. Add interactivity: tab switching, modal open/close, pagination, form interactions
5. For PC prototypes, use fixed 1440px width container or full-width responsive
6. **⚠️ 多页面原型编码规范（当原型包含多个页面时）**：
   - 每个页面用 `<div class="page-section" id="pageXxxName">` 包裹，默认只有第一个页面有 `active` class
   - 页面切换 CSS 规则：`.page-section { display: none !important; }` `.page-section.active { display: block !important; }`
   - 页面切换 JS：在侧边栏/Tab 的点击事件中，先移除所有 `.page-section` 的 `active` class，再给目标页面加上 `active` class，然后**调用 `window.__setActivePage('pageXxxName')` 通知注释引擎切换页面**
   - 同时暴露 `window.__switchToPage = function(pageId) { ... 切换DOM ...; window.__setActivePage(pageId); }` 供注释引擎的 `__focusAnnotation` 调用（当用户点击面板中属于其他页面的注释时，自动跳转到该页面）
   - **⚠️ 多屏并排展示模式（Side-by-Side）**：当多个页面需要同时可见时（如登录+注册两个手机并排展示），**不要用 `display: none` 隐藏页面**，而是：
     - 所有页面同时有 `active` class（都 `display: block`）
     - 页面间用 flex 横向排列（如 `display: flex; gap: 60px;`）
     - 页面切换（如"立即注册"→"返回登录"）用 `scrollIntoView({ behavior: 'smooth' })` 滚动定位，而非隐藏/显示
     - 注释注册前调用 `window.__setMultiScreenMode(true, { 'pageLogin': '📱 登录页', 'pageRegister': '📲 注册页' })` 启用多屏模式
     - 多屏模式下注释面板自动显示页面筛选 Tab（全部/登录页/注册页）+ 二级分组（页面→类型）
     - 点击面板注释时自动滚动到对应页面元素，不再切换页面显示/隐藏
     - **代码模板**：
       ```js
       // 启用多屏模式（在注释注册之前调用）
       window.__setMultiScreenMode(true, {
         'pageLogin': '📱 登录页',
         'pageRegister': '📲 注册页'
       });
       // 注册注释时仍用 __setActivePage 设置当前页面，注释自动归属
       window.__setActivePage('pageLogin');
       window.__addAnnotationOn('#loginPhone', 'right', { title: '...', description: '...', type: 'interaction' });
       window.__setActivePage('pageRegister');
       window.__addAnnotationOn('#regPhone', 'right', { title: '...', description: '...', type: 'interaction' });
       // 注册完毕后不需要切回默认页面（多屏模式下页面切换不影响显示）
       ```

**Phase B — Annotations**:
1. Review every functional area on the page
2. For each area decide what types of annotations are needed (interaction/business/edgecase/permission)
3. Register annotations using **`window.__onAnnotationsReady`** 回调函数（**禁止使用 DOMContentLoaded**，因为框架初始化顺序存在竞争关系）：
   - **`__addAnnotation({ x, y, ... })`** — 手动指定视口坐标 (通用模式)
   - **`__addAnnotationOn(selector, position, opts)`** — 相对目标元素自动定位 (推荐模式)
   - **`opts.page`** — 注释所属页面 ID（多页面原型时使用，默认为当前活跃页面）
4. 注释注册代码推荐使用**轮询等待模式**（替代原 `__onAnnotationsReady` 回调方式，避免 DOMContentLoaded 时序竞争）：
```js
(function() {
  function register() {
    if (typeof window.__addAnnotationOn !== 'function') {
      setTimeout(register, 50);  // 每50ms重试，直到框架就绪
      return;
    }
    // 框架就绪，开始注册注释
    // ⚠️ 多页面原型：先用 __setActivePage 设置当前页面，再注册注释（注释自动归属当前页面）
    window.__setActivePage('pageShiftSettings');
    window.__addAnnotationOn('#target-selector', 'right', {
      title: '注释标题',
      description: '注释内容',
      type: 'business'
      // page 参数会自动取当前活跃页面，无需手动指定
      // 如果需要全局注释（所有页面可见），显式设置 page: null
    });
    // 切换到另一个页面注册注释
    window.__setActivePage('pageAttendanceRecord');
    window.__addAnnotationOn('#another-selector', 'left', {
      title: '另一个页面的注释',
      description: '这个注释只属于考勤记录页面',
      type: 'interaction'
    });
    // 注册完毕后，切回默认页面
    window.__setActivePage('pageShiftSettings');
  }
  register();
})();
```
   - **多页面原型注释分组规则**：
     - 注册注释前先调用 `__setActivePage('pageId')` 设置当前页面，后续注册的注释自动归属该页面
     - 注释的 `page` 属性为 `null` 时视为全局注释，所有页面都可见
     - **传统多页模式**（页面切换隐藏/显示）：页面切换时调用 `__setActivePage(newPageId)`，框架自动隐藏/显示注释标记和面板内容
     - **多屏并排模式**（页面同时可见）：调用 `__setMultiScreenMode(true, { pageId: '标签' })` 后，面板显示页面筛选 Tab + 二级分组；点击面板注释滚动定位到目标元素，不切换页面
     - 在右侧面板中，传统模式只显示当前页面的注释；多屏模式默认显示全部注释（可按 Tab 筛选单页）
   - **拖拽标记**：按住注释标记（圆形徽章）拖拽即可重新定位
   - **删除注释**：在右侧注释面板中，每项注释末尾的✕按钮可删除注释（卡片上不提供删除按钮以避免事件冲突）
   - **展开卡片**：注释卡片标题栏⛶按钮可展开/缩小卡片（180px↔600px）
   - **双击编辑**：双击注释描述区域可编辑内容
   - **添加注释**：工具栏"➕添加注释"模式，点击页面任意位置创建新注释

**Phase C — Selection Tool**:
1. The framework automatically includes the marquee selection tool
2. It appears in the toolbar automatically — no extra code needed

#### Annotation Coverage Rules

| Component Type | Required Annotation Types | 补充要求 |
|---------------|--------------------------|---------|
| Search input | interaction, edgecase(empty result) | 说明搜索的数据范围和匹配规则 |
| Data table / List | interaction(pagination/sort), business(sorting logic), edgecase(empty/error) | 必须包含【数据来源】【排序规则】【字段字典】 |
| Form / Modal | interaction(fields/validation/submit), edgecase(error/duplicate/timeout) | 必须列出所有字段的名称、类型、格式、必填/选填 |
| Buttons (add/edit/delete) | interaction(click flow), business(data rules), permission(who can see/click) | 说明触发条件、后置影响、失败处理 |
| Navigation menu | interaction(route), permission(menu visibility per role) | — |
| Approval workflow / Timeline | business(flow), permission(approval role), edgecase(reject/recall) | 必须说明数据来源（完整预定义节点 vs 仅已流转）、排序规则（正序/倒序）、每个节点的字段组成 |
| Charts / Statistics | business(data source/calculation), edgecase(no data) | 说明数据计算逻辑和统计口径 |
| Upload component | interaction(drag/click), edgecase(file type/size/network) | — |
| Permission-restricted area | permission(role-based), edgecase(no access state) | — |
| Detail card / Form display | interaction, edgecase(empty/error) | 必须列出所有展示字段的字段清单 |

#### Annotation Quality Standards (注释质量标准)

每条注释必须遵循 **「三个问题」原则**：回答"数据从哪来"、"按什么排序"、"字段有哪些"。

**核心检查清单：**

1. **数据逻辑检查**（business/edgecase 类型）
   - [ ] 数据来源：静态预定义还是动态查询？是否支持分页？
   - [ ] 数据范围：展示全部数据还是按条件过滤？过滤条件是什么？
   - [ ] 排序规则：默认排序字段？升序还是降序？用户能否自定义？
   - [ ] 字段定义：每条数据包含哪些字段？各自的类型、格式、必填/选填？

2. **交互行为检查**（interaction 类型）
   - [ ] 触发条件：什么条件下可操作？是否需要权限？
   - [ ] 处理流程：点击后发生了什么？有无确认弹窗？
   - [ ] 后置影响：操作完成后数据/页面状态如何变化？
   - [ ] 失败处理：网络超时、权限不足、数据冲突时如何提示？

3. **边界情况检查**（edgecase 类型）
   - [ ] 空数据态：无数据时页面显示什么？
   - [ ] 加载态：数据加载中显示什么？
   - [ ] 错误态：接口报错时如何展示？
   - [ ] 异常流转：暂停、驳回、撤回等异常状态如何处理？

**注释内容格式规范：**

使用结构化段落，每条注释的 `description` 按以下模板组织：

```
【数据逻辑】数据来源 + 数据范围说明
【排序规则】排序依据 + 升序/降序
【字段组成】字段1 + 字段2 + ...（各字段的格式说明）
【业务规则】触发条件 → 处理流程 → 结果/输出
【边界异常】异常条件 → 系统行为 → 用户感知
```

**禁止行为：**
- ❌ 只写视觉表现不写逻辑（如"已完成绿色，当前蓝色"→ 缺少数据来源和排序规则）
- ❌ 字段说明模糊（如"展示审批记录" → 应明确列出所有字段）
- ❌ 遗漏 edgecase 注释（数据展示类组件必须有空数据/错误态注释）

**⚠️ 关键编码约束 —— description 字段换行转义（已出现多次生产事故）：**

注释注册代码嵌入在 HTML 的 `<script>` 标签中，所有 `description` 字符串必须使用 **JavaScript 单引号字符串**。单引号字符串内不允许包含未转义的**实际换行符**（即按下回车产生的 `\n`），否则会导致整段 `<script>` 解析失败，注释引擎和页面交互全部失效。

| 错误写法（导致脚本崩溃） | 正确写法 |
|---|---|
| `description: '第一行`<br>`第二行'` | `description: '第一行\n第二行'` |
| `description: '【业务】xxx`<br>`【异常】yyy'` | `description: '【业务】xxx\n【异常】yyy'` |

**生成 HTML 时的强制检查**：在输出最终 HTML 之前，必须确保 `<script>` 标签内所有单引号字符串中没有裸换行。如果 description 内容本身包含多行，**必须将实际换行替换为 `\n` 转义序列**。

#### Interaction Fidelity

| Interaction | Minimum Fidelity |
|-------------|-----------------|
| Tab switching | Content switches, active tab highlighted |
| Modal/Drawer | Opens/closes with animation, proper backdrop |
| Dropdown/Select | Options appear, clickable to select |
| Pagination | Page numbers clickable, "prev/next" works |
| Form validation | Required fields show red border + error on submit |
| Hover effects | Buttons, table rows, cards have hover states |
| Toast/notification | Appears briefly, dismissible |
| Expand/Collapse | Animates smoothly |

### Step 4: Handle Iteration / Selection-Based Modification

> 🔒 **进入修改执行前，先核对「输出模式选择」下方的「修改模式执行前必读」门禁**（升版本号 → 加/改注释 → 高亮标记 → 更新版本标注栏）。以下为完整执行流程：

The selection tool captures user modifications and returns them via clipboard + visual panel. Here is the complete workflow:

1. **用户操作**：用户点击工具栏"✂️ 框选模式"，在页面上拖拽框选要修改的区域，填写修改描述，点击"确认修改"
2. **框架处理**：框架自动将框选区域坐标 + 修改描述 + 时间戳格式化为结构化文本，尝试复制到剪贴板，同时在页面中央弹出一个"框选修改请求已就绪"面板。**v1.2：确认修改时框架自动升版（V1.0→V1.1…），版本号写入请求文本与版本台账，并尝试保存页面快照**
3. **用户回传**：用户将修改请求文本粘贴到对话框发送给 AI（面板上有"复制修改请求并发送给AI"按钮）
4. **AI 接收处理**：当收到用户粘贴的框选修改请求后：
   - 解析请求中的区域坐标和修改描述
   - 根据坐标判断该区域包含哪些组件（导航栏/表单/表格/弹窗等）
   - 根据修改描述理解具体的修改意图
5. **AI 执行修改**：
   - 定位到目标 HTML 组件
   - 更新目标组件的 HTML/CSS/JS 内容
   - 新增或更新该区域对应的注释（更新注释内容，或新增注释）
   - 同步版本：把文件内 aptVersion 标注与顶部版本标注栏更新为**请求文本中的版本号**（框选确认时框架已在浏览器内自动升版并记台账，直接沿用即可，**不要重复升号**）
   - 框选区域用高亮边框标记修改后的区域
6. **重新交付**：保存更新后的 HTML 文件，在回复中给出其绝对路径，让用户打开查看

**重要**：框选工具的输出是**结构化文本消息**，必须由用户粘贴回对话框才能让 AI 执行修改。这是前端 → AI 之间的数据桥接机制。

### Step 5: Multi-Platform Adaptation

Auto-detect target platform from user input. If not specified, default to PC Web.

| Platform | Layout | Interactions | Notes |
|----------|--------|-------------|-------|
| PC Web | 1440px container, sidebar+content | hover, click, pagination | Default |
| APP | 375-414px width, single column | tap, swipe, bottom sheet | Touch targets ≥44px |
| Mini Program | 375-414px, native navbar | tap, no hover | WeChat design rules |
| H5 | Responsive, safe-area | tap, no hover | Performance priority |

### Step 6: PRD 输出（按需触发）

当用户要求输出需求文档/PRD/需求规格说明书时，执行以下流程。

#### 6.1 注释→PRD 映射规则

原型中的每条注释按 type 映射到 PRD 的不同章节：

| 注释类型 | 映射到 PRD 章节 | 映射产物 |
|---------|----------------|---------|
| `interaction` | 功能需求详述 + 页面交互说明 | 功能条目 + 操作流程 + 交互规格表 |
| `business` | 业务流程 + 功能需求详述 | 业务规则 + 状态流转 + 数据逻辑 |
| `edgecase` | 功能需求详述(边界与异常) + 边界与异常处理 | 异常列表 + 处理策略 |
| `permission` | 用户角色与权限 | 权限矩阵条目 + 角色定义 |
| `note` | 附录 / 数据字典 | 备注说明 / 待确认事项 |

#### 6.2 PRD 生成执行流程

1. **定位原型文件**：
   - 如果用户指定了文件名 → 直接读取
   - 如果用户未指定 → 用 Bash 搜索最近生成的 `.html` 原型文件（例如 `find <项目目录> -name '*.html' -printf '%T@ %p\n' | sort -rn | head`，或按修改时间排序取最新的）

2. **提取注释数据**：从 HTML 中扫描所有 `__addAnnotationOn(` 和 `__addAnnotation(` 调用，提取每条注释的：
   - id（编号）
   - title（标题）
   - description（描述）
   - type（类型）
   - targetSelector（关联的页面元素/组件）

3. **分类整理**：按 type 分组，判断每个功能所属的业务模块

4. **补充需求分析**：结合 Step 1 中的需求分析结果（用户角色、使用场景、页面结构、操作链路、边界场景）

5. **选择模板**：
   - 用户要求"完整/详细/全面"PRD → 使用完整 PRD 模板
   - 用户要求"精简/简要/快速"PRD → 使用精简 PRD 模板

6. **输出文档**：按 `references/prd-template.md` 中的模板填充，生成 `.md` 格式文件

7. **保存并交付**：保存到项目目录，在回复中给出生成的 `.md` 文件绝对路径交付给用户

## Bundled Resources

- `assets/prototype-framework.js` — The annotation engine + selection tool + panel (v1.2). **新增多屏并排展示模式（v1.1）+ 版本管理与回退（v1.2）**：`__setMultiScreenMode(enabled, pageLabels)` 启用后，注释面板自动显示页面筛选 Tab + 二级分组（页面→类型），点击注释滚动定位而非切换页面。**嵌入方式：在生成的 HTML 中将该文件内容直接内联到 `<script>` 标签中，不使用 data URI（避免部分浏览器对 data URI 脚本的限制）**
- `assets/prototype-framework.js` **v1.2 版本管理与回退**：框选确认修改自动升版（V1.0→V1.1…）+ 本地版本台账 + 页面快照保存；工具条「📜 版本」可查看台账 / 导出快照文件 / 回退（有快照 → 新标签页打开该版本；无快照 → 生成回退指令粘贴给 AI）。localStorage 不可用（file:// 下常见）时自动降级为会话内存，不影响既有交互
- `references/prototype-guide.md` — Complete guide for building prototypes: template structure, annotation API, design system specs, interaction fidelity rules, multi-platform adaptation, and reference extraction guide.
- `references/prd-template.md` — Requirements Specification Document (PRD) template referencing Tencent, Alibaba, JD.com formats. Includes full PRD and lightweight PRD templates, annotation-to-PRD mapping rules, and generation workflow.
