# 原型生成方式

> 本文件只在 Step 2（原型设计与规范对齐）执行前加载。定义原型生成方式（统一为交互式 HTML）的适用场景、执行步骤、局部迭代与参照截图路由。
>
> 本文件只管原型生成方式。Step 2 流程见 `workflow.md`；标注层规范见 `annotation-overlay.md`；UI 风格预设见 `ui-design-style.md`；产出字段定义见 `../shared/output-contract.md`。

原型不是画画，是定义交互。原型文档需要包含页面布局、每个元素的交互说明、组件复用标注、UI 规范引用和异常状态展示。

---

## 1. 原型生成方式（统一为交互式 HTML）

**原型生成方式统一为交互式 HTML（唯一方式）**：AI 直接生成自包含 HTML/CSS/JS，浏览器打开即可点击交互（按钮/弹窗/筛选/表单/状态切换真跑），页面上直接打编号+引线标注，支持框选局部迭代、可参照现有系统截图对齐风格。无需外部账号和联网、主交付物即原型本身。不再提供外网 Stitch、墨刀等外部工具方式，subagent 无需询问用户选择原型生成方式，直接按第 2 节执行。

| 产出物 | 说明 |
| ---- | ---- |
| 主交付物 | 自包含 HTML 文件（含标注层，预览态/标注态同一份），用 Write 工具写入产品库 `详细设计/原型/` 目录 |
| 可选导出 | 交互说明文档（`详细设计/原型/<简称>-原型交互说明.md`），用户需要离线 md 时从同一份 proto JSON 渲染 |

---

## 2. 执行步骤（路由内嵌 pm-prototype-prd）

原型生成统一路由到本目录自包含内嵌的 `pm-prototype-prd` 技能（`pm-prototype-prd/SKILL.md`），按其 **Path B → 原型生成流程 Step 0 → Step 1 → Step 3 → Step 4** 执行：直接生成带墨刀式页面内联标注的自包含 HTML，不输出业务需求文档、不输出 PRD。构建指南见 `pm-prototype-prd/references/prototype-guide.md`；标注引擎为 `pm-prototype-prd/assets/prototype-framework.js`（内联进 HTML）；局部迭代走第 3 节。

### 2.1 前置条件

- 用户已选择 UI 风格预设（见 `ui-design-style.md` 第 3 节），或提供了自定义风格描述/参照截图
- Step 1 页面映射表已定稿，提供页面清单、层级和 Story 归属

### 2.2 执行步骤

1. **进入 pm-prototype-prd Path B**：读取 `pm-prototype-prd/SKILL.md`，不触发 Path A（业务需求文档）、不输出 PRD；从「原型生成流程」Step 0 起执行。
2. **Step 0 参考图检测**：
   - 用户在本 step2 会话里已选 UI 风格预设（`ui-style-presets/`），或提供了自定义风格/参照截图/原系统截图 → 视为参考图已命中，跳过读图与「询问参考图」
   - 仅当用户明确要求"另换风格/不用预设"时才重新走读图提取
3. **Step 1 需求分析**：基于 Step 1 定稿的页面映射表与关联 Story，明确角色/权限、使用场景、页面结构、功能模块、操作链路、边界场景。
4. **冻结设计输入**（对齐本 step2 存量，映射进 pm-prototype-prd 的 `:root` CSS 变量）：
   - **design tokens**：从用户选的 `ui-style-presets/` 预设文件提取主色/中性色阶/字号/圆角/间距/阴影，注入 HTML `:root` 的 CSS 变量（`--primary-color`、`--bg-color`、`--radius` 等，映射见 `ui-design-style.md` 第 3.5 节）。禁止在 CSS 中硬编码色值/圆角/字号
   - **组件规格**：统一按钮/输入框/卡片/表格/弹窗/导航侧栏的样式和状态，规格取自预设文件的"组件风格"表
   - **App Shell + 规范导航**（多页必选）：冻结唯一骨架（静态 HTML shell + 导航/侧栏/顶栏），所有 `.page-section` 页逐字粘贴此 shell，只填主内容槽。这是多页导航不漂移的根因保障
   - **页面清单**：信息架构 + 每页职责 + 页间路由/导航；多页用 `page-section` + `__setActivePage`（多屏并排用 `__setMultiScreenMode`）
   - **mock schema**：统一假数据结构（内联 JSON），不调真实后端
