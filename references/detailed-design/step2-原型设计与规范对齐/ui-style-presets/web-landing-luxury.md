# 风格预设：奢华精致 - Web Landing

## 基本信息
- 平台: Web Landing
- 风格: 奢华精致
- 适用场景: 高端品牌官网、奢侈品展示、精品酒店、高级定制服务

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #556B2F |
| 辅助色 | #C0A062 |
| 警告色 | #D4A574 |
| 错误色 | #8B3A3A |
| 背景色 | #FBF9F4 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #2C2C2C |
| 文字次色 | #6B6B6B |
| 边框色 | #E8E0D5 |
| 圆角 | 2px (卡片) / 1px (按钮) |
| 间距基数 | 4px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Apoc Revelations | Söhne, Georgia, serif |
| 正文 | Söhne | 思源黑体, system-ui, sans-serif |
| 等宽 | Söhne Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 40px (default) / 32px (small) / 48px (large)，细线边框，大字间距 |
| 表格 | 行高 48px，极简横线分隔，表头金属色细字 |
| 表单 | 标签上方对齐，输入框高度 40px，底部细线边框 |
| 弹窗 | 宽度 520px (默认) / 760px (大)，细线边框，金属色装饰线 |
| 导航 | 顶部导航栏高 60px，大字间距 Logo，透明背景 + 模糊 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入 300ms |
| 弹窗 | 缩放 + 淡入 250ms |
| 按钮 hover | 边框颜色渐变 200ms |
| 表格排序 | 箭头旋转 150ms |
| 滚动揭示 | 淡入 + 上滑 400ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标
- 禁止紫色渐变背景
- hover 状态必须完整实现
- 对比度达到 WCAG AA 4.5:1 标准
- 触控区域最小 44x44px
- 动画时长 150-300ms，不拖不闪
- 响应式断点: 375 / 768 / 1024 / 1440px

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    /* 主色系 - 橄榄绿 + 金属金 */
    --color-primary: #556B2F;
    --color-primary-hover: #6B8E23;
    --color-primary-active: #4A5D28;
    --color-secondary: #C0A062;
    --color-warning: #D4A574;
    --color-error: #8B3A3A;

    /* 背景色系 - 奶油白 */
    --color-bg: #FBF9F4;
    --color-card-bg: #FFFFFF;

    /* 文字色系 - 深灰低饱和 */
    --color-text-primary: #2C2C2C;
    --color-text-secondary: #6B6B6B;
    --color-text-accent: #C0A062;

    /* 边框色系 - 精致浅色 */
    --color-border: #E8E0D5;
    --color-border-light: #F5F1EA;

    /* 圆角 */
    --radius-card: 2px;
    --radius-button: 1px;
    --radius-input: 1px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;

    /* 字体 */
    --font-family-title: 'Apoc Revelations', 'Söhne', Georgia, serif;
    --font-family-body: 'Söhne', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'Söhne Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 150ms ease;
    --transition-base: 200ms ease;
    --transition-slow: 300ms ease;

    /* 组件尺寸 */
    --btn-height-sm: 32px;
    --btn-height-default: 40px;
    --btn-height-lg: 48px;
    --table-row-height: 48px;
    --input-height: 40px;
    --modal-width-default: 520px;
    --modal-width-large: 760px;
    --navbar-height: 60px;
    --content-max-width: 1280px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.7;
  }

  .container {
    max-width: var(--content-max-width);
    margin: 0 auto;
    padding: 0 var(--spacing-lg);
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-card);
    padding: var(--spacing-lg);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-lg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-button);
    background: transparent;
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    font-family: var(--font-family-body);
    font-size: 14px;
    letter-spacing: 2px;
    text-transform: uppercase;
  }
  .btn-primary {
    border-color: var(--color-primary);
    color: var(--color-primary);
  }
  .btn-primary:hover {
    background: var(--color-primary);
    color: var(--color-bg);
    border-color: var(--color-primary);
  }

  /* 表格基础样式 */
  .table { width: 100%; border-collapse: collapse; }
  .table th {
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-text-secondary);
    font-family: var(--font-family-body);
    font-weight: 400;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: var(--color-text-secondary);
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border-light);
    font-size: 14px;
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-sm);
    border: none;
    border-bottom: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 14px;
    transition: border-color var(--transition-base);
  }
  .input:focus {
    outline: none;
    border-bottom-color: var(--color-secondary);
  }

  /* 顶部导航栏 */
  .navbar {
    height: var(--navbar-height);
    background: rgba(251, 249, 244, 0.9);
    backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--color-border);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-lg);
    position: sticky;
    top: 0;
    z-index: 100;
  }

  /* 标题样式 */
  .headline {
    font-family: var(--font-family-title);
    font-size: 40px;
    font-weight: 400;
    line-height: 1.3;
    letter-spacing: -0.5px;
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
