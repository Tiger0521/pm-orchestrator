# 风格预设：极致暗色 - Admin Backend

## 基本信息
- 平台: Admin Backend
- 风格: 极致暗色
- 适用场景: 夜间运营后台、监控面板、安全审计平台

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #7C5CFC |
| 辅助色 | #50E3C2 |
| 警告色 | #FFB347 |
| 错误色 | #FF6B6B |
| 背景色 | #0A0A0F |
| 卡片背景 | #12121A |
| 文字主色 | #EAEAEF |
| 文字次色 | #6B6B80 |
| 边框色 | #1E1E2A |
| 圆角 | 8px (卡片) / 6px (按钮) |
| 间距基数 | 8px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | DM Sans Bold | 思源黑体 Bold, system-ui |
| 正文 | DM Sans Regular | 思源黑体 Regular, system-ui |
| 等宽 | JetBrains Mono | SF Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 36px (default)，圆角 6px，主色填充，hover 亮度增强 |
| 表格 | 行高 48px，表头暗色高亮，行 hover 背景微妙提升 |
| 表单 | 输入框高度 36px，深色背景 #0A0A0F，焦点紫色外发光 |
| 弹窗 | 宽度 480px (默认)，深色背景，圆角 8px，微光边框 |
| 导航 | 侧边栏宽 200px，深色底，活跃项紫渐变色块 |
| 统计卡片 | 背景 #12121A，紫色顶部装饰条，大号数字 + 标签 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入 + 微上移 200ms |
| 弹窗 | 缩放 + 淡入 200ms |
| 按钮 hover | 亮度增强 + 微阴影 150ms |
| 统计卡片 | 数字跳动动画 400ms |
| 侧边栏项 | 活跃指示条 slideIn 150ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标
- 禁止紫色渐变背景（本风格主色是紫色，但不可白底紫渐变 AI slop）
- 禁止使用 Inter / Roboto / Arial 作为主标题字体
- hover / focus / active 三态必须完整实现
- 对比度达到 WCAG AA 4.5:1 标准（暗色模式更需关注文本对比度）
- 触控区域最小 44x44px
- 动画时长 150-300ms
- 背景不可纯黑：用极深灰 #0A0A0F 而非 #000000
- 卡片需要微妙层次：通过透明白叠加和光晕，非厚边框
- 每个页面有独立视觉记忆点

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #7C5CFC;
    --color-primary-hover: #9176FD;
    --color-primary-active: #6A48E5;
    --color-secondary: #50E3C2;
    --color-warning: #FFB347;
    --color-error: #FF6B6B;
    --color-bg: #0A0A0F;
    --color-card-bg: #12121A;
    --color-card-bg-hover: #181828;
    --color-text-primary: #EAEAEF;
    --color-text-secondary: #6B6B80;
    --color-border: #1E1E2A;
    --color-border-active: #7C5CFC;
    --radius-card: 8px;
    --radius-button: 6px;
    --radius-input: 6px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    --font-family-title: 'DM Sans', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'DM Sans', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'JetBrains Mono', 'SF Mono', Consolas, monospace;
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;
    --btn-height-default: 36px;
    --table-row-height: 48px;
    --input-height: 36px;
    --modal-width-default: 480px;
    --sidebar-width: 200px;
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
    top: 0; left: 0; right: 0; bottom: 0;
    background: radial-gradient(ellipse at 20% 20%, rgba(124,92,252,0.06) 0%, transparent 50%),
                radial-gradient(ellipse at 80% 80%, rgba(80,227,194,0.04) 0%, transparent 50%);
    z-index: -1;
    pointer-events: none;
  }

  .app-layout {
    display: flex;
    min-height: 100vh;
  }

  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-card-bg);
    border-right: 1px solid var(--color-border);
    padding: var(--spacing-base) 0;
  }

  .sidebar-item {
    padding: var(--spacing-sm) var(--spacing-lg);
    color: var(--color-text-secondary);
    cursor: pointer;
    position: relative;
    transition: all var(--transition-fast);
  }
  .sidebar-item:hover {
    color: var(--color-text-primary);
    background: rgba(124,92,252,0.08);
  }
  .sidebar-item.active {
    color: var(--color-text-primary);
    background: linear-gradient(90deg, rgba(124,92,252,0.15) 0%, transparent 100%);
    border-right: 2px solid var(--color-primary);
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
    transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  }
  .card:hover {
    border-color: var(--color-border-active);
    box-shadow: 0 4px 20px rgba(124,92,252,0.08);
  }

  .stat-card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border);
    padding: var(--spacing-lg);
    border-top: 3px solid var(--color-primary);
  }
  .stat-value {
    font-size: 32px;
    font-weight: 700;
    color: var(--color-text-primary);
    font-family: var(--font-family-mono);
  }

  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-lg);
    border-radius: var(--radius-button);
    border: none;
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    border: 1px solid var(--color-border);
    font-size: 14px;
  }
  .btn:hover {
    background: var(--color-card-bg-hover);
    box-shadow: 0 2px 8px rgba(0,0,0,0.4);
  }
  .btn-primary {
    background: var(--color-primary);
    color: #fff;
    border-color: var(--color-primary);
  }
  .btn-primary:hover {
    background: var(--color-primary-hover);
    box-shadow: 0 4px 12px rgba(124,92,252,0.3);
  }

  .table { width: 100%; border-collapse: collapse; }
  .table th {
    background: #0E0E18;
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    color: var(--color-text-secondary);
    font-weight: 600;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
  }
  .table tbody tr:hover {
    background: rgba(124,92,252,0.04);
  }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-base);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    background: var(--color-bg);
    color: var(--color-text-primary);
    font-size: 14px;
    transition: all var(--transition-fast);
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    box-shadow: 0 0 0 3px rgba(124,92,252,0.15);
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
