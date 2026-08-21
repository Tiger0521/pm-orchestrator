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
    /* 主色系 */
    --color-primary: #1890FF;
    --color-primary-hover: #40A9FF;
    --color-primary-active: #096DD9;
    --color-secondary: #52C41A;
    --color-warning: #FAAD14;
    --color-error: #FF4D4F;

    /* 背景色系 */
    --color-bg: #F0F2F5;
    --color-card-bg: #FFFFFF;

    /* 文字色系 */
    --color-text-primary: #262626;
    --color-text-secondary: #8C8C8C;

    /* 边框色系 */
    --color-border: #D9D9D9;
    --color-border-light: #F0F0F0;

    /* 圆角 */
    --radius-card: 4px;
    --radius-button: 2px;
    --radius-input: 2px;

    /* 间距系统 (8px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;

    /* 字体 */
    --font-family-title: 'Inter', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'Inter', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'JetBrains Mono', 'SF Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;

    /* 组件尺寸 */
    --btn-height-sm: 24px;
    --btn-height-default: 32px;
    --btn-height-lg: 40px;
    --table-row-height: 48px;
    --input-height: 32px;
    --modal-width-default: 480px;
    --modal-width-large: 720px;
    --sidebar-width: 200px;
    --sidebar-width-collapsed: 48px;
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
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border);
    padding: var(--spacing-base);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-base);
    border-radius: var(--radius-button);
    border: 1px solid var(--color-border);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-size: 14px;
  }
  .btn-primary {
    background: var(--color-primary);
    color: #fff;
    border-color: var(--color-primary);
  }
  .btn-primary:hover {
    background: var(--color-primary-hover);
    border-color: var(--color-primary-hover);
  }

  /* 表格基础样式 */
  .table { width: 100%; border-collapse: collapse; }
  .table th {
    background: #FAFAFA;
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    font-weight: 600;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border-light);
  }
  .table tbody tr:nth-child(even) { background: #FAFAFA; }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-sm);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    font-size: 14px;
    transition: border-color var(--transition-fast);
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2);
  }

  /* 侧边栏基础样式 */
  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-card-bg);
    border-right: 1px solid var(--color-border);
    height: 100vh;
    position: fixed;
    left: 0;
    top: 0;
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
