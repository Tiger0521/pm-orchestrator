# Step 2 工作流：原型设计与规范对齐

本文件是 Step 2 的唯一执行流程。基于已定稿的 Step 1 产出（业务流、页面映射、两张 HTML 图），生成可交互原型，对齐 UI 规范，确认主干体验。

**职责边界**：本文件只管 Step 2 执行流程。grilling 决策域与推导域见 `../shared/grilling-protocol.md` 第 3.2/4.2 节；原型生成方式（统一为交互式 HTML）见 `prototype-method.md`；标注层规范见 `annotation-overlay.md`；UI 风格与 office-hours 结构借鉴见 `ui-design-style.md`；风格预设见 `ui-style-presets/`；确认方法见 `../shared/confirmation-method.md`；设计自检见 `../shared/design-review.md`；产出字段见 `../shared/output-contract.md`；落盘步骤见 `../shared/persist-guide.md`。

---

## 1. 前置依赖（硬门禁）

- Step 1 已定稿：业务流文档、页面映射文档均已用户确认，两张 HTML 图已生成并被确认
- 读取 Step 1 定稿产物作为设计输入：页面映射表（页面清单、层级、关联 Story）、业务动线
- 前置不满足时返回 `needs-input`，不得跳过 Step 1 直接设计原型

## 2. 执行步骤

1. **读取前置**：Step 1 定稿产物（页面映射表、业务动线、两张 HTML 图）。页面清单、层级、Story 归属是推导域，直接沿用不问（见 `../shared/grilling-protocol.md` 第 4.2 节）
2. **grilling 敲定决策域**：按 `../shared/grilling-protocol.md` 第 3.2 节逐轮敲定，每轮一问，收敛判据见协议第 6 节：
   - 目标平台：六选一（Web Dashboard / Web Landing / Web App / Mobile App / Mini Program / Admin Backend），平台说明见 `ui-design-style.md` 第 3.1 节
   - UI 风格预设：基于已选平台给出 5 个最匹配的候选（触发条件成立时读取 `ui-style-presets/` 下对应预设文件），见 `ui-design-style.md` 第 3.4 节
   - 核心页面布局模式：每类核心页面用方案对比题裁决（列表页表格 vs 卡片、详情页标签页 vs 长页滚动、表单弹窗 vs 独立页 vs 分步向导）
   - 组件复用范围、布局与 Step 1 层级冲突：有歧义时问，无歧义由 agent 建议后随草案确认

   原型生成方式固定为交互式 HTML（唯一方式，见 `prototype-method.md` 第 1 节），不进入 grilling 决策域、不询问。
3. 决策域收敛后，按交互式 HTML 方式执行（路由本目录内嵌的 `pm-prototype-prd` 技能，见 `prototype-method.md` 第 2 节）
4. 为每个页面生成原型草案，按变更规模（change-scope）区分产出深浅：
   - **新页面 / 完整新模块**：对核心页面采用"问题 -> 方案对比 -> 推荐 -> 成功标准"结构（office-hours 结构借鉴，见 `ui-design-style.md` 第 1 节），包含全套内联标注；对非核心页面简化为"问题 -> 推荐方案"
   - **日常小优化**（加字段、改文案、调样式、挪位置）：只更新原型 HTML + 对应标注卡，不重写流程说明、不堆长文。在草案中显式标注"按小优化处理，如需完整流程说明请说明"
   - 原型均包含页面布局、元素说明表、异常状态、组件复用标注、UI 规范引用。必备要素见 `prototype-method.md` 第 5 节
5. 执行设计自检。设计审查机制的五个维度（完整性/一致性/可实施性/复用性/边界覆盖）见 `../shared/design-review.md`，不通过的自行修正
6. 输出完整原型草案预览（结构化草稿数据块，含确认状态追踪，格式见 `../shared/output-contract.md` 第 4 节）

## 3. 如何询问

- grilling 决策域按 `../shared/grilling-protocol.md` 第 3.2 节逐轮敲定，每轮一问：先问目标平台（六选一），再问 UI 风格预设（基于已选平台给 5 个候选），再逐类裁决核心页面布局模式（原型生成方式固定为交互式 HTML，不询问）
- 推导域（页面清单、层级、Story 归属、空/加载/错误态枚举）直接沿用或机械展开，不问（见协议第 4.2 节）
- 原型草案生成后，按每轮一个问题确认

## 4. 提供什么选择

- **目标平台选择**：A. Web Dashboard / B. Web Landing / C. Web App / D. Mobile App / E. Mini Program / F. Admin Backend + 补充描述 + 强制跳过。平台说明见 `ui-design-style.md` 第 3.1 节
- **UI 风格预设选择**：基于已选平台给出 5 个最匹配的预设 + 补充描述 + 强制跳过。提问格式见 `ui-design-style.md` 第 3.4 节
- **核心页面布局方案对比**：A. 方案一 / B. 方案二 + 补充描述 + 强制跳过。方案对比示例见 `ui-design-style.md` 第 1 节

## 5. 用户确认点

- 展示完整原型草案（含布局示意、元素说明、异常状态、组件复用）
- 给出理解回执（原型方式：交互式 HTML、风格预设、覆盖页面数）
- 提出"以上原型方案（含布局、交互说明、异常状态）是否符合预期？需要调整哪些页面的设计？"

## 6. 产出

产出固定为交互式 HTML 方式（产出物见 `prototype-method.md` 第 1 节）：带标注层的自包含 HTML 成为主交付物、原型即文档；独立的交互说明文档（`详细设计/原型/<简称>-原型交互说明.md`）降为可选导出（从同一份 proto JSON 渲染，给需要离线文档的场景留出口）：

| 主交付物 | 交互说明文档中的布局示意 |
| ---- | ---- |
| 自包含 HTML 文件（含标注层，预览态/标注态同一份） | 文件路径 + 标注层开关说明 |

**主交付物落盘**：HTML 文件（`<简称>-原型.html`，含标注层）用 Write 工具直接写入产品库 `详细设计/原型/` 目录（与 Step 1 两张 HTML 图同机制，不走 JSON + render-doc.sh）。

**交互说明文档落盘**：为可选导出（用户需要离线 md 时从同一份 proto JSON 用 `render-doc.sh` 渲染）。落盘步骤见 `../shared/persist-guide.md` 第 3 节，产出字段见 `../shared/output-contract.md` 第 1.3 节。

## 7. 质量门

- 核心页面原型已覆盖
- 每个页面包含布局说明和元素说明
- 关键交互元素有明确说明（表格形式或内联标注卡）
- 异常状态有展示方案（空状态、加载中、错误状态各有具体文案）
- 组件复用已标注
- UI 规范已引用（如有设计系统）或标注"无已有设计系统"
- 原型生成方式已记录（统一为交互式 HTML）
- 交互式 HTML 文件已写入产品库 `详细设计/原型/` 目录，含标注层（预览态/标注态可切换）
- 交互式 HTML 的交互真跑：按钮可点击、弹窗能开能关、筛选实时生效、表单有前端校验、列表三态切换（见 `prototype-method.md` 第 2.3 节）
- 多页一致性：导航逐字粘贴、App Shell 字节一致（见 `prototype-method.md` 第 2.2 节）
- 核心页面有方案对比记录
