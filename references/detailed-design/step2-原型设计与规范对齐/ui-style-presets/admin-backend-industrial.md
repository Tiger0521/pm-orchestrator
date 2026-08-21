# 风格预设：工业硬朗 - Admin Backend

## 基本信息
- 平台: Admin Backend
- 风格: 工业硬朗
- 适用场景: ERP、OA、配置管理（运维型后台）

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #00BFA6 |
| 辅助色 | #FF6D00 |
| 警告色 | #FFD700 |
| 错误色 | #FF1744 |
| 背景色 | #1A1A2E |
| 卡片背景 | #16213E |
| 文字主色 | #E0E0E0 |
| 文字次色 | #8E8E8E |
| 边框色 | #2A2A3E |
| 圆角 | 2px (最小圆角) |
| 间距基数 | 4px (2/4/8/12/16/24) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Satoshi Bold | 思源黑体 Bold, system-ui |
| 正文 | Satoshi Regular | 思源黑体 Regular, system-ui |
| 等宽 | JetBrains Mono | Source Code Pro, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 36px (default)，圆角 2px，深色背景 + 青色强调 |
| 表格 | 行高 44px，表头深色高亮，数据行荧光数值列 |
| 表单 | 输入框高度 36px，深色背景，焦点青色底边线 |
| 弹窗 | 宽度 520px (默认)，深色背景，青色顶部装饰条 |
| 导航 | 侧边栏宽 200px，深色，高亮项左侧青色竖条 |
| 筛选区 | 顶部水平排列，高度 48px，过滤器白色标签 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入 150ms |
| 弹窗 | 从右滑入 + 淡入 200ms |
| 按钮 hover | 背景色渐变 + 阴影增强 100ms |
| 侧栏展开 | slideDown 200ms |
| 数据更新 | 数值数字翻转动画 300ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标
- 禁止紫色渐变背景
- 禁止使用 Inter / Roboto / Arial 作为主标题字体
- hover / focus / active 三态必须完整实现
- 对比度达到 WCAG AA 4.5:1 标准
- 触控区域最小 44x44px
- 动画时长 150-300ms
- 背景不可纯色：需要网格纹理或底纹
- 每个页面有独立视觉记忆点

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #00BFA6;
    --color-primary-hover: #00A896;
    --color-primary-active: #00897B;
    --color-secondary: #FF6D00;
    --color-warning: #FFD700;
    --color-error: #FF1744;
    --color-bg: #1A1A2E;
    --color-card-bg: #16213E;
    --color-card-bg-hover: #1E2A4A;
    --color-text-primary: #E0E0E0;
    --color-text-secondary: #8E8E8E;
    --color-text-highlight: #00BFA6;
    --color-border: #2A2A3E;
    --color-border-active: #00BFA6;
    --radius-card: 2px;
    --radius-button: 2px;
    --radius-input: 2px;
    --spacing-xs: 2px;
    --spacing-sm: 4px;
    --spacing-md: 8px;
    --spacing-base: 12px;
    --spacing-lg: 16px;
    --spacing-xl: 24px;
    --font-family-title: 'Satoshi', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'Satoshi', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'JetBrains Mono', 'Source Code Pro', Consolas, monospace;
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;
    --btn-height-default: 36px;
    --table-row-height: 44px;
    --input-height: 36px;
    --modal-width-default: 520px;
    --sidebar-width: 200px;
    --filter-bar-height: 48px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
  }

  body::before {
    content: '';
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background-image: repeating-linear-gradient(
      0deg,
      transparent,
      transparent 2px,
      rgba(0,191,166,0.02) 2px,
      rgba(0,191,166,0.02) 3px
    );
    z-index: -1;
    pointer-events: none;
  }

  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-card-bg);
    border-right: 1px solid var(--color-border);
    min-height: 100vh;
    padding: var(--spacing-base) 0;
  }

  .sidebar-item {
    padding: var(--spacing-sm) var(--spacing-lg);
    color: var(--color-text-secondary);
    cursor: pointer;
    border-left: 3px solid transparent;
    transition: all var(--transition-fast);
  }
  .sidebar-item:hover, .sidebar-item.active {
    color: var(--color-text-primary);
    background: rgba(0,191,166,0.08);
    border-left-color: var(--color-primary);
  }

  .filter-bar {
    height: var(--filter-bar-height);
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
  }

  .card {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    padding: var(--spacing-base);
  }

  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-base);
    border: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-size: 14px;
  }
  .btn:hover {
    background: var(--color-card-bg-hover);
    box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  }
  .btn-primary {
    color: var(--color-primary);
    border-color: var(--color-primary);
  }
  .btn-primary:hover {
    background: rgba(0,191,166,0.15);
  }

  .table { width: 100%; border-collapse: collapse; }
  .table th {
    background: #0F1A2E;
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    font-weight: 600;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
  }
  .table td.highlight {
    color: var(--color-primary);
    font-family: var(--font-family-mono);
  }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-md);
    border: 1px solid var(--color-border);
    background: var(--color-bg);
    color: var(--color-text-primary);
    font-size: 14px;
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    border-bottom-width: 2px;
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
