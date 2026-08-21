# UI 风格预设索引

本目录存放详细设计阶段内嵌的 UI 风格预设文件。用户在 Step 2 原型设计时，subagent 会先询问目标平台，再基于该平台给出 5 个最匹配的风格预设候选。每个预设文件定义一种"平台 x 风格"组合的完整设计 Token（颜色、字体、圆角、间距、组件规格、动效规则、反"AI 味"硬规则和 HTML 生成模板）。

---

## 平台 x 风格矩阵

下表展示了当前已有的预设文件分布。"有"表示该组合已有预设文件，"--"表示该组合暂无预设（可后续扩展）。

| 风格 \ 平台 | Web Dashboard | Web Landing | Web App | Mobile App | Mini Program | Admin Backend |
| ------------ | -------------- | ----------- | ------- | ----------- | ------------ | ------------- |
| 极简商务     | 有             | --          | 有      | --          | --           | 有            |
| Material Design | --         | --          | --      | 有          | --           | --            |
| 毛玻璃       | --             | --          | --      | 有          | --           | --            |
| 新粗野主义   | --             | 有          | --      | --          | --           | --            |
| 复古未来     | 有             | --          | --      | --          | --           | --            |
| 杂志编辑     | --             | 有          | --      | --          | --           | --            |
| 奢华精致     | --             | 有          | --      | --          | --           | --            |
| 柔和粉彩     | --             | --          | --      | 有          | 有           | --            |
| 工业硬朗     | 有             | --          | 有      | --          | --           | 有            |
| 中国风       | --             | 有          | --      | --          | 有           | --            |
| 有机自然     | --             | --          | --      | --          | --           | --            |
| 艺术装饰     | --             | --          | --      | 有          | --           | --            |
| 极致暗色     | 有             | --          | --      | --          | --           | 有            |
| 活力撞色     | --             | --          | --      | 有          | --           | --            |
| 日式禅意     | 有             | --          | --      | --          | --           | --            |
| 渐变流体     | --             | --          | 有      | --          | --           | --            |

### 平台说明

| 平台 | 说明 | 典型场景 |
| ---- | ---- | ---- |
| Web Dashboard | 后台管理、数据仪表盘 | CRM、CMS、运营后台、监控大屏 |
| Web Landing | 营销落地页、产品官网 | 产品发布、活动推广、品牌展示 |
| Web App | 复杂 Web 应用 | 在线编辑器、项目管理工具、低代码平台 |
| Mobile App | 原生 App / 跨平台 App | 电商、社交、工具类 App |
| Mini Program | 微信小程序 / 支付宝小程序 | 轻量级服务、线下扫码场景 |
| Admin Backend | 管理后台（偏表单和列表） | ERP、OA、配置管理 |

### 风格说明（16 种）

风格分类的权威定义见 `../ui-design-style.md` 第 3.2 节，本表与该节保持同步。

| 风格 | 核心特征 | 配色基调 | 字体配对 | 适用平台 |
| ---- | ---- | ---- | ---- | ---- |
| 极简商务 | 大量留白、克制色彩、信息密度适中 | 白底 + 主色蓝/灰 + 辅助色1个 | Inter / 思源黑体 | Web Dashboard, Admin, Web App |
| Material Design | 阴影层次、波纹反馈、FAB 按钮 | 白底 + Material 主色 + 深色变体 | Roboto / Noto Sans | Mobile App, Web App |
| 毛玻璃 | 半透明背景模糊、柔和阴影 | 浅色渐变背景 + 半透明白卡片 | SF Pro / 思源黑体 | Mobile App, Web App |
| 新粗野主义 | 粗边框、高饱和色、无阴影 | 纯色底 + 黑边框 + 撞色 | Space Grotesk / 阿里巴巴普惠体 | Web Landing, Web App |
| 复古未来 | 霓虹色、网格线、等宽字体 | 深色底 + 霓虹紫/青 + 荧光色 | JetBrains Mono / 等宽 | Web Landing, Web Dashboard |
| 杂志编辑 | 大标题、栏式排版、图片为主 | 米白底 + 深棕文字 + 单一强调色 | Playfair Display / 思源宋体 | Web Landing, Web App |
| 奢华精致 | 金属质感、精致间距、低饱和 | 奶油白底 + 深灰文字 + 橄榄绿强调 | Apoc Revelations / Söhne | Web Landing, Mobile App |
| 柔和粉彩 | 圆润、大圆角、暖色调 | 粉白底 + 柔和粉/蓝/绿 | Nunito / 圆体 | Mini Program, Mobile App |
| 工业硬朗 | 直角、深色、数据密度高 | 深灰底 + 荧光绿/橙数据色 | IBM Plex Sans / 等宽 | Web Dashboard, Web App, Admin |
| 中国风 | 水墨、留白、传统色彩 | 宣纸白底 + 墨黑 + 朱砂红 | 思源宋体 / 楷体 | Web Landing, Mini Program |
| 有机自然 | 有机形状、大地色系、自然纹理 | 沙白底 + 苔绿/赭石/陶土色 | DM Serif Display / Nunito Sans | Web Landing, Mobile App |
| 艺术装饰 | 几何对称、金属点缀、扇形纹 | 深绿底 + 金色线条 + 象牙白 | Cormorant Garamond / Montserrat | Web Landing, Web Dashboard, Mobile App |
| 极致暗色 | OLED 黑底、高对比霓虹强调色 | 纯黑底 + 单一霓虹强调色 + 灰阶 | Satoshi / Space Mono | Web Dashboard, Web App, Admin |
| 活力撞色 | 高饱和撞色、几何分块、大胆 | 亮黄底 + 品红/电蓝撞色 | Archivo Black / Inter | Web Landing, Mobile App |
| 日式禅意 | 极致留白、间（ma）、侘寂美学 | 灰白底 + 墨色文字 + 极少点缀 | 筑紫AオMincho / Hiragino | Web Dashboard, Web Landing |
| 渐变流体 | 网格渐变、流体形状、多层透明 | 渐变底 + 毛玻璃卡片 + 柔光 | General Sans / iA Writer Duo | Web App, Mobile App |

