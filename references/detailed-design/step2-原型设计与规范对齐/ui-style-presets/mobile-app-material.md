# 风格预设：Material Design - Mobile App

## 基本信息
- 平台: Mobile App
- 风格: Material Design
- 适用场景: 电商、社交、工具类移动应用，遵循 Google Material Design 规范

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #6200EE |
| 辅助色 | #03DAC6 |
| 警告色 | #FF9800 |
| 错误色 | #B00020 |
| 背景色 | #FFFFFF |
| 卡片背景 | #FFFFFF |
| 文字主色 | #212121 |
| 文字次色 | #757575 |
| 边框色 | #E0E0E0 |
| 圆角 | 8px (卡片) / 4px (按钮) / 24px (底部弹窗) |
| 间距基数 | 4px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Roboto Bold | Noto Sans Bold, system-ui, sans-serif |
| 正文 | Roboto Regular | Noto Sans Regular, system-ui, sans-serif |
| 等宽 | Roboto Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 36px (default) / 32px (small) / 48px (large)，圆角 4px，波纹反馈效果 |
| 列表 | 行高 56px，左滑出菜单，右侧图标，分割线 |
| 表单 | 标签上方浮动，输入框高度 48px，底部下划线 + 聚焦色变 |
| 底部弹窗 | 圆角 24px，从底部滑入，可拖拽关闭 |
| 底部 Tab 栏 | 高度 56px，3-5 个 Tab，图标 + 文字，选中项主色高亮 |
| FAB | 直径 56px，圆形，主色背景，右下角浮动，阴影层次 |
| 顶部 AppBar | 高度 56px，主色背景，白色标题，左侧返回箭头 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 右滑入 + 淡入 250ms |
| 底部弹窗 | 上滑 + 淡入 250ms |
| 按钮 hover/press | 波纹扩散 200ms |
| 列表项点击 | 背景色变化 150ms |
| FAB 点击 | 缩放 + 波纹 200ms |
| Tab 切换 | 下划线滑动 200ms |

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
    /* 主色系 - Material Design */
    --color-primary: #6200EE;
    --color-primary-hover: #7C4DCB;
    --color-primary-active: #4A0099;
    --color-secondary: #03DAC6;
    --color-warning: #FF9800;
    --color-error: #B00020;

    /* 背景色系 */
    --color-bg: #FFFFFF;
    --color-card-bg: #FFFFFF;
    --color-surface: #F5F5F5;

    /* 文字色系 */
    --color-text-primary: #212121;
    --color-text-secondary: #757575;
    --color-text-on-primary: #FFFFFF;

    /* 边框色系 */
    --color-border: #E0E0E0;
    --color-divider: #BDBDBD;

    /* 圆角 */
    --radius-card: 8px;
    --radius-button: 4px;
    --radius-input: 4px;
    --radius-bottom-sheet: 24px;
    --radius-fab: 28px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;

    /* 字体 */
    --font-family-title: 'Roboto', 'Noto Sans', system-ui, sans-serif;
    --font-family-body: 'Roboto', 'Noto Sans', system-ui, sans-serif;
    --font-family-mono: 'Roboto Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 150ms ease;
    --transition-base: 200ms ease;
    --transition-slow: 250ms ease;

    /* Material 阴影层次 */
    --elevation-1: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
    --elevation-2: 0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23);
    --elevation-3: 0 10px 20px rgba(0,0,0,0.19), 0 6px 6px rgba(0,0,0,0.23);
    --elevation-4: 0 14px 28px rgba(0,0,0,0.25), 0 10px 10px rgba(0,0,0,0.22);

    /* 组件尺寸 */
    --btn-height-sm: 32px;
    --btn-height-default: 36px;
    --btn-height-lg: 48px;
    --list-row-height: 56px;
    --input-height: 48px;
    --bottom-sheet-radius: 24px;
    --tabbar-height: 56px;
    --appbar-height: 56px;
    --fab-size: 56px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
    /* 模拟移动设备视口 */
    max-width: 414px;
    margin: 0 auto;
  }

  /* 卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    box-shadow: var(--elevation-1);
    padding: var(--spacing-base);
    margin-bottom: var(--spacing-sm);
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
    font-size: 14px;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    position: relative;
    overflow: hidden;
  }
  .btn:hover {
    box-shadow: var(--elevation-2);
  }
  /* 波纹效果 */
  .btn::after {
    content: '';
    position: absolute;
    top: 50%; left: 50%;
    width: 0; height: 0;
    border-radius: 50%;
    background: rgba(255,255,255,0.3);
    transform: translate(-50%, -50%);
    transition: width var(--transition-base), height var(--transition-base);
  }
  .btn:active::after {
    width: 200px;
    height: 200px;
  }

  /* 列表项基础样式 */
  .list-item {
    height: var(--list-row-height);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-base);
    border-bottom: 1px solid var(--color-border);
    cursor: pointer;
    transition: background var(--transition-fast);
  }
  .list-item:active {
    background: var(--color-surface);
  }

  /* 输入框基础样式 - Material 下划线风格 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-xs);
    border: none;
    border-bottom: 2px solid var(--color-border);
    background: transparent;
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
    transition: border-color var(--transition-fast);
  }
  .input:focus {
    outline: none;
    border-bottom-color: var(--color-primary);
  }

  /* 顶部 AppBar */
  .appbar {
    height: var(--appbar-height);
    background: var(--color-primary);
    color: var(--color-text-on-primary);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-base);
    position: sticky;
    top: 0;
    z-index: 100;
  }

  /* 底部 Tab 栏 */
  .tabbar {
    height: var(--tabbar-height);
    background: var(--color-card-bg);
    border-top: 1px solid var(--color-border);
    display: flex;
    justify-content: space-around;
    align-items: center;
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
  }
  .tabbar-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: var(--color-text-secondary);
    font-size: 12px;
    cursor: pointer;
    transition: color var(--transition-fast);
  }
  .tabbar-item.active {
    color: var(--color-primary);
  }

  /* FAB 浮动按钮 */
  .fab {
    width: var(--fab-size);
    height: var(--fab-size);
    border-radius: var(--radius-fab);
    background: var(--color-secondary);
    color: var(--color-text-primary);
    border: none;
    cursor: pointer;
    box-shadow: var(--elevation-3);
    display: flex;
    align-items: center;
    justify-content: center;
    position: fixed;
    right: var(--spacing-base);
    bottom: calc(var(--tabbar-height) + var(--spacing-base));
    z-index: 50;
    transition: box-shadow var(--transition-fast);
  }
  .fab:hover {
    box-shadow: var(--elevation-4);
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
