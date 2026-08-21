# 风格预设：渐变流体 - Web App

## 基本信息
- 平台: Web App
- 风格: 渐变流体
- 适用场景: 创意工具、设计协作平台、可视化编辑器

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #6C5CE7 |
| 辅助色 | #00CEC9 |
| 警告色 | #FDCB6E |
| 错误色 | #E17055 |
| 背景色 | #F8F9FE |
| 卡片背景 | rgba(255,255,255,0.75) |
| 文字主色 | #2D3436 |
| 文字次色 | #636E72 |
| 边框色 | rgba(108,92,231,0.12) |
| 圆角 | 16px (卡片) / 8px (按钮) |
| 间距基数 | 8px (4/8/12/16/24/32/48) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Satoshi Bold | 思源黑体 Bold, system-ui |
| 正文 | Satoshi Regular | 思源黑体 Regular, system-ui |
| 等宽 | iA Writer Duo | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 40px (default) / 32px (small)，圆角 8px，毛玻璃浅背景 |
| 表格 | 行高 52px，圆角卡片式表格，行间分隔用阴影而非线条 |
| 表单 | 输入框高度 40px，背景半透明，焦点时边框发光 |
| 弹窗 | 宽度 600px (默认) / 800px (大)，毛玻璃背景 + 模糊遮罩 |
| 导航 | 顶部导航，左侧 Logo + 中间搜索 + 右侧用户，高度 56px |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 渐变网格背景流动 + 内容淡入 300ms |
| 弹窗 | backdrop 模糊 150ms backdrop-blur，卡片 translateY 200ms |
| 按钮 hover | box-shadow 扩散 + background 渐变旋转 200ms |
| 卡片入场 | staggered reveal，每张延时 50ms，从下往上 250ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标
- 禁止紫色渐变背景（本风格主色是紫蓝色，但不可白底紫渐变 AI slop）
- 禁止使用 Inter / Roboto / Arial 作为主标题字体
- 配色必须有主次：紫色占 60%，青色做强调
- hover / focus / active 三态必须完整实现
- 对比度达到 WCAG AA 4.5:1 标准
- 触控区域最小 44x44px
- 动画时长 150-300ms
- 背景不可纯色：网格渐变背景是风格标志，必须动态流动
- 布局至少一处不对称破格
- 每个页面有独立视觉记忆点

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #6C5CE7;
    --color-primary-hover: #5A4BD1;
    --color-primary-active: #4834B5;
    --color-secondary: #00CEC9;
    --color-warning: #FDCB6E;
    --color-error: #E17055;
    --color-bg: #F8F9FE;
    --color-card-bg: rgba(255,255,255,0.75);
    --color-text-primary: #2D3436;
    --color-text-secondary: #636E72;
    --color-border: rgba(108,92,231,0.12);
    --radius-card: 16px;
    --radius-button: 8px;
    --radius-input: 8px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    --spacing-2xl: 48px;
    --font-family-title: 'Satoshi', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'Satoshi', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'iA Writer Duo', 'JetBrains Mono', Consolas, monospace;
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;
    --btn-height-sm: 32px;
    --btn-height-default: 40px;
    --btn-height-lg: 48px;
    --table-row-height: 52px;
    --input-height: 40px;
    --modal-width-default: 600px;
    --modal-width-large: 800px;
    --topbar-height: 56px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
    min-height: 100vh;
    position: relative;
    overflow-x: hidden;
  }

  body::before {
    content: '';
    position: fixed;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background:
      radial-gradient(ellipse at 20% 50%, rgba(108,92,231,0.08) 0%, transparent 50%),
      radial-gradient(ellipse at 80% 20%, rgba(0,206,201,0.06) 0%, transparent 50%),
      radial-gradient(ellipse at 50% 80%, rgba(108,92,231,0.05) 0%, transparent 50%);
    z-index: -1;
    animation: gradientFlow 20s ease-in-out infinite alternate;
  }

  @keyframes gradientFlow {
    0% { transform: translate(0, 0) rotate(0deg); }
    100% { transform: translate(-2%, -1%) rotate(3deg); }
  }

  .topbar {
    height: var(--topbar-height);
    background: rgba(255,255,255,0.6);
    backdrop-filter: blur(12px);
    border-bottom: 1px solid var(--color-border);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-lg);
    gap: var(--spacing-base);
    position: sticky;
    top: 0;
    z-index: 100;
  }

  .card {
    background: var(--color-card-bg);
    backdrop-filter: blur(8px);
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border);
    padding: var(--spacing-lg);
    box-shadow: 0 2px 8px rgba(108,92,231,0.06);
    transition: box-shadow var(--transition-base), transform var(--transition-base);
  }
  .card:hover {
    box-shadow: 0 8px 24px rgba(108,92,231,0.1);
    transform: translateY(-2px);
  }

  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-lg);
    border-radius: var(--radius-button);
    border: 1px solid var(--color-border);
    background: rgba(255,255,255,0.6);
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    font-size: 14px;
    backdrop-filter: blur(4px);
  }
  .btn:hover {
    box-shadow: 0 4px 12px rgba(108,92,231,0.15);
    transform: translateY(-1px);
  }
  .btn-primary {
    background: var(--color-primary);
    color: #fff;
    border-color: var(--color-primary);
  }
  .btn-primary:hover {
    background: var(--color-primary-hover);
    box-shadow: 0 4px 16px rgba(108,92,231,0.3);
  }

  .table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0 4px;
  }
  .table th {
    padding: var(--spacing-sm) var(--spacing-base);
    text-align: left;
    font-weight: 600;
    color: var(--color-text-secondary);
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .table td {
    padding: var(--spacing-base);
    background: var(--color-card-bg);
    border-bottom: none;
  }
  .table tr td:first-child { border-radius: var(--radius-card) 0 0 var(--radius-card); }
  .table tr td:last-child { border-radius: 0 var(--radius-card) var(--radius-card) 0; }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-base);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    background: rgba(255,255,255,0.5);
    font-size: 14px;
    transition: all var(--transition-fast);
    backdrop-filter: blur(4px);
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    box-shadow: 0 0 0 3px rgba(108,92,231,0.15);
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
