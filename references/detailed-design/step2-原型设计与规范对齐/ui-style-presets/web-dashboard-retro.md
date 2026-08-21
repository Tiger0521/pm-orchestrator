# 风格预设：复古未来 - Web Dashboard

## 基本信息
- 平台: Web Dashboard
- 风格: 复古未来
- 适用场景: 数据分析平台、技术后台、AI 监控面板、DevOps 仪表盘

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #B026FF |
| 辅助色 | #00FFFF |
| 警告色 | #FFEB3B |
| 错误色 | #FF1744 |
| 背景色 | #0D0221 |
| 卡片背景 | #1A0B2E |
| 文字主色 | #E1E1E1 |
| 文字次色 | #7B7B7B |
| 边框色 | #2D1B4E |
| 圆角 | 2px (卡片) / 0px (按钮) |
| 间距基数 | 4px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | JetBrains Mono Bold | IBM Plex Mono, Consolas, monospace |
| 正文 | JetBrains Mono Regular | IBM Plex Mono, Consolas, monospace |
| 等宽 | JetBrains Mono | IBM Plex Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 36px (default) / 28px (small) / 44px (large)，方角霓虹边框 |
| 表格 | 行高 44px，表头霓虹紫背景，网格线边框，等宽数字 |
| 表单 | 标签左对齐，输入框高度 36px，霓虹色聚焦边框 + 发光 |
| 弹窗 | 宽度 520px (默认) / 760px (大)，方角，顶部霓虹色发光边框 |
| 导航 | 侧边栏宽 220px，深色底，霓虹色高亮选中项 + 发光效果 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入 + 扫描线 200ms |
| 弹窗 | 缩放 + 淡入 + 发光 200ms |
| 按钮 hover | 霓虹边框发光 + 背景闪烁 150ms |
| 表格排序 | 箭头旋转 150ms |
| 数据加载 | 扫描线从上到下 300ms |

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
    /* 主色系 - 霓虹色 */
    --color-primary: #B026FF;
    --color-primary-hover: #C14FFF;
    --color-primary-active: #9A1FE6;
    --color-secondary: #00FFFF;
    --color-warning: #FFEB3B;
    --color-error: #FF1744;

    /* 背景色系 - 深色赛博朋克 */
    --color-bg: #0D0221;
    --color-card-bg: #1A0B2E;
    --color-card-bg-hover: #251040;

    /* 文字色系 */
    --color-text-primary: #E1E1E1;
    --color-text-secondary: #7B7B7B;
    --color-text-neon: #00FFFF;

    /* 边框色系 */
    --color-border: #2D1B4E;
    --color-border-neon: #B026FF;
    --color-border-cyan: #00FFFF;

    /* 圆角 */
    --radius-card: 2px;
    --radius-button: 0px;
    --radius-input: 0px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;

    /* 字体 */
    --font-family-title: 'JetBrains Mono', 'IBM Plex Mono', Consolas, monospace;
    --font-family-body: 'JetBrains Mono', 'IBM Plex Mono', Consolas, monospace;
    --font-family-mono: 'JetBrains Mono', 'IBM Plex Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;

    /* 发光效果 */
    --glow-primary: 0 0 10px rgba(176, 38, 255, 0.5), 0 0 20px rgba(176, 38, 255, 0.3);
    --glow-cyan: 0 0 10px rgba(0, 255, 255, 0.5), 0 0 20px rgba(0, 255, 255, 0.3);

    /* 组件尺寸 */
    --btn-height-sm: 28px;
    --btn-height-default: 36px;
    --btn-height-lg: 44px;
    --table-row-height: 44px;
    --input-height: 36px;
    --modal-width-default: 520px;
    --modal-width-large: 760px;
    --sidebar-width: 220px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.6;
  }

  /* 网格线背景 */
  body::before {
    content: '';
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background-image:
      linear-gradient(rgba(176, 38, 255, 0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(176, 38, 255, 0.03) 1px, transparent 1px);
    background-size: 40px 40px;
    pointer-events: none;
    z-index: 0;
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    border-left: 2px solid var(--color-border-neon);
    padding: var(--spacing-base);
    position: relative;
    z-index: 1;
  }
  .card:hover {
    border-color: var(--color-border-neon);
    box-shadow: var(--glow-primary);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-base);
    border: 1px solid var(--color-border-neon);
    background: transparent;
    color: var(--color-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    font-family: var(--font-family-mono);
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 1px;
  }
  .btn-primary:hover {
    background: rgba(176, 38, 255, 0.15);
    box-shadow: var(--glow-primary);
  }

  /* 表格基础样式 */
  .table { width: 100%; border-collapse: collapse; }
  .table th {
    background: rgba(176, 38, 255, 0.2);
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 2px solid var(--color-border-neon);
    font-family: var(--font-family-mono);
    font-size: 12px;
    text-transform: uppercase;
    color: var(--color-primary);
    letter-spacing: 1px;
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
    padding: 0 var(--spacing-sm);
    border: 1px solid var(--color-border);
    background: var(--color-bg);
    color: var(--color-text-primary);
    font-family: var(--font-family-mono);
    font-size: 13px;
  }
  .input:focus {
    border-color: var(--color-border-neon);
    outline: none;
    box-shadow: var(--glow-primary);
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
    z-index: 10;
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
