# 风格预设：杂志编辑 - Web Landing

## 基本信息
- 平台: Web Landing
- 风格: 杂志编辑
- 适用场景: 内容媒体官网、品牌故事页、产品发布专题、数字杂志

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #C0392B |
| 辅助色 | #8E44AD |
| 警告色 | #F39C12 |
| 错误色 | #C0392B |
| 背景色 | #FAF6F0 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #3E2723 |
| 文字次色 | #795548 |
| 边框色 | #D7CCC8 |
| 圆角 | 0px (全局直角) |
| 间距基数 | 8px (8/16/24/32/48/64) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Playfair Display Bold | 思源宋体 Bold, Georgia, serif |
| 正文 | Playfair Display Regular | 思源宋体 Regular, Georgia, serif |
| 等宽 | Space Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 44px (default) / 36px (small) / 52px (large)，直角，细线边框 + 下划线 |
| 表格 | 行高 52px，表头衬线字体大号，横线分隔无竖线 |
| 表单 | 标签上方对齐，输入框高度 44px，下划线样式无边框 |
| 弹窗 | 宽度 640px (默认) / 880px (大)，无圆角，顶部大号标题 |
| 导航 | 顶部导航栏高 72px，大号衬线 Logo，底部细线分隔 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 上滑淡入 300ms |
| 弹窗 | 上滑 + 淡入 250ms |
| 按钮 hover | 下划线展开 200ms |
| 表格排序 | 箭头旋转 150ms |
| 滚动揭示 | 图片渐显 + 文字上滑 300ms |

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
    /* 主色系 - 单一强调色 */
    --color-primary: #C0392B;
    --color-primary-hover: #A93226;
    --color-primary-active: #922B21;
    --color-secondary: #8E44AD;
    --color-warning: #F39C12;
    --color-error: #C0392B;

    /* 背景色系 - 米白纸质 */
    --color-bg: #FAF6F0;
    --color-card-bg: #FFFFFF;

    /* 文字色系 - 深棕色系 */
    --color-text-primary: #3E2723;
    --color-text-secondary: #795548;
    --color-text-accent: #C0392B;

    /* 边框色系 */
    --color-border: #D7CCC8;
    --color-border-light: #EFEBE9;

    /* 圆角 - 全局直角 */
    --radius-card: 0px;
    --radius-button: 0px;
    --radius-input: 0px;

    /* 间距系统 (8px 基数) */
    --spacing-xs: 8px;
    --spacing-sm: 16px;
    --spacing-md: 24px;
    --spacing-base: 32px;
    --spacing-lg: 48px;
    --spacing-xl: 64px;

    /* 字体 */
    --font-family-title: 'Playfair Display', '思源宋体', Georgia, serif;
    --font-family-body: 'Playfair Display', '思源宋体', Georgia, serif;
    --font-family-mono: 'Space Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 150ms ease;
    --transition-base: 200ms ease;
    --transition-slow: 300ms ease;

    /* 组件尺寸 */
    --btn-height-sm: 36px;
    --btn-height-default: 44px;
    --btn-height-lg: 52px;
    --table-row-height: 52px;
    --input-height: 44px;
    --modal-width-default: 640px;
    --modal-width-large: 880px;
    --navbar-height: 72px;
    --content-max-width: 1200px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.8;
  }

  /* 栏式排版 */
  .container {
    max-width: var(--content-max-width);
    margin: 0 auto;
    padding: 0 var(--spacing-base);
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    padding: var(--spacing-md);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-md);
    border: none;
    border-bottom: 2px solid var(--color-primary);
    background: transparent;
    color: var(--color-text-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-family: var(--font-family-title);
    font-size: 15px;
    letter-spacing: 1px;
  }
  .btn-primary {
    color: var(--color-primary);
  }
  .btn-primary:hover {
    color: var(--color-primary-hover);
    border-bottom-width: 4px;
  }

  /* 表格基础样式 */
  .table { width: 100%; border-collapse: collapse; }
  .table th {
    height: var(--table-row-height);
    text-align: left;
    padding: 0 var(--spacing-sm);
    border-bottom: 2px solid var(--color-text-primary);
    font-family: var(--font-family-title);
    font-size: 14px;
    text-transform: uppercase;
    letter-spacing: 2px;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-sm);
    border-bottom: 1px solid var(--color-border);
    font-size: 15px;
  }

  /* 输入框基础样式 - 下划线风格 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-xs);
    border: none;
    border-bottom: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
  }
  .input:focus {
    outline: none;
    border-bottom-color: var(--color-primary);
    border-bottom-width: 2px;
  }

  /* 顶部导航栏 */
  .navbar {
    height: var(--navbar-height);
    background: var(--color-bg);
    border-bottom: 1px solid var(--color-border);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-base);
  }

  /* 大标题样式 */
  .headline {
    font-family: var(--font-family-title);
    font-size: 48px;
    font-weight: 700;
    line-height: 1.2;
    letter-spacing: -0.5px;
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
