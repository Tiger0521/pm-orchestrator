# 风格预设：日式禅意 - Web Dashboard

## 基本信息
- 平台: Web Dashboard
- 风格: 日式禅意
- 适用场景: 内容优先的阅读型后台、报告面板、知识库管理、冥想/ wellness 类产品后台

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #2B2B2B |
| 辅助色 | #B5502F |
| 警告色 | #C2880E |
| 错误色 | #A63A2E |
| 背景色 | #F7F6F2 |
| 卡片背景 | #FDFCFA |
| 文字主色 | #2B2B2B |
| 文字次色 | #9B9A94 |
| 边框色 | #E8E6DF |
| 圆角 | 2px (卡片) / 2px (按钮) |
| 间距基数 | 8px (8/16/24/32/48/64) — 间距基数偏大，留白即设计 |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | 筑紫AオMincho（Tsukushi A Old Mincho） | 思源宋体 Medium, serif |
| 正文 | Hiragino Sans | 思源黑体 Regular, system-ui |
| 等宽 | Space Mono | SF Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 40px (default)，圆角 2px，墨色填充白字；次按钮细描边无填充 |
| 表格 | 行高 56px（高于常规，行间呼吸感），仅横向发丝线分隔，无表头背景色 |
| 表单 | 输入框高度 40px，无内边框，仅底部 1px 发丝线，焦点时底线变墨色 |
| 弹窗 | 宽度 480px (默认)，米白底，无阴影或极浅阴影，靠留白分区 |
| 导航 | 侧边栏宽 240px，灰白底与正文同色，仅 1px 发丝线分隔 |
| 数据卡片 | 无边框，仅靠留白和字重区分层级；数字用衬线字体放大 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 极缓淡入 300ms（禅意不急躁，可放宽到 300ms 上限） |
| 弹窗 | 淡入 250ms，无缩放无位移 |
| 按钮 hover | 墨色加深 200ms |
| 表格行 hover | 底色极浅加深 200ms |
| 数字变化 | 直接切换，不做跳动动画（静默原则） |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标（细线描边 1px，克制数量，每页不超过 5 个）
- 禁止紫色渐变背景
- 禁止使用 Inter / Roboto / Arial 作为主标题字体（本风格标题必须衬线）
- hover / focus / active 三态必须完整实现（即使反馈极轻）
- 对比度达到 WCAG AA 4.5:1 标准
- 触控区域最小 44x44px
- 动画时长 150-300ms（本风格取上限，宁慢勿跳）
- 极少点缀原则：全局只有一个朱色 #B5502F 强调点（如当前项、关键数字），其余全部灰阶
- 禁止阴影堆叠：卡片靠留白分区，最多 1 层极浅阴影
- 留白即设计：区块间距至少 48px，拒绝密集信息堆叠
- 每个页面有独立视觉记忆点（本风格通常是超大衬线数字或一处朱色）

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #2B2B2B;
    --color-primary-hover: #1A1A1A;
    --color-secondary: #B5502F;
    --color-warning: #C2880E;
    --color-error: #A63A2E;
    --color-bg: #F7F6F2;
    --color-card-bg: #FDFCFA;
    --color-text-primary: #2B2B2B;
    --color-text-secondary: #9B9A94;
    --color-border: #E8E6DF;
    --color-accent: #B5502F;
    --radius-card: 2px;
    --radius-button: 2px;
    --radius-input: 2px;
    --spacing-xs: 8px;
    --spacing-sm: 16px;
    --spacing-md: 24px;
    --spacing-base: 32px;
    --spacing-lg: 48px;
    --spacing-xl: 64px;
    --font-family-title: 'Tsukushi A Old Mincho', '筑紫AオMincho', '思源宋体', serif;
    --font-family-body: 'Hiragino Sans', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'Space Mono', 'SF Mono', Consolas, monospace;
    --transition-fast: 200ms ease;
    --transition-base: 250ms ease;
    --transition-slow: 300ms ease;
    --btn-height-default: 40px;
    --table-row-height: 56px;
    --input-height: 40px;
    --modal-width-default: 480px;
    --sidebar-width: 240px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.75;
    min-height: 100vh;
  }

  .app-layout {
    display: flex;
    min-height: 100vh;
  }

  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-bg);
    border-right: 1px solid var(--color-border);
    padding: var(--spacing-md) 0;
  }

  .sidebar-item {
    padding: var(--spacing-xs) var(--spacing-md);
    color: var(--color-text-secondary);
    cursor: pointer;
    font-size: 14px;
    letter-spacing: 0.05em;
    transition: color var(--transition-fast);
  }
  .sidebar-item:hover {
    color: var(--color-text-primary);
  }
  .sidebar-item.active {
    color: var(--color-accent);
  }

  .main-content {
    flex: 1;
    padding: var(--spacing-lg);
    max-width: 1080px;
    margin: 0 auto;
  }

  .page-title {
    font-family: var(--font-family-title);
    font-size: 28px;
    font-weight: 500;
    letter-spacing: 0.08em;
    margin-bottom: var(--spacing-md);
  }

  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border);
    padding: var(--spacing-md);
  }

  .stat-block {
    padding: var(--spacing-md) 0;
    border-bottom: 1px solid var(--color-border);
  }
  .stat-block:last-child { border-bottom: none; }
  .stat-label {
    font-size: 13px;
    color: var(--color-text-secondary);
    letter-spacing: 0.1em;
    margin-bottom: var(--spacing-xs);
  }
  .stat-value {
    font-family: var(--font-family-title);
    font-size: 40px;
    font-weight: 400;
    color: var(--color-text-primary);
    line-height: 1.1;
  }
  .stat-value.accent { color: var(--color-accent); }

  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-md);
    border-radius: var(--radius-button);
    background: transparent;
    color: var(--color-text-primary);
    cursor: pointer;
    transition: background var(--transition-fast), color var(--transition-fast);
    border: 1px solid var(--color-border);
    font-size: 14px;
    font-family: var(--font-family-body);
    letter-spacing: 0.05em;
  }
  .btn:hover { border-color: var(--color-text-secondary); }
  .btn-primary {
    background: var(--color-primary);
    color: #FDFCFA;
    border-color: var(--color-primary);
  }
  .btn-primary:hover {
    background: var(--color-primary-hover);
    border-color: var(--color-primary-hover);
  }

  .table { width: 100%; border-collapse: collapse; }
  .table th {
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-xs);
    border-bottom: 1px solid var(--color-border);
    color: var(--color-text-secondary);
    font-weight: 400;
    font-size: 13px;
    letter-spacing: 0.08em;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-xs);
    border-bottom: 1px solid var(--color-border);
  }
  .table tbody tr:hover {
    background: rgba(43, 43, 43, 0.025);
  }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-xs);
    border: none;
    border-bottom: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    font-size: 15px;
    transition: border-color var(--transition-fast);
  }
  .input:focus {
    border-bottom-color: var(--color-primary);
    outline: none;
  }

  .hairline {
    border: none;
    border-top: 1px solid var(--color-border);
    margin: var(--spacing-md) 0;
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