---

## 选择指南

### 第一步：确定平台

根据项目类型和目标设备选择平台：

1. **Web Dashboard** -- 适合后台管理系统、数据仪表盘、运营后台。以数据展示和表格操作为主，侧边栏导航。
2. **Web Landing** -- 适合营销落地页、产品官网、活动推广页。以品牌展示和转化引导为主，单页滚动式布局。
3. **Web App** -- 适合复杂 Web 应用（在线编辑器、项目管理工具）。功能复杂，多面板布局。
4. **Mobile App** -- 适合原生或跨平台 App。触控交互为主，底部 Tab 栏导航。
5. **Mini Program** -- 适合微信/支付宝小程序。轻量级服务，含胶囊按钮等小程序特有组件。
6. **Admin Backend** -- 适合偏表单和列表的管理后台（ERP、OA、配置管理）。与 Web Dashboard 类似但更侧重表单密度。

### 第二步：确定风格

根据产品调性和用户群体选择风格：

1. **极简商务** -- 适合 B2B 产品、企业级应用。克制、专业、信息清晰。
2. **Material Design** -- 适合面向消费者的移动应用。遵循 Google 设计规范，层次感强。
3. **毛玻璃** -- 适合高端消费类应用。视觉精致，半透明质感。
4. **新粗野主义** -- 适合创意机构、设计工作室官网。大胆、有态度、视觉冲击强。
5. **复古未来** -- 适合技术工具、数据分析平台。赛博朋克美学，数据感强。
6. **杂志编辑** -- 适合内容型产品、媒体官网。排版讲究，阅读体验优先。
7. **奢华精致** -- 适合高端品牌、奢侈品官网。质感精致，低饱和高级感。
8. **柔和粉彩** -- 适合母婴、健康、生活类应用。温暖、亲和、无攻击性。
9. **工业硬朗** -- 适合 DevOps 工具、监控大屏、工业系统。数据密度高，深色护眼。
10. **中国风** -- 适合传统文化、国潮品牌、政务类产品。水墨意境，传统美学。
11. **有机自然** -- 适合环保、健康、生活方式品牌。柔和曲线，大地色温润感。
12. **艺术装饰** -- 适合奢侈品、高端会所、精品酒店。几何对称，金色线条装饰感。
13. **极致暗色** -- 适合夜间使用、监控面板、沉浸式产品。OLED 纯黑省电，霓虹强调色醒目。
14. **活力撞色** -- 适合年轻人社交、运动健身、潮牌。高饱和撞色，能量感强。
15. **日式禅意** -- 适合阅读型产品、内容后台、冥想类应用。极致留白，安静克制。
16. **渐变流体** -- 适合创意工具、设计协作平台。柔和渐变，轻盈流动感。

### 第三步：查找预设文件

根据平台和风格的交叉点，在下方文件清单中找到对应的预设文件。如果该组合暂无预设，选择最接近的预设并自定义调整。

### 自定义风格

如果用户选择"补充描述"并描述了自己的风格偏好，subagent 将用户描述与最接近的预设结合使用。例如用户说"我们公司有自己的品牌色是紫色"，subagent 选择最接近的预设（如极简商务），将主色替换为紫色，其他 Token 保持不变。截图提炼自定义预设的完整机制见 `../ui-design-style.md` 第 3.6 节。

---

## 预设文件清单

