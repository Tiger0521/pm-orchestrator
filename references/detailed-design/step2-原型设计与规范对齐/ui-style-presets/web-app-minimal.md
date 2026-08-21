# 风格预设：极简商务 - Web App

## 基本信息
- 平台: Web App
- 风格: 极简商务
- 适用场景: 在线编辑器、项目管理工具、低代码平台

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
| 导航 | 侧边栏宽 220px，折叠后 48px |
| 工具栏 | 高度 40px，顶部固定，带图标+文字混合按钮 |
| 面板 | 可拖拽分隔条，左右分栏，面板间距 8px |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入淡出 200ms |
| 弹窗 | 缩放 + 淡入 150ms |
| 按钮 hover | 背景色渐变 100ms |
| 面板拖拽 | 实时跟随，无动画 |
| 树展开 | slideDown 200ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标
- 禁止紫色渐变背景
- hover 状态必须完整实现
- 对比度达到 WCAG AA 4.5:1 标准
- 触控区域最小 44x44px
- 动画时长 150-300ms，不拖不闪
- 响应式断点: 375 / 768 / 1024 / 1440px
- 背景不可用纯色填充：必须有渐变、纹理、噪点或图案层
- 布局不可全部居中对称卡片堆叠：至少有一处非对称、错位或破格设计
- 不可多个页面长得一样：每个页面要有视觉记忆点

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #1890FF;
    --color-primary-hover: #40A9FF;
    --color-primary-active: #096DD9;
    --color-secondary: #52C41A;
    --color-warning: #FAAD14;
    --color-error: #FF4D4F;
    --color-bg: #F0F2F5;
    --color-card-bg: #FFFFFF;
    --color-text-primary: #262626;
    --color-text-secondary: #8C8C8C;
    --color-border: #D9D9D9;
    --color-border-light: #F0F0F0;
    --radius-card: 4px;
    --radius-button: 2px;
    --radius-input: 2px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    --font-family-title: 'Inter', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'Inter', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'JetBrains Mono', 'SF Mono', Consolas, monospace;
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 200ms ease;
    --btn-height-sm: 24px;
    --btn-height-default: 32px;
    --btn-height-lg: 40px;
    --table-row-height: 48px;
    --input-height: 32px;
    --modal-width-default: 480px;
    --modal-width-large: 720px;
    --sidebar-width: 220px;
    --sidebar-width-collapsed: 48px;
    --toolbar-height: 40px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
    overflow: hidden;
  }

  .app-layout {
    display: flex;
    height: 100vh;
  }

  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-card-bg);
    border-right: 1px solid var(--color-border);
    display: flex;
    flex-direction: column;
    transition: width var(--transition-base);
  }

  .main-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .toolbar {
    height: var(--toolbar-height);
    background: var(--color-card-bg);
    border-bottom: 1px solid var(--color-border);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-base);
    gap: var(--spacing-sm);
  }

  .content-panels {
    flex: 1;
    display: flex;
    overflow: hidden;
  }

  .panel {
    overflow: auto;
    border-right: 1px solid var(--color-border-light);
    padding: var(--spacing-base);
  }
  .panel:last-child { border-right: none; }

  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border);
    padding: var(--spacing-base);
  }

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
    white-space: nowrap;
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

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
