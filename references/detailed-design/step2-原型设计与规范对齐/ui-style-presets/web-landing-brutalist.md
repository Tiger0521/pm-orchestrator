# 风格预设：新粗野主义 - Web Landing

## 基本信息
- 平台: Web Landing
- 风格: 新粗野主义
- 适用场景: 创意机构官网、设计工作室、独立产品发布页、艺术展览推广

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #FF6B6B |
| 辅助色 | #4ECDC4 |
| 警告色 | #FFE66D |
| 错误色 | #FF3232 |
| 背景色 | #F7F7F7 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #000000 |
| 文字次色 | #555555 |
| 边框色 | #000000 |
| 圆角 | 0px (全局直角) |
| 间距基数 | 4px (4/8/16/24/32/48) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Space Grotesk Bold | 阿里巴巴普惠体 Bold, system-ui |
| 正文 | Space Grotesk Regular | 阿里巴巴普惠体 Regular, system-ui |
| 等宽 | Space Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 48px (default) / 36px (small) / 56px (large)，3px 黑色实边框，方角 |
| 表格 | 行高 56px，3px 黑色边框，无圆角，撞色表头 |
| 表单 | 标签左对齐，输入框高度 48px，3px 黑色边框，方角 |
| 弹窗 | 宽度 600px (默认) / 840px (大)，4px 黑色边框，方角，硬阴影 |
| 导航 | 顶部导航栏高 64px，黑色底部边框，大字号粗体 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 硬切 + 位移 150ms |
| 弹窗 | 缩放 + 淡入 150ms，硬阴影位移 |
| 按钮 hover | 边框位移 + 硬阴影出现 100ms |
| 表格排序 | 箭头旋转 150ms |
| 滚动揭示 | 上滑淡入 200ms |

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
    /* 主色系 - 高饱和撞色 */
    --color-primary: #FF6B6B;
    --color-primary-hover: #FF5252;
    --color-primary-active: #E63946;
    --color-secondary: #4ECDC4;
    --color-warning: #FFE66D;
    --color-error: #FF3232;

    /* 背景色系 */
    --color-bg: #F7F7F7;
    --color-card-bg: #FFFFFF;

    /* 文字色系 */
    --color-text-primary: #000000;
    --color-text-secondary: #555555;

    /* 边框色系 - 粗野黑边框 */
    --color-border: #000000;
    --border-width: 3px;
    --border-width-thick: 4px;

    /* 圆角 - 全局直角 */
    --radius-card: 0px;
    --radius-button: 0px;
    --radius-input: 0px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 16px;
    --spacing-base: 24px;
    --spacing-lg: 32px;
    --spacing-xl: 48px;

    /* 字体 */
    --font-family-title: 'Space Grotesk', '阿里巴巴普惠体', system-ui, sans-serif;
    --font-family-body: 'Space Grotesk', '阿里巴巴普惠体', system-ui, sans-serif;
    --font-family-mono: 'Space Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;

    /* 硬阴影 */
    --shadow-hard: 6px 6px 0px #000000;
    --shadow-hard-lg: 8px 8px 0px #000000;

    /* 组件尺寸 */
    --btn-height-sm: 36px;
    --btn-height-default: 48px;
    --btn-height-lg: 56px;
    --table-row-height: 56px;
    --input-height: 48px;
    --modal-width-default: 600px;
    --modal-width-large: 840px;
    --navbar-height: 64px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border: var(--border-width) solid var(--color-border);
    padding: var(--spacing-base);
  }
  .card:hover {
    box-shadow: var(--shadow-hard);
    transform: translate(-2px, -2px);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-base);
    border: var(--border-width) solid var(--color-border);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-family: var(--font-family-title);
    font-weight: 700;
    font-size: 16px;
  }
  .btn-primary {
    background: var(--color-primary);
    color: #fff;
  }
  .btn-primary:hover {
    box-shadow: var(--shadow-hard);
    transform: translate(-2px, -2px);
  }

  /* 表格基础样式 */
  .table { width: 100%; border-collapse: collapse; }
  .table th {
    background: var(--color-primary);
    color: #fff;
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border: var(--border-width) solid var(--color-border);
    font-weight: 700;
    font-size: 14px;
    text-transform: uppercase;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border: var(--border-width) solid var(--color-border);
    font-size: 14px;
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-sm);
    border: var(--border-width) solid var(--color-border);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
  }
  .input:focus {
    outline: none;
    box-shadow: var(--shadow-hard);
    transform: translate(-2px, -2px);
  }

  /* 顶部导航栏 */
  .navbar {
    height: var(--navbar-height);
    background: var(--color-card-bg);
    border-bottom: var(--border-width-thick) solid var(--color-border);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-lg);
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