| 文件名 | 平台 | 风格 | 简要说明 |
| ------ | ---- | ---- | -------- |
| `web-dashboard-minimal.md` | Web Dashboard | 极简商务 | 白底蓝色主色调，大量留白，适合 CRM/CMS/运营后台 |
| `web-dashboard-industrial.md` | Web Dashboard | 工业硬朗 | 深灰底荧光数据色，直角高密度，适合监控大屏/DevOps |
| `web-dashboard-retro.md` | Web Dashboard | 复古未来 | 深色底霓虹紫青，网格线等宽字体，适合数据分析/技术后台 |
| `web-dashboard-dark.md` | Web Dashboard | 极致暗色 | OLED 黑底单霓虹青强调色，KPI 等宽大数字，适合夜间/沉浸式仪表盘 |
| `web-dashboard-zen.md` | Web Dashboard | 日式禅意 | 灰白底墨色文字衬线标题，大留白发丝线，适合阅读型/内容优先后台 |
| `web-landing-brutalist.md` | Web Landing | 新粗野主义 | 纯色底黑边框撞色，粗犷无阴影，适合创意机构/设计工作室 |
| `web-landing-magazine.md` | Web Landing | 杂志编辑 | 米白底深棕文字，栏式排版大标题，适合内容媒体/品牌官网 |
| `web-landing-luxury.md` | Web Landing | 奢华精致 | 奶油白底深灰橄榄绿，金属质感精致间距，适合高端品牌/奢侈品 |
| `web-landing-chinese.md` | Web Landing | 中国风 | 宣纸白底墨黑朱砂红，水墨留白传统色彩，适合国潮/传统文化 |
| `web-app-minimal.md` | Web App | 极简商务 | 白底蓝色主色调，多面板工作区布局，适合编辑器/项目管理工具 |
| `web-app-industrial.md` | Web App | 工业硬朗 | 深灰底荧光数据色，多面板高密度，适合 DevOps/日志分析平台 |
| `web-app-gradient.md` | Web App | 渐变流体 | 渐变底毛玻璃卡片，柔和光感，适合创意工具/设计协作平台 |
| `mobile-app-material.md` | Mobile App | Material Design | 白底 Material 主色，阴影层次波纹反馈，适合消费类移动应用 |
| `mobile-app-glassmorphism.md` | Mobile App | 毛玻璃 | 浅色渐变半透明白卡片，柔和阴影模糊，适合高端消费类应用 |
| `mobile-app-pastel.md` | Mobile App | 柔和粉彩 | 粉白底柔和粉蓝绿，圆润大圆角暖色调，适合母婴/健康/生活 |
| `mobile-app-vibrant.md` | Mobile App | 活力撞色 | 亮黄底品红电蓝撞色，黑描边硬阴影，适合年轻人社交/运动/潮牌 |
| `mobile-app-art-deco.md` | Mobile App | 艺术装饰 | 墨绿底金色线条象牙白，几何对称扇形纹，适合奢侈品/精品酒店 |
| `mini-program-pastel.md` | Mini Program | 柔和粉彩 | 粉白底柔和粉蓝绿，含胶囊按钮等小程序组件，适合生活服务 |
| `mini-program-chinese.md` | Mini Program | 中国风 | 宣纸白底墨黑朱砂红，含胶囊按钮等小程序组件，适合国风/政务 |
| `admin-backend-minimal.md` | Admin Backend | 极简商务 | 白底蓝色主色调，表单列表高密度，适合 ERP/OA/配置管理 |
| `admin-backend-industrial.md` | Admin Backend | 工业硬朗 | 深色直角高密度表单列表，适合运维型 ERP/日志后台 |
| `admin-backend-dark.md` | Admin Backend | 极致暗色 | 深黑底紫色强调色，微光边框统计卡片，适合夜间运营/安全审计 |

---

## 预设扩展规则

`ui-style-presets/` 目录支持后续扩展。新增预设文件后，更新本 README 的平台 x 风格矩阵、风格说明表、文件清单，以及 `../ui-design-style.md` 第 3.2 节风格分类表。每个预设文件必须包含上述完整字段：

1. **基本信息** -- 平台、风格、适用场景
2. **设计 Token** -- 主色、辅助色、警告色、错误色、背景色、卡片背景、文字主色、文字次色、边框色、圆角、间距基数
3. **字体配对** -- 标题、正文、等宽字体的字体和回退
4. **组件风格** -- 按钮、表格、表单、弹窗、导航等组件的规格（按平台补充特有组件，如 Mobile 的底部导航/安全区）
5. **动效规则** -- 页面切换、弹窗、按钮 hover 等场景的动画
6. **反"AI 味"硬规则** -- 以 `../ui-design-style.md` 第 3.3 节的 12 条为基线，可按风格特化（如活力撞色追加"撞色纪律"、日式禅意追加"极少点缀原则"）
7. **HTML 生成模板** -- 供交互式 HTML 方式直接引用的 CSS 变量和基础样式

### 风格预设的应用（交互式 HTML）

直接应用 -- 预设 design tokens 注入 HTML `:root` 的 CSS 变量（`--primary-color` 等，映射表见 `../ui-design-style.md` 第 3.5 节），组件样式用 `var(--xxx)` 引用。
