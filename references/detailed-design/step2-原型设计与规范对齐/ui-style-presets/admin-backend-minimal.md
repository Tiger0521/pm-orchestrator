# 风格预设：极简商务 - Admin Backend

## 基本信息
- 平台: Admin Backend
- 风格: 极简商务
- 适用场景: ERP、OA、配置管理、偏表单和列表的管理后台

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
| 圆角 | 2px (卡片) / 2px (按钮) |
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
| 按钮 | 高度 32px (default) / 24px (small) / 40px (large)，圆角 2px，主色填充 |
| 表格 | 行高 40px，表头深色背景，斑马纹，支持固定列 + 横向滚动 |
| 表单 | 标签右对齐，输入框高度 32px，密集排列，支持行内表单 |
| 弹窗 | 宽度 520px (默认) / 760px (大)，含底部操作按钮栏 |
| 导航 | 侧边栏宽 208px，折叠后 56px，支持三级菜单 + 面包屑导航 |
| 筛选栏 | 表格上方横向筛选栏，高度 40px，折叠/展开切换 |
| 分页 | 底部固定，含页码 + 跳转 + 每页条数选择 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 淡入淡出 200ms |
| 弹窗 | 缩放 + 淡入 150ms |
| 按钮 hover | 背景色渐变 100ms |
| 表格排序 | 箭头旋转 150ms |
| 侧边栏折叠 | 宽度过渡 200ms |
| 筛选栏展开 | 高度过渡 200ms |

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
    --color-table-header: #FAFAFA;

    /* 文字色系 */
    --color-text-primary: #262626;
    --color-text-secondary: #8C8C8C;
    --color-text-link: #1890FF;

    /* 边框色系 */
    --color-border: #D9D9D9;
    --color-border-light: #F0F0F0;
    --color-border-split: #E8E8E8;

    /* 圆角 */
    --radius-card: 2px;
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
    --table-row-height: 40px;
    --table-header-height: 40px;
    --input-height: 32px;
    --input-height-sm: 24px;
    --modal-width-default: 520px;
    --modal-width-large: 760px;
    --sidebar-width: 208px;
    --sidebar-width-collapsed: 56px;
    --navbar-height: 48px;
    --filter-bar-height: 40px;
    --pagination-height: 48px;

    /* 阴影 */
    --shadow-card: 0 1px 2px rgba(0, 0, 0, 0.06);
    --shadow-modal: 0 4px 12px rgba(0, 0, 0, 0.15);
    --shadow-sidebar: 2px 0 8px rgba(0, 0, 0, 0.06);
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
    font-size: 14px;
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    border: 1px solid var(--color-border-split);
    box-shadow: var(--shadow-card);
    padding: var(--spacing-base);
    margin-bottom: var(--spacing-base);
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
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--spacing-xs);
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
  .btn-sm {
    height: var(--btn-height-sm);
    padding: 0 var(--spacing-sm);
    font-size: 13px;
  }
  .btn-lg {
    height: var(--btn-height-lg);
    padding: 0 var(--spacing-lg);
    font-size: 16px;
  }

  /* 表格基础样式 - 高密度列表 */
  .table { width: 100%; border-collapse: collapse; font-size: 14px; }
  .table th {
    background: var(--color-table-header);
    height: var(--table-header-height);
    text-align: left;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    font-weight: 600;
    color: var(--color-text-primary);
    white-space: nowrap;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border-light);
    color: var(--color-text-primary);
  }
  .table tbody tr:nth-child(even) { background: #FAFAFA; }
  .table tbody tr:hover { background: #E6F7FF; }

  /* 表单基础样式 - 密集排列 */
  .form-item {
    display: flex;
    align-items: center;
    margin-bottom: var(--spacing-base);
  }
  .form-label {
    width: 100px;
    text-align: right;
    padding-right: var(--spacing-sm);
    color: var(--color-text-secondary);
    font-size: 14px;
    flex-shrink: 0;
  }
  .form-content {
    flex: 1;
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-sm);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    font-size: 14px;
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    transition: all var(--transition-fast);
    width: 100%;
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
    box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2);
  }

  /* 侧边栏 */
  .sidebar {
    width: var(--sidebar-width);
    background: var(--color-card-bg);
    border-right: 1px solid var(--color-border-split);
    box-shadow: var(--shadow-sidebar);
    height: 100vh;
    position: fixed;
    left: 0;
    top: 0;
    transition: width var(--transition-slow);
    z-index: 100;
  }
  .sidebar-collapsed {
    width: var(--sidebar-width-collapsed);
  }

  /* 顶部导航栏 */
  .navbar {
    height: var(--navbar-height);
    background: var(--color-card-bg);
    border-bottom: 1px solid var(--color-border-split);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-lg);
    position: sticky;
    top: 0;
    z-index: 99;
  }

  /* 面包屑导航 */
  .breadcrumb {
    display: flex;
    align-items: center;
    gap: var(--spacing-xs);
    font-size: 14px;
    color: var(--color-text-secondary);
  }
  .breadcrumb a {
    color: var(--color-text-link);
    text-decoration: none;
  }
  .breadcrumb a:hover {
    color: var(--color-primary-hover);
  }

  /* 筛选栏 */
  .filter-bar {
    background: var(--color-card-bg);
    padding: var(--spacing-base);
    margin-bottom: var(--spacing-base);
    border: 1px solid var(--color-border-split);
    border-radius: var(--radius-card);
    display: flex;
    flex-wrap: wrap;
    gap: var(--spacing-sm);
    align-items: center;
  }

  /* 分页 */
  .pagination {
    height: var(--pagination-height);
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: var(--spacing-xs);
    padding: 0 var(--spacing-base);
  }

  /* 弹窗底部操作栏 */
  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: var(--spacing-sm);
    padding: var(--spacing-base);
    border-top: 1px solid var(--color-border-light);
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
