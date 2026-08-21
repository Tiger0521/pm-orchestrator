# 风格预设：极致暗色 - Web Dashboard

## 基本信息
- 平台: Web Dashboard
- 风格: 极致暗色
- 适用场景: 夜间监控大屏、数据分析面板、沉浸式仪表盘、护眼运营后台

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #00E5FF |
| 辅助色 | #FF7A45 |
| 警告色 | #FFC53D |
| 错误色 | #FF4D4F |
| 背景色 | #050508 |
| 卡片背景 | #0D0D14 |
| 文字主色 | #F0F0F5 |
| 文字次色 | #7A7A8C |
| 边框色 | #1A1A26 |
| 圆角 | 10px (卡片) / 6px (按钮) |
| 间距基数 | 8px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Satoshi Bold | 思源黑体 Bold, system-ui |
| 正文 | Satoshi Regular | 思源黑体 Regular, system-ui |
| 等宽 | Space Mono | SF Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 36px (default)，圆角 6px，幽灵描边为主，主操作霓虹填充 |
| 表格 | 行高 44px，表头极淡分隔线，行 hover 微亮背景，数字用等宽字体 |
| 表单 | 输入框高度 36px，纯黑背景 #050508，焦点霓虹描边 + 外发光 |
| 弹窗 | 宽度 520px (默认)，深色 #0D0D14，霓虹顶部细线 |
| 导航 | 侧边栏宽 220px，纯黑底，活跃项霓虹左侧指示条 |
| KPI 卡片 | 大号等宽数字 + 单位，卡片顶部无装饰，靠数字大小做层级 |
| 图表容器 | 深色底 + 网格线 #1A1A26，数据线用主色/辅助色双线 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入 200ms |
| KPI 数字 | 计数滚动 400ms（等宽字体保证不跳动） |
| 按钮 hover | 霓虹描边亮度增强 150ms |
| 卡片 hover | 边框微亮 + 阴影加深 150ms |
| 图表加载 | 数据线从左到右描画 600ms（一次性入场） |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标（描边风格，线宽 1.5px）
- 禁止紫色渐变背景
- 禁止使用 Inter / Roboto / Arial 作为主标题字体
- hover / focus / active 三态必须完整实现
- 对比度达到 WCAG AA 4.5:1 标准（暗底灰字尤其要过检）
- 触控区域最小 44x44px
- 动画时长 150-300ms
- 背景不可纯黑 #000000：用 #050508 保留深度
- 单一霓虹强调色原则：主色只做一个（青），辅助色只用于数据对比，不做彩虹仪表盘
- 卡片层次靠极细边框 + 微妙底色差，不堆厚阴影
- 每个页面有独立视觉记忆点

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #00E5FF;
    --color-primary-hover: #4DEBFF;
    --color-primary-active: #00B8CC;
    --color-secondary: #FF7A45;
    --color-warning: #FFC53D;
    --color-error: #FF4D4F;
    --color-bg: #050508;
    --color-card-bg: #0D0D14;
    --color-card-bg-hover: #13131D;
    --color-text-primary: #F0F0F5;
    --color-text-secondary: #7A7A8C;
    --color-border: #1A1A26;
    --color-border-active: #00E5FF;
    --radius-card: 10px;
    --radius-button: 6px;
    --radius-input: 6px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    --font-family-title: 'Satoshi', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'Satoshi', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'Space Mono', 'SF Mono', Consolas, monospace;
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;
    --btn-height-default: 36px;
    --table-row-height: 44px;
    --input-height: 36px;
    --modal-width-default: 520px;
    --sidebar-width: 220px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
    min-height: 100vh;
  }

  body::before {
    content: '';
    position: fixed;
    inset: 0;
    background: radial-gradient(ellipse at 70% -10%, rgba(0, 229, 255, 0.05) 0%, transparent 55%);
    z-index: -1;
    pointer-events: none;
  }

  .app-layout {
    display: flex;
    min-height: 100vh;
  }

  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-bg);
    border-right: 1px solid var(--color-border);
    padding: var(--spacing-base) 0;
  }

  .sidebar-item {
    padding: var(--spacing-sm) var(--spacing-lg);
    color: var(--color-text-secondary);
    cursor: pointer;
    position: relative;
    transition: color var(--transition-fast), background var(--transition-fast);
  }
  .sidebar-item:hover {
    color: var(--color-text-primary);
  }
  .sidebar-item.active {
    color: var(--color-primary);
    background: rgba(0, 229, 255, 0.06);
  }
  .sidebar-item.active::before {
    content: '';
    position: absolute;
    left: 0; top: 8px; bottom: 8px;
    width: 2px;
    background: var(--color-primary);
    border-radius: 1px;
  }

  .main-content {
    flex: 1;
    padding: var(--spacing-lg);
    overflow-y: auto;
  }

  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border);
    padding: var(--spacing-base);
    transition: border-color var(--transition-fast), background var(--transition-fast);
  }
  .card:hover {
    border-color: rgba(0, 229, 255, 0.35);
    background: var(--color-card-bg-hover);
  }

  .kpi-value {
    font-family: var(--font-family-mono);
    font-size: 34px;
    font-weight: 700;
    color: var(--color-text-primary);
    letter-spacing: -0.5px;
  }
  .kpi-unit {
    font-family: var(--font-family-body);
    font-size: 13px;
    color: var(--color-text-secondary);
    margin-left: 4px;
  }
  .kpi-trend-up { color: var(--color-primary); font-size: 13px; }
  .kpi-trend-down { color: var(--color-error); font-size: 13px; }

  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-lg);
    border-radius: var(--radius-button);
    background: transparent;
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    border: 1px solid var(--color-border);
    font-size: 14px;
    font-family: var(--font-family-body);
  }
  .btn:hover {
    border-color: var(--color-text-secondary);
  }
  .btn-primary {
    background: var(--color-primary);
    color: #050508;
    border-color: var(--color-primary);
    font-weight: 600;
  }
  .btn-primary:hover {
    background: var(--color-primary-hover);
    box-shadow: 0 0 16px rgba(0, 229, 255, 0.25);
  }
  .btn-primary:active {
    background: var(--color-primary-active);
  }

  .table { width: 100%; border-collapse: collapse; }
  .table th {
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    color: var(--color-text-secondary);
    font-weight: 500;
    font-size: 12px;
    letter-spacing: 0.5px;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid rgba(26, 26, 38, 0.6);
  }
  .table td.num {
    font-family: var(--font-family-mono);
  }
  .table tbody tr:hover {
    background: rgba(0, 229, 255, 0.03);
  }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-base);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    background: var(--color-bg);
    color: var(--color-text-primary);
    font-size: 14px;
    transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    box-shadow: 0 0 0 3px rgba(0, 229, 255, 0.12);
  }

  .chart-container {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-card);
    padding: var(--spacing-lg);
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
