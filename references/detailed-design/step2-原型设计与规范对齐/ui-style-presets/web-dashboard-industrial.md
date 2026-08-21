# 风格预设：工业硬朗 - Web Dashboard

## 基本信息
- 平台: Web Dashboard
- 风格: 工业硬朗
- 适用场景: 监控大屏、DevOps 工具、工业系统、运维管理

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #39FF14 |
| 辅助色 | #FF8C00 |
| 警告色 | #FFD700 |
| 错误色 | #FF3B3B |
| 背景色 | #1A1A2E |
| 卡片背景 | #16213E |
| 文字主色 | #E0E0E0 |
| 文字次色 | #8E8E8E |
| 边框色 | #2A2A3E |
| 圆角 | 0px (全局直角) |
| 间距基数 | 4px (2/4/8/12/16/24) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | IBM Plex Sans Bold | 思源黑体 Bold, system-ui |
| 正文 | IBM Plex Sans Regular | 思源黑体 Regular, system-ui |
| 等宽 | IBM Plex Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 36px (default) / 28px (small) / 44px (large)，方角无圆角 |
| 表格 | 行高 40px，表头深色高亮背景，无斑马纹，等宽数字 |
| 表单 | 标签左对齐，输入框高度 36px，方角深色背景 |
| 弹窗 | 宽度 560px (默认) / 800px (大)，无圆角，顶部荧光色边框 |
| 导航 | 顶部导航栏高 48px，深色背景，荧光色高亮选中项 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入 150ms |
| 弹窗 | 滑入 + 淡入 200ms |
| 按钮 hover | 背景色渐变 100ms，左侧荧光色条出现 |
| 表格排序 | 箭头旋转 150ms |
| 数据刷新 | 荧光色脉冲 300ms |

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
    /* 主色系 - 荧光数据色 */
    --color-primary: #39FF14;
    --color-primary-hover: #2ECC11;
    --color-primary-active: #25CC0A;
    --color-secondary: #FF8C00;
    --color-warning: #FFD700;
    --color-error: #FF3B3B;

    /* 背景色系 - 深色工业风 */
    --color-bg: #1A1A2E;
    --color-card-bg: #16213E;
    --color-card-bg-hover: #1E2A4A;

    /* 文字色系 */
    --color-text-primary: #E0E0E0;
    --color-text-secondary: #8E8E8E;
    --color-text-highlight: #39FF14;

    /* 边框色系 */
    --color-border: #2A2A3E;
    --color-border-active: #39FF14;

    /* 圆角 - 全局直角 */
    --radius-card: 0px;
    --radius-button: 0px;
    --radius-input: 0px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 2px;
    --spacing-sm: 4px;
    --spacing-md: 8px;
    --spacing-base: 12px;
    --spacing-lg: 16px;
    --spacing-xl: 24px;

    /* 字体 */
    --font-family-title: 'IBM Plex Sans', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'IBM Plex Sans', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'IBM Plex Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;

    /* 组件尺寸 */
    --btn-height-sm: 28px;
    --btn-height-default: 36px;
    --btn-height-lg: 44px;
    --table-row-height: 40px;
    --input-height: 36px;
    --modal-width-default: 560px;
    --modal-width-large: 800px;
    --topbar-height: 48px;
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
    border: 1px solid var(--color-border);
    padding: var(--spacing-base);
  }
  .card:hover {
    background: var(--color-card-bg-hover);
    border-color: var(--color-border-active);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-base);
    border: 1px solid var(--color-border);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-family: var(--font-family-mono);
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .btn-primary {
    background: transparent;
    color: var(--color-primary);
    border-color: var(--color-primary);
  }
  .btn-primary:hover {
    background: rgba(57, 255, 20, 0.1);
    border-color: var(--color-primary);
  }

  /* 表格基础样式 */
  .table { width: 100%; border-collapse: collapse; }
  .table th {
    background: #0F3460;
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 2px solid var(--color-primary);
    font-family: var(--font-family-mono);
    font-size: 12px;
    text-transform: uppercase;
    color: var(--color-primary);
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    font-family: var(--font-family-mono);
    font-size: 13px;
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-md);
    border: 1px solid var(--color-border);
    background: var(--color-bg);
    color: var(--color-text-primary);
    font-family: var(--font-family-mono);
    font-size: 13px;
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    box-shadow: 0 0 0 1px var(--color-primary);
  }

  /* 顶部导航栏 */
  .topbar {
    height: var(--topbar-height);
    background: var(--color-card-bg);
    border-bottom: 1px solid var(--color-border);
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
