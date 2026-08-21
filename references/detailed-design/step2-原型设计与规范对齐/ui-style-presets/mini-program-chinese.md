# 风格预设：中国风 - Mini Program

## 基本信息
- 平台: Mini Program
- 风格: 中国风
- 适用场景: 国潮品牌、传统文化展示、政务文化服务、茶道书院小程序

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
| 圆角 | 4px (卡片) / 2px (按钮) / 12px (底部弹窗) |
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
| 按钮 | 高度 44px (default) / 36px (small) / 52px (large)，小圆角 2px，朱砂红边框 + 墨色文字 |
| 列表 | 行高 56px，圆角分组卡片，横线分隔，宋体大号文字 |
| 表单 | 标签上方对齐，输入框高度 44px，底部墨色细线边框 |
| 底部弹窗 | 圆角 12px，从底部滑入，顶部朱砂红装饰线 |
| 底部 Tab 栏 | 高度 56px，宣纸色背景，宋体文字，选中项朱砂红高亮 |
| 导航栏 | 高度 44px + 状态栏，宣纸色背景，居中宋体标题，右侧预留胶囊按钮空间 |
| 胶囊按钮区 | 右侧固定 88px 宽度，与微信原生胶囊按钮对齐 |
| 操作按钮组 | 底部固定栏，双按钮（取消 + 确认），朱砂红确认 + 墨色取消 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 水墨淡入 250ms |
| 底部弹窗 | 上滑 + 水墨淡入 300ms |
| 按钮 hover/press | 墨色扩散 + 朱砂红显现 200ms |
| 列表项点击 | 背景色渐变 150ms |
| Tab 切换 | 下划线滑动 + 颜色渐变 200ms |
| 下拉刷新 | 水墨晕染加载动画 300ms |

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
    --color-surface: #EDE8DC;

    /* 文字色系 - 墨色 */
    --color-text-primary: #1A1A1A;
    --color-text-secondary: #5C5C5C;
    --color-text-accent: #9E2A2B;

    /* 边框色系 */
    --color-border: #D4C9B0;
    --color-border-light: #E8DFD0;

    /* 圆角 - 小圆角传统风格 */
    --radius-card: 4px;
    --radius-button: 2px;
    --radius-input: 2px;
    --radius-bottom-sheet: 12px;

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

    /* 阴影 */
    --shadow-soft: 0 2px 8px rgba(158, 42, 43, 0.08);
    --shadow-medium: 0 4px 12px rgba(158, 42, 43, 0.12);
    --shadow-tabbar: 0 -2px 8px rgba(26, 26, 26, 0.06);

    /* 组件尺寸 */
    --btn-height-sm: 36px;
    --btn-height-default: 44px;
    --btn-height-lg: 52px;
    --list-row-height: 56px;
    --input-height: 44px;
    --bottom-sheet-radius: 12px;
    --tabbar-height: 56px;
    --navbar-height: 44px;
    --status-bar-height: 20px;
    --capsule-width: 88px;
    --safe-area-bottom: 34px;
    --content-max-width: 414px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.8;
    /* 模拟小程序视口 */
    max-width: var(--content-max-width);
    margin: 0 auto;
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

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-card);
    padding: var(--spacing-sm);
    margin-bottom: var(--spacing-xs);
    position: relative;
    z-index: 1;
    transition: all var(--transition-fast);
  }
  .card:active {
    background: var(--color-surface);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-sm);
    border: 1px solid var(--color-primary);
    border-radius: var(--radius-button);
    background: transparent;
    color: var(--color-primary);
    cursor: pointer;
    transition: all var(--transition-base);
    font-family: var(--font-family-title);
    font-size: 15px;
    letter-spacing: 2px;
  }
  .btn-primary {
    background: var(--color-primary);
    color: var(--color-card-bg);
  }
  .btn:active {
    opacity: 0.8;
  }

  /* 列表项基础样式 */
  .list-item {
    height: var(--list-row-height);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-sm);
    cursor: pointer;
    transition: background var(--transition-fast);
    border-bottom: 1px solid var(--color-border-light);
  }
  .list-item:active {
    background: var(--color-surface);
  }
  .list-item:last-child {
    border-bottom: none;
  }

  /* 圆角分组列表 */
  .list-group {
    background: var(--color-card-bg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-card);
    overflow: hidden;
    margin-bottom: var(--spacing-xs);
  }

  /* 输入框基础样式 - 下划线风格 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-xs);
    border: none;
    border-bottom: 2px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
    transition: border-color var(--transition-base);
  }
  .input:focus {
    outline: none;
    border-bottom-color: var(--color-primary);
  }

  /* 小程序导航栏 - 居中宋体标题 + 右侧胶囊按钮空间 */
  .navbar {
    height: calc(var(--navbar-height) + var(--status-bar-height));
    padding-top: var(--status-bar-height);
    background: var(--color-bg);
    display: flex;
    align-items: center;
    justify-content: center;
    border-bottom: 1px solid var(--color-border);
    position: sticky;
    top: 0;
    z-index: 100;
  }
  .navbar-title {
    font-family: var(--font-family-title);
    font-size: 17px;
    font-weight: 700;
    color: var(--color-text-primary);
    letter-spacing: 2px;
  }
  /* 右侧胶囊按钮占位区域 */
  .navbar-capsule-placeholder {
    position: absolute;
    right: var(--spacing-xs);
    top: var(--status-bar-height);
    width: var(--capsule-width);
    height: var(--navbar-height);
    /* 实际开发中此区域由微信原生胶囊按钮占据 */
  }

  /* 底部 Tab 栏 */
  .tabbar {
    height: calc(var(--tabbar-height) + var(--safe-area-bottom));
    background: var(--color-card-bg);
    box-shadow: var(--shadow-tabbar);
    border-top: 1px solid var(--color-border);
    display: flex;
    justify-content: space-around;
    align-items: flex-start;
    padding-top: var(--spacing-xs);
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 100;
  }
  .tabbar-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    color: var(--color-text-secondary);
    font-family: var(--font-family-title);
    font-size: 10px;
    cursor: pointer;
    transition: color var(--transition-fast);
  }
  .tabbar-item.active {
    color: var(--color-primary);
  }

  /* 底部固定操作按钮组 */
  .action-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    display: flex;
    gap: var(--spacing-xs);
    padding: var(--spacing-xs) var(--spacing-sm) calc(var(--spacing-xs) + var(--safe-area-bottom));
    background: var(--color-card-bg);
    border-top: 1px solid var(--color-border);
    box-shadow: var(--shadow-tabbar);
    z-index: 100;
  }
  .action-bar .btn {
    flex: 1;
  }
  .btn-secondary {
    border-color: var(--color-border);
    color: var(--color-text-primary);
    background: transparent;
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
