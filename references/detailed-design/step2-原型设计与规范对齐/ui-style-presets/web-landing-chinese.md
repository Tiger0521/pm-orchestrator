# 风格预设：中国风 - Web Landing

## 基本信息
- 平台: Web Landing
- 风格: 中国风
- 适用场景: 国潮品牌官网、传统文化推广、政务文化展示、茶道/书院

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #9E2A2B |
| 辅助色 | #4A6741 |
| 警告色 | #C9963B |
| 错误色 | #8B0000 |
| 背景色 | #F5F0E6 |
| 卡片背景 | #FFFEF7 |
| 文字主色 | #1A1A1A |
| 文字次色 | #5C5C5C |
| 边框色 | #D4C9B0 |
| 圆角 | 0px (全局直角) |
| 间距基数 | 8px (8/16/24/32/48/64) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | 思源宋体 Bold | 楷体, Georgia, serif |
| 正文 | 思源宋体 Regular | 楷体, Georgia, serif |
| 等宽 | 思源等宽 | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 44px (default) / 36px (small) / 52px (large)，直角，朱砂红边框 + 墨色文字 |
| 表格 | 行高 48px，表头宋体大号，横线分隔无竖线 |
| 表单 | 标签上方对齐，输入框高度 44px，底部墨色细线边框 |
| 弹窗 | 宽度 600px (默认) / 840px (大)，无圆角，顶部朱砂红装饰线 |
| 导航 | 顶部导航栏高 64px，宋体大号 Logo，底部水墨色细线 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 水墨晕染淡入 300ms |
| 弹窗 | 上滑 + 淡入 250ms |
| 按钮 hover | 墨色扩散 + 朱砂红显现 200ms |
| 表格排序 | 箭头旋转 150ms |
| 滚动揭示 | 水墨淡入 + 上滑 400ms |

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
    /* 主色系 - 朱砂红 + 墨绿 */
    --color-primary: #9E2A2B;
    --color-primary-hover: #B33333;
    --color-primary-active: #7A2021;
    --color-secondary: #4A6741;
    --color-warning: #C9963B;
    --color-error: #8B0000;

    /* 背景色系 - 宣纸白 */
    --color-bg: #F5F0E6;
    --color-card-bg: #FFFEF7;

    /* 文字色系 - 墨色 */
    --color-text-primary: #1A1A1A;
    --color-text-secondary: #5C5C5C;
    --color-text-accent: #9E2A2B;

    /* 边框色系 */
    --color-border: #D4C9B0;
    --color-border-light: #E8DFD0;

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
    --font-family-title: '思源宋体', '楷体', Georgia, serif;
    --font-family-body: '思源宋体', '楷体', Georgia, serif;
    --font-family-mono: '思源等宽', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 150ms ease;
    --transition-base: 200ms ease;
    --transition-slow: 300ms ease;

    /* 组件尺寸 */
    --btn-height-sm: 36px;
    --btn-height-default: 44px;
    --btn-height-lg: 52px;
    --table-row-height: 48px;
    --input-height: 44px;
    --modal-width-default: 600px;
    --modal-width-large: 840px;
    --navbar-height: 64px;
    --content-max-width: 1200px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.8;
  }

  /* 宣纸纹理背景 */
  body::before {
    content: '';
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background-image: radial-gradient(circle at 20% 30%, rgba(158, 42, 43, 0.02) 0%, transparent 50%),
                      radial-gradient(circle at 80% 70%, rgba(74, 103, 65, 0.02) 0%, transparent 50%);
    pointer-events: none;
    z-index: 0;
  }

  .container {
    max-width: var(--content-max-width);
    margin: 0 auto;
    padding: 0 var(--spacing-base);
    position: relative;
    z-index: 1;
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    padding: var(--spacing-md);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-md);
    border: 1px solid var(--color-primary);
    background: transparent;
    color: var(--color-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    font-family: var(--font-family-title);
    font-size: 15px;
    letter-spacing: 2px;
  }
  .btn-primary:hover {
    background: var(--color-primary);
    color: var(--color-card-bg);
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
    font-weight: 700;
    letter-spacing: 1px;
  }
  .table td {
    height: var(--table-row-height);
    padding: 0 var(--spacing-sm);
    border-bottom: 1px solid var(--color-border);
    font-size: 15px;
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-xs);
    border: none;
    border-bottom: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
    transition: border-color var(--transition-base);
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
    font-size: 44px;
    font-weight: 700;
    line-height: 1.4;
    letter-spacing: 4px;
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
