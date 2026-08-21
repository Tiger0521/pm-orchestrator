# UI 设计风格

本文件定义 Step 2（原型设计与规范对齐）的 UI 设计风格规则：office-hours 设计文档结构借鉴、设计系统引用规则、UI 风格预设体系和设计思维与反 AI-slop 设计哲学。只在生成原型草案时读取。

**职责边界**：本文件只管 UI 设计风格。Step 2 流程见 `workflow.md`；原型执行步骤见 `prototype-method.md`；确认方法见 `../shared/confirmation-method.md`；设计审查见 `../shared/design-review.md`；产出字段见 `../shared/output-contract.md`；写作规范见 `../shared/design-writing.md`。每个知识点只有一个权威来源；其他文件需要引用某规则时，只引用名称，完整定义在本文件中。

---

## 1. 借鉴 office-hours 设计文档结构

借鉴 office-hours skill 的 `design-and-handoff.md` 中设计文档的结构化方法论，将以下模式应用到每个页面的设计中：

| office-hours 设计文档要素 | 在详细设计中的对应应用 |
| ---- | ---- |
| Problem Statement（问题陈述） | 每个页面设计前先明确：这个页面解决用户的什么问题？承载哪些 User Story 的价值？ |
| Approaches Considered（方案对比） | 对核心页面，提供至少两种布局/交互方案供用户选择，不只有一个方案 |
| Recommended Approach（推荐方案） | 明确推荐哪个方案，并给出理由（用户动线最短、操作效率最高、异常兜底最完整等） |
| Open Questions（未决问题） | 标注设计中尚未确认的点，记录到 `tracking-log.md` |
| Success Criteria（成功标准） | 定义怎样算设计完成：所有 Story 有归属页面、所有交互有契约、所有异常有兜底 |

**应用方式**：subagent 在生成原型草案时，对每个核心页面采用"问题 -> 方案对比 -> 推荐 -> 成功标准"的结构。对于非核心页面（如简单的详情页），可简化为"问题 -> 推荐方案"。

**方案对比示例**：

```
页面：订单列表页

问题陈述：运营人员需要快速定位需要处理的订单，当前 Story US-Ord-01 要求支持搜索和筛选。

方案 A：顶部搜索栏 + 左侧筛选面板
- 优点：筛选条件可见，操作直觉
- 缺点：占用屏幕空间，列表区域变小

方案 B：顶部搜索栏 + 右侧抽屉式筛选
- 优点：列表区域最大化，筛选按需展开
- 缺点：筛选条件默认隐藏，新用户不易发现

推荐：方案 B，理由：运营人员高频使用搜索而非筛选，列表区域最大化更符合日常操作习惯。
成功标准：搜索结果 < 300ms 展示、空状态有引导、筛选可展开/收起。
```

---

## 2. 设计系统引用

如果产品库或项目中已有设计系统（如 Ant Design、Element Plus 或自研组件库），subagent 在生成原型时：

1. **优先引用已有组件**：不自行设计已有组件的样式，只标注"使用 XX 组件"
2. **标注复用关系**：哪些组件跨页面复用，在原型文档的"组件复用"章节统一标注
3. **不重复展开规范**：原型文档中只引用规范编号（如 `引用 Ant Design Table 组件`），不在文档中重复展开组件的 props 和样式

**无已有设计系统时的处理**：如果无已有设计系统，subagent 在原型文档中标注"无已有设计系统，原型中使用的组件样式为建议值，待 UI 设计师确认"。

---

## 3. 内嵌 UI 风格预设

用户不需要从零描述 UI 风格。subagent 在原型设计步骤（Step 2）grilling 阶段，**必须询问用户选择 UI 风格预设**。风格预设内嵌在 skill 文件中，覆盖常见平台和设计风格。

**设计理念**：借鉴以下开源 skill 的优秀实践，将经过验证的设计规则内嵌到我们的 skill 中：