5. **构建交互式 HTML**（pm-prototype-prd Step 3）：
   - **Phase 0 框架嵌入**：把 `pm-prototype-prd/assets/prototype-framework.js` 内容直接内联进 HTML 的 `<script>`（放在 `</body>` 前、其他脚本之前），不使用 data URI
   - **Phase A 布局**：按 `:root` CSS 变量构建页面；实现交互（Tab 切换、弹窗开关、分页、表单校验、三态）
   - **Phase B 标注**：用 `__addAnnotationOn(selector, position, opts)` 给关键交互元素打墨刀式标注（interaction/business/edgecase/permission/note），注册走轮询等待模式（`typeof window.__addAnnotationOn === 'function'` 就绪后再注册）。description 用单引号字符串并转义换行为 `\n`（避免 `<script>` 解析崩溃）。标注引擎规范与 API 见 `annotation-overlay.md` 与 `pm-prototype-prd/references/prototype-guide.md`
   - **Phase C 框选工具**：框架自动含框选迭代工具，无需额外代码
6. **静态自检**（pm-prototype-prd 的交互保真与质量标准）：
   - 导航完整性：每页含逐字粘贴的 App Shell + Nav，导航 markup 逐页字节一致
   - 交互真跑项核对（见 2.3）、所有链接指向真实文件/锚点（无 404）、无重复 id、无未定义 mock/state 变量、无未绑定事件处理器
   - 标注覆盖 check（数据逻辑/交互行为/边界情况三问），`<script>` 内无裸换行
   - 只修明显缺陷，不重构可用代码；**不打开浏览器、不截图**（纯静态源码审查）
7. **交付**：将自包含 HTML 写入产品库 `详细设计/原型/` 目录（用 Write 工具直写，与 Step 1 两张 HTML 图同机制，不走 JSON + render-doc.sh）。交付物为内联框架的带标注自包含 HTML（预览态见干净原型、标注态显示编号+引线+标注卡+右侧面板）。

### 2.3 交互验收线（"真跑"标准）

交互式 HTML 的交互必须真跑，不是静态图。验收标准直接搬 pm-prototype-prd 的交互保真清单：

- 按钮可点击、弹窗能开能关
- Tab 切换内容联动、下拉可选、分页可翻
- 表单有前端校验（必填字段红框 + 提交报错）
- 列表有空/加载/错误三态切换
- mock 数据（内联 JSON），不调真实后端
- 多页一致性由 App Shell + 规范导航保证（导航逐字粘贴 + 只填主内容槽）

### 2.4 标注层

生成原型时按 `annotation-overlay.md` 规范用 `prototype-framework.js` 引擎（`__addAnnotationOn` 定位 + 右侧注释面板 + 框选工具）给关键交互元素打墨刀式标注。标注内容直接取自现有 `proto-*.json`（或 Step 2 草案）的"元素说明 + 异常状态 + 组件复用"字段，不新增数据结构。标注层完整规范（引擎嵌入、API、编号/引线/标注卡渲染、页面归属与多屏并排、与 proto JSON 字段映射）见 `annotation-overlay.md` 与 `pm-prototype-prd/references/prototype-guide.md`。

---

## 3. 局部迭代路由

当用户要求修改已有交互式 HTML 原型的某个区域时，走 pm-prototype-prd 的 **Step 4 框选修改 / 局部迭代**（`pm-prototype-prd/SKILL.md` 第 4 节）。核心原则：精准定位改动区域，局部重写，其余页面 1:1，不扩散。

### 3.1 触发信号

用户指明要改的区域（按模块/区块名，或描述"订单列表的筛选区"），而非整页重做。也可由原型页面上的「✂️ 框选模式」工具触发（用户在浏览器框选区域 → 生成结构化修改请求 → 回传 AI 解析执行）。

### 3.2 执行步骤

