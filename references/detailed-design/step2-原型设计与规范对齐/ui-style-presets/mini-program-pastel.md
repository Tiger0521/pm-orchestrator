# 风格预设：柔和粉彩 - Mini Program

## 基本信息
- 平台: Mini Program
- 风格: 柔和粉彩
- 适用场景: 母婴、健康、生活服务类小程序，线下扫码场景

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #FF8FAB |
| 辅助色 | #88D8B0 |
| 警告色 | #FFD93D |
| 错误色 | #FF6B6B |
| 背景色 | #FFF5F7 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #4A4A4A |
| 文字次色 | #9B9B9B |
| 边框色 | #FFE4ED |
| 圆角 | 16px (卡片) / 12px (按钮) / 20px (底部弹窗) |
| 间距基数 | 4px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Nunito Bold | 圆体, system-ui, sans-serif |
| 正文 | Nunito Regular | 圆体, system-ui, sans-serif |
| 等宽 | Nunito Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 44px (default) / 36px (small) / 52px (large)，圆角 12px，粉色填充 + 白色文字 |
| 列表 | 行高 56px，圆角分组卡片，无分割线，柔和间距 |
| 表单 | 标签上方对齐，输入框高度 44px，大圆角 + 浅色背景 |
| 底部弹窗 | 圆角 20px，从底部滑入，圆角顶部 + 柔和阴影 |
| 底部 Tab 栏 | 高度 56px，白色背景，圆角图标，选中项粉色高亮 |
| 导航栏 | 高度 44px + 状态栏，浅色背景，居中标题，右侧预留胶囊按钮空间 |
| 胶囊按钮区 | 右侧固定 88px 宽度，与微信原生胶囊按钮对齐 |
| 操作按钮组 | 底部固定栏，双按钮（取消 + 确认），圆角 + 柔和阴影 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 右滑入 + 弹性淡入 250ms |
| 底部弹窗 | 上滑 + 弹性淡入 300ms |
| 按钮 hover/press | 缩放 0.95 + 阴影变化 150ms |
| 列表项点击 | 背景色渐变 150ms |
| Tab 切换 | 图标弹跳 + 颜色渐变 200ms |
| 下拉刷新 | 旋转加载动画 200ms |

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
    /* 主色系 - 柔和粉彩 */
    --color-primary: #FF8FAB;
    --color-primary-hover: #FF7A99;
    --color-primary-active: #FF6B8A;
    --color-secondary: #88D8B0;
    --color-warning: #FFD93D;
    --color-error: #FF6B6B;

    /* 背景色系 - 暖色调粉白 */
    --color-bg: #FFF5F7;
    --color-card-bg: #FFFFFF;
    --color-surface: #FFE4ED;

    /* 文字色系 */
    --color-text-primary: #4A4A4A;
    --color-text-secondary: #9B9B9B;
    --color-text-on-primary: #FFFFFF;

    /* 边框色系 */
    --color-border: #FFE4ED;
    --color-border-light: #FFF0F5;

    /* 圆角 - 大圆角圆润风格 */
    --radius-card: 16px;
    --radius-button: 12px;
    --radius-input: 12px;
    --radius-bottom-sheet: 20px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;

    /* 字体 */
    --font-family-title: 'Nunito', '圆体', system-ui, sans-serif;
    --font-family-body: 'Nunito', '圆体', system-ui, sans-serif;
    --font-family-mono: 'Nunito Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 - 弹性缓动 */
    --transition-fast: 150ms cubic-bezier(0.34, 1.56, 0.64, 1);
    --transition-base: 200ms cubic-bezier(0.34, 1.56, 0.64, 1);
    --transition-slow: 300ms cubic-bezier(0.34, 1.56, 0.64, 1);

    /* 柔和阴影 */
    --shadow-soft: 0 2px 8px rgba(255, 143, 171, 0.15);
    --shadow-medium: 0 4px 16px rgba(255, 143, 171, 0.2);
    --shadow-tabbar: 0 -2px 8px rgba(255, 143, 171, 0.08);

    /* 组件尺寸 */
    --btn-height-sm: 36px;
    --btn-height-default: 44px;
    --btn-height-lg: 52px;
    --list-row-height: 56px;
    --input-height: 44px;
    --bottom-sheet-radius: 20px;
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
    line-height: 1.6;
    /* 模拟小程序视口 */
    max-width: var(--content-max-width);
    margin: 0 auto;
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    box-shadow: var(--shadow-soft);
    padding: var(--spacing-base);
    margin-bottom: var(--spacing-sm);
    transition: all var(--transition-fast);
  }
  .card:active {
    transform: scale(0.98);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-lg);
    border: none;
    border-radius: var(--radius-button);
    background: var(--color-primary);
    color: var(--color-text-on-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-family: var(--font-family-body);
    font-size: 15px;
    font-weight: 700;
    box-shadow: var(--shadow-soft);
  }
  .btn:active {
    transform: scale(0.95);
    box-shadow: var(--shadow-medium);
  }

  /* 列表项基础样式 */
  .list-item {
    height: var(--list-row-height);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-base);
    cursor: pointer;
    transition: background var(--transition-fast);
  }
  .list-item:active {
    background: var(--color-surface);
  }

  /* 圆角分组列表 */
  .list-group {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    box-shadow: var(--shadow-soft);
    overflow: hidden;
    margin-bottom: var(--spacing-base);
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-base);
    border: 2px solid var(--color-border);
    border-radius: var(--radius-input);
    background: var(--color-bg);
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
    transition: all var(--transition-fast);
  }
  .input:focus {
    outline: none;
    border-color: var(--color-primary);
    background: var(--color-card-bg);
  }

  /* 小程序导航栏 - 居中标题 + 右侧胶囊按钮空间 */
  .navbar {
    height: calc(var(--navbar-height) + var(--status-bar-height));
    padding-top: var(--status-bar-height);
    background: var(--color-bg);
    display: flex;
    align-items: center;
    justify-content: center;
    position: sticky;
    top: 0;
    z-index: 100;
    position: relative;
  }
  .navbar-title {
    font-family: var(--font-family-title);
    font-size: 17px;
    font-weight: 700;
    color: var(--color-text-primary);
  }
  /* 右侧胶囊按钮占位区域（与微信原生胶囊对齐） */
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
    font-size: 10px;
    font-weight: 600;
    cursor: pointer;
    transition: all var(--transition-fast);
  }
  .tabbar-item.active {
    color: var(--color-primary);
    transform: scale(1.1);
  }

  /* 底部固定操作按钮组 */
  .action-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    display: flex;
    gap: var(--spacing-sm);
    padding: var(--spacing-sm) var(--spacing-base) calc(var(--spacing-sm) + var(--safe-area-bottom));
    background: var(--color-card-bg);
    box-shadow: var(--shadow-tabbar);
    z-index: 100;
  }
  .action-bar .btn {
    flex: 1;
  }
  .btn-secondary {
    background: var(--color-surface);
    color: var(--color-primary);
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