| 开源 Skill | 借鉴点 | 来源 |
| ---- | ---- | ---- |
| UI/UX Pro Max | 67 种 UI 风格 + 161 套配色 + 57 组字体配对 + 反"AI 味"硬规则 | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |
| Anthropic frontend-design | 4 步设计框架（Purpose/Tone/Constraints/Differentiation）+ 美学极性选择 | [anthropics/skills](https://github.com/anthropics/skills) |
| UX/UI Design Skill | UX 行为原则与 UI 视觉实现分离，Pajamas 风格 token | [abr011/ux-design-skill](https://github.com/abr011/ux-design-skill) |
| AAA Design Skill | 16 种品牌规格 + 页面模板（dashboard/landing/article/architecture） | [chadyazar/aaa-design-skill](https://github.com/chadyazar/aaa-design-skill) |

**预设组织方式**：UI 风格预设按"平台 x 风格"矩阵组织，存放在本目录 `ui-style-presets/` 下，每个预设一个 Markdown 文件。

### 3.1 平台分类

| 平台 | 说明 | 典型场景 |
| ---- | ---- | ---- |
| Web Dashboard | 后台管理、数据仪表盘 | CRM、CMS、运营后台、监控大屏 |
| Web Landing | 营销落地页、产品官网 | 产品发布、活动推广、品牌展示 |
| Web App | 复杂 Web 应用 | 在线编辑器、项目管理工具、低代码平台 |
| Mobile App | 原生 App / 跨平台 App | 电商、社交、工具类 App |
| Mini Program | 微信小程序 / 支付宝小程序 | 轻量级服务、线下扫码场景 |
| Admin Backend | 管理后台（偏表单和列表） | ERP、OA、配置管理 |

### 3.2 风格分类

| 风格 | 核心特征 | 配色基调 | 字体配对 | 适用平台 |
| ---- | ---- | ---- | ---- | ---- |
| 极简商务 | 大量留白、克制色彩、信息密度适中 | 白底 + 主色蓝/灰 + 辅助色1个 | Inter / 思源黑体 | Web Dashboard, Admin |
| Material Design | 阴影层次、波纹反馈、FAB 按钮 | 白底 + Material 主色 + 深色变体 | Roboto / Noto Sans | Mobile App, Web App |
| 毛玻璃 | 半透明背景模糊、柔和阴影 | 浅色渐变背景 + 半透明白卡片 | SF Pro / 思源黑体 | Mobile App, Web App |
| 新粗野主义 | 粗边框、高饱和色、无阴影 | 纯色底 + 黑边框 + 撞色 | Space Grotesk / 阿里巴巴普惠体 | Web Landing, Web App |
| 复古未来 | 霓虹色、网格线、等宽字体 | 深色底 + 霓虹紫/青 + 荧光色 | JetBrains Mono / 等宽 | Web Landing, Web Dashboard |
| 杂志编辑 | 大标题、栏式排版、图片为主 | 米白底 + 深棕文字 + 单一强调色 | Playfair Display / 思源宋体 | Web Landing, Web App |
| 奢华精致 | 金属质感、精致间距、低饱和 | 奶油白底 + 深灰文字 + 橄榄绿强调 | Apoc Revelations / Söhne | Web Landing, Mobile App |
| 柔和粉彩 | 圆润、大圆角、暖色调 | 粉白底 + 柔和粉/蓝/绿 | Nunito / 圆体 | Mini Program, Mobile App |
| 工业硬朗 | 直角、深色、数据密度高 | 深灰底 + 荧光绿/橙数据色 | IBM Plex Sans / 等宽 | Web Dashboard |
| 中国风 | 水墨、留白、传统色彩 | 宣纸白底 + 墨黑 + 朱砂红 | 思源宋体 / 楷体 | Web Landing, Mini Program |
| 有机自然 | 有机形状、大地色系、自然纹理 | 沙白底 + 苔绿/赭石/陶土色 | DM Serif Display / Nunito Sans | Web Landing, Mobile App |
| 艺术装饰 | 几何对称、金属点缀、扇形纹 | 深绿底 + 金色线条 + 象牙白 | Cormorant Garamond / Montserrat | Web Landing, Web Dashboard, Mobile App |
| 极致暗色 | OLED 黑底、高对比霓虹强调色 | 纯黑底 + 单一霓虹强调色 + 灰阶 | Satoshi / Space Mono | Web Dashboard, Web App, Admin |
| 活力撞色 | 高饱和撞色、几何分块、大胆 | 亮黄底 + 品红/电蓝撞色 | Archivo Black / Inter | Web Landing, Mobile App |
| 日式禅意 | 极致留白、间（ma）、侘寂美学 | 灰白底 + 墨色文字 + 极少点缀 | 筑紫AオMincho / Hiragino | Web Dashboard, Web Landing |
| 渐变流体 | 网格渐变、流体形状、多层透明 | 渐变底 + 毛玻璃卡片 + 柔光 | General Sans / iA Writer Duo | Web App, Mobile App |

### 3.3 预设文件格式

每个预设文件（如 `ui-style-presets/web-dashboard-minimal.md`）包含以下字段：

```markdown
# 风格预设：极简商务 - Web Dashboard

## 基本信息
- 平台: Web Dashboard
- 风格: 极简商务
- 适用场景: CRM、CMS、运营后台

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #1890FF |
| 辅助色 | #52C41A |
| 警告色 | #FAAD14 |
| 错误色 | #FF4D4F |
| 背景色 | #F0F2F5 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #262626 |
| 文字次色 | #8C8C8C |
| 边框色 | #D9D9D9 |
| 圆角 | 4px (卡片) / 2px (按钮) |
| 间距基数 | 8px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Inter Bold | 思源黑体 Bold, system-ui |
| 正文 | Inter Regular | 思源黑体 Regular, system-ui |
| 等宽 | JetBrains Mono | SF Mono, Consolas |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 32px (default) / 24px (small) / 40px (large) |
| 表格 | 行高 48px，表头深色背景，斑马纹 |
| 表单 | 标签右对齐，输入框高度 32px |
| 弹窗 | 宽度 480px (默认) / 720px (大) |
| 导航 | 侧边栏宽 200px，折叠后 48px |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入淡出 200ms |
| 弹窗 | 缩放 + 淡入 150ms |
| 按钮 hover | 背景色渐变 100ms |
| 表格排序 | 箭头旋转 150ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标（自绘或引用图标库）
- 禁止紫色渐变背景（白底紫渐变是 AI slop 标志）
- 禁止使用 Inter / Roboto / Arial / system-ui 作为主标题字体（过于泛化，缺个性）。标题字体必须有辨识度，正文字体可沉稳但不可与标题同字族
- 配色必须有主次：一个主色调占 60%+，一个强调色做点睛，不可均匀分布"彩虹"
- hover / focus / active 三态必须完整实现，不可只有 hover
- 对比度达到 WCAG AA 4.5:1 标准
- 触控区域最小 44x44px
- 动画时长 150-300ms，不拖不闪
- 响应式断点: 375 / 768 / 1024 / 1440px
- 背景不可用纯色填充：必须有渐变、纹理、噪点或图案层，营造氛围和层次
- 布局不可全部居中对称卡片堆叠：至少有一处非对称、错位或破格设计
- 不可多个页面长得一样：每个页面要有视觉记忆点（一个独特元素让人记住）

## HTML 生成模板（供交互式 HTML 方式直接引用）
<head> 中直接引用的 CSS 变量和基础样式...
```

### 3.4 风格选择提问

subagent 在目标平台确认后，基于用户已选平台，从该平台对应的预设文件中给出 5 个最匹配的候选（如该平台预设不足 5 个，用最接近的其他平台预设补足并在选项中标注"跨平台借用"），向用户展示风格选择选择题：

```
UI 风格预设选择（已选平台: Web Dashboard）：

A. 极简商务 -- 大量留白、克制色彩，适合 CRM/CMS/运营后台
B. 工业硬朗 -- 深色底、荧光数据色、高信息密度，适合监控大屏/DevOps
C. 复古未来 -- 霓虹色、网格线、等宽字体，适合数据分析/技术后台
D. 极致暗色 -- OLED 黑底、高对比霓虹强调色，适合夜间/护眼/沉浸式后台
E. 日式禅意 -- 极致留白、墨色文字、间（ma）美学，适合内容优先/阅读型后台
补充描述：我自己填写
强制跳过：这个问题暂时不回答，记录为待验证并继续
```

**选项选取规则**：从已选平台对应的预设文件中优先选取；不足 5 个时，按风格多样性最大化原则从其他平台借用（不重复同一风格）。每个选项标注风格名 + 一句话核心特征 + 适合场景，让用户一眼区分差异。

### 3.5 风格预设的应用（交互式 HTML）

风格预设**直接应用**到交互式 HTML：预设文件的 design tokens 注入 HTML `:root` 的 CSS 变量（`--primary-color`、`--bg-color`、`--radius` 等，见下方映射表），组件样式用 `var(--xxx)` 引用，无需从零描述。

**design tokens 到 CSS 变量映射**（内嵌 pm-prototype-prd 的 `prototype-framework.js` / `references/prototype-guide.md` 约定）：

| 预设文件字段 | CSS 变量 | 说明 |
| ---- | ---- | ---- |
| 设计 Token 表：主色 | `--primary-color` / `--primary-hover` | 主品牌色及其悬浮态 |
| 设计 Token 表：辅助色 | `--success-color` / `--warning-color` / `--danger-color` | 辅助强调/状态色 |
| 设计 Token 表：背景色 | `--bg-color` | 页面背景 |
| 设计 Token 表：卡片背景 | `--card-bg` | 卡片容器背景 |
| 设计 Token 表：文字主色/次色 | `--text-primary` / `--text-secondary` / `--text-muted` | 正文与次要/辅助文字 |
| 设计 Token 表：边框色 | `--border-color` / `--border-light` | 边框与浅分割线 |
| 设计 Token 表：圆角 | `--radius` / `--radius-lg` | 圆角体系（组件/卡片） |
| 设计 Token 表：间距基数 | （间距按 `--radius` 体系等比例，原型中直接使用） | 间距体系（4/8/12/16/24/32） |
| 字体配对表 | `--font-family` / `--font-size`~`--font-size-xl` | 字体族与字号体系 |
| 组件风格表 | 组件 CSS（容器用 `var(--xxx)`） | 按钮/表格/表单/弹窗/导航规格 |
| 动效规则表 | 页面切换/弹窗/hover 动效 | 页面切换/弹窗/hover/排序动效 |
| 反"AI 味"硬规则 | anti-AI-slop 规则 | 禁止 emoji 图标、禁止紫色渐变等 |

> 强制规则：生成交互式 HTML 时把选中预设的 token 值注入 `:root`，所有组件样式用 `var(--xxx)` 引用，禁止硬编码色值/圆角/字号（见 `pm-prototype-prd/references/prototype-guide.md`）。

### 3.6 自定义风格

自定义风格有两种来源，都复用同一套机制（结合最近预设改 token）：

**来源一：用户口述偏好**。用户选择"补充描述"并描述了自己的风格偏好，subagent 将用户描述与最接近的预设结合使用。例如用户说"我们公司有自己的品牌色是紫色"，subagent 选择最接近的预设（如极简商务），将主色替换为紫色，其他 token 保持不变。

**来源二：截图提炼（参照截图迭代路由）**。用户提供现有系统的截图/URL，要求按原系统风格出原型。subagent 走内嵌 pm-prototype-prd 的 Step 0 参考图提取（见 `prototype-method.md` 第 4 节），先抓取/读图、从截图/URL 中提炼视觉语言（颜色、字体、间距、圆角、组件样式），注入 HTML `:root` 的 CSS 变量（`--primary-color` 等）。提炼出的 tokens 落成一个自定义 `ui-style-preset` 文件，复用 `ui-style-presets/` 的文件格式（基本信息 / 设计 Token / 字体配对 / 组件风格 / 动效规则 / 反"AI 味"规则 / HTML 生成模板），存进预设目录。这样一次截图提炼，后续页面都能复用这套参照风格，不必每页重提。

**自定义预设文件命名**：`ui-style-presets/<平台>-custom-<简称>.md`，如 `web-dashboard-custom-crm.md`。存入后更新本文件 3.2 节风格分类表和 `ui-style-presets/README.md` 的矩阵与文件清单。

### 3.7 预设扩展规则

`ui-style-presets/` 目录支持后续扩展。新增预设文件后，更新本文件中的风格分类表（3.2 节）和 `ui-style-presets/README.md` 的矩阵与文件清单即可。每个预设文件必须包含上述完整字段（基本信息、设计 Token、字体配对、组件风格、动效规则、反"AI 味"硬规则、HTML 生成模板）。

---

## 4. 设计思维与反 AI-slop 设计哲学

> 本文件引用了 `frontend-design` skill 的设计哲学。本节的理念全局适用，交互式 HTML 原型同样应当贯彻"bold aesthetic direction"原则，而非平铺直叙罗列组件。

### 4.1 五步设计思维

subagent 在进入原型设计前，先走五步设计思维——不是写下来，是想清楚：

1. **Purpose（目的）**：这个界面解决什么问题？谁用？
2. **Tone（调性）**：选一个极端的调性方向。不是在列表里随便勾一个，而是真正的设计方向选择。例如工业硬朗不是"暗色背景"——它是"直角、机械感、数据就是美学"。极简商务不是"白底蓝字"——它是"克制、呼吸感、专业信任"。
3. **Differentiation（差异点）**：这个页面做到极致的那件事是什么——用户会记住的一个点。
4. **Cohesion（一致性）**：从颜色到字体到动效到间距，每个选择是否服务于同一个调性方向，有没有"突然跳出"的元素。
5. **Boldness（大胆执行）**：设计一旦选定方向，就执行到底。半调子的设计比错误的方向更糟糕。

### 4.2 排版原则

字体是 UI 的声调，不可用泛化字体：

- 标题字体必须有辨识度：选择有性格的 display 字体（如 DM Serif Display、Cormorant Garamond、Archivo Black、Space Grotesk、Satoshi、IBM Plex Sans），而非 Inter / Roboto / system-ui
- 正文字体与标题不同字族：Serif Display 配 Sans-body，粗犷无衬线配优雅正文
- 如果用户系统不支持所选字体，提供有品格的 fallback：中文字体优先选思源黑体/宋体/圆体，前缀为"Bold/Medium/Regular"权重
- 字号层级至少 4 级：h1 / h2 / body / caption，每级步长 4-6px
- 行高常规 1.5（正文）/ 1.2（标题），中文正文行高 1.75

### 4.3 背景与氛围

- 背景不可纯白/纯灰填充。至少添加：微妙的网格噪点、极浅的径向渐变、大块模糊几何形状作为背景层
- 深色模式背景不可纯黑（#000000）。用深灰蓝或极深靛蓝（如 #0A0A0F / #1A1A2E），保留视觉深度
- 卡片用叠加的透明层和微妙阴影营造层次，而非厚实边框

### 4.4 交互与动效

动效是交互的反馈，不是装饰：

- 页面加载应有一次精心编排的入场：子元素的 staggered reveal（animation-delay 错峰），而非全局 fadeIn
- hover 状态不只有背景色改变：加 shadow lift、scale 1.02、左侧指示条滑动等有"肌肉感"的反馈
- 弹窗/抽屉入场用 transition（translateY + opacity），不出 scale（缩放弹窗太"Windows 98"）
- 动效时长严格遵守 150-300ms 窗口，过长拖沓，过短无感

### 4.5 反 AI-slop 设计核查清单

subagent 在原型交付前，对照以下核查清单（不仅检查预设文件中的硬规则——那些是代码层面的——下面这些是设计思维层面的筛选器）：

| 核查项 | 合格标准 |
| ---- | -------- |
| 这页全是居中对齐的卡片方块吗？ | 至少要有一处不对称/错位/破格布局 |
| 这页换掉颜色还能认出是什么产品吗？ | 换色后仍能通过布局和信息结构识别 |
| 背景换成白色后页面还成立吗？ | 不依赖颜色/渐变遮丑 |
| 我选的字体是每个人都用的吗？ | 检查标题字体是否 Inter/Roboto/Arial/system-ui |
| 动效是无意义的闪烁还是有意义的反馈？ | 每个动效回答"谁做了什么事，然后怎样" |
| 这个页面和另一个页面区别是什么？ | 每个页面应有独特的视觉记忆点 |