1. **定位模块边界**：agent 在 HTML 里定位到用户指明模块的 DOM 边界（靠 `data-ann` 锚点/被 `__addAnnotationOn` 绑定的 selector 或模块的语义化容器）
2. **只改选中区**：只重写这块的 HTML + CSS + 它对应的标注卡，其余 DOM、样式、标注逐字不动
3. **标注层同步**：只更新被改模块的编号和标注卡，未改模块的编号连号保持不变（用稳定锚点 selector 而非顺序号，避免改一处全页重排编号）；版本升号——浏览器内框选确认时框架自动升版并记台账（见内嵌 pm-prototype-prd 门禁下方「v1.2 框架代管」说明），AI 直接改文件时手动升号并同步 aptVersion 标注与版本标注栏
4. **静态自检**：按 §2.2 静态自检，重点验证未改区域的 App Shell + Nav 逐字一致

### 3.3 依赖

局部迭代依赖交互式 HTML 的模块化页面结构--每个页面只填主内容槽、组件是离散块，所以"只改一块"在结构上是可行的。框选迭代由 `prototype-framework.js` 内置（见 `pm-prototype-prd/references/prototype-guide.md`）。

---

## 4. 参照截图迭代路由

当用户提供现有系统的截图/URL，要求按原系统风格出原型或迭代时，走 pm-prototype-prd 的 **Step 0 参考图检测与提取**（`pm-prototype-prd/SKILL.md` 第 0 节）。

### 4.1 触发信号

用户给出截图/URL，要求"按这个风格做"或"参照现有系统改版"。

### 4.2 执行步骤

1. **抓取/读图**：用 Read 工具读取截图（或抓取 URL 页面），逐项提取视觉规范（颜色、字体、间距、圆角、组件样式）为 `:root` CSS 变量（`--ref-*` → 注入 `--primary-color` 等）
2. **提炼设计语言**：从截图/URL 中提炼视觉语言（颜色、字体、间距、圆角、组件样式），写入 HTML `:root` 的 design tokens（CSS 变量）字段
3. **存自定义预设**：将提炼出的 design tokens 落成一个自定义 `ui-style-preset` 文件（复用 `ui-style-presets/` 的文件格式），存进预设目录。一次截图提炼，后续页面都能复用这套参照风格（见 `ui-design-style.md` 第 3.6 节）
4. **跑实现**：按冻结的 tokens 执行 §2.2 构建流程，产物天然对齐原系统风格；用 `type: 'note'` 标注卡片在关键组件上标注"样式复刻自参考图"

### 4.3 与存量对接

`ui-design-style.md` 第 3.6 节已有"自定义风格"的口子（用户描述偏好就结合最近预设改 token），本路由把它从"用户口述偏好"扩到"用户给截图、agent 提炼 token"，是同一个机制的增强。注意：用户在 step2 会话里已选 `ui-style-presets/` 预设时，Step 0 视为已命中、直接复用预设 token，不重复读图。

---

## 5. 原型文档的统一正文结构

无论迭代几次，原型文档（proto-*.md）的正文结构一致：页面列表、每个页面的布局示意、元素说明表、异常状态、组件复用。交互式 HTML 方式的"布局示意"为 HTML 文件路径 + 标注层开关说明（预览态/标注态切换方式）。

### 5.1 必备要素

原型文档必须包含以下要素：

| 要素 | 说明 | 合格标准 |
| ---- | ---- | ---- |
| 页面布局 | 文字描述或 ASCII 示意 | 能让开发理解页面结构分区 |
| 元素说明 | 每个元素的类型、交互行为、反馈 | 用表格呈现，不遗漏关键元素 |
| 异常状态 | 空状态、加载中、错误状态 | 每种异常都有具体展示方案和文案 |
| 组件复用 | 哪些组件跨页面复用 | 标注复用组件名和使用页面 |
| UI 规范引用 | 如已有设计系统，引用对应规范 | 引用编号，不重复展开全文 |

**交互式 HTML 的特殊说明**：上述必备要素（元素说明、异常状态、组件复用）直接以内联标注卡的形式呈现在原型 HTML 上（见 `annotation-overlay.md`），独立的交互说明文档降为可选导出。