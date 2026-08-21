# 风格预设：毛玻璃 - Mobile App

## 基本信息
- 平台: Mobile App
- 风格: 毛玻璃
- 适用场景: 高端消费类应用、音乐播放器、天气应用、iOS 风格工具应用

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #007AFF |
| 辅助色 | #34C759 |
| 警告色 | #FF9500 |
| 错误色 | #FF3B30 |
| 背景色 | #E8E8F0 |
| 卡片背景 | rgba(255, 255, 255, 0.72) |
| 文字主色 | #1C1C1E |
| 文字次色 | #8E8E93 |
| 边框色 | rgba(255, 255, 255, 0.5) |
| 圆角 | 16px (卡片) / 12px (按钮) / 20px (底部弹窗) |
| 间距基数 | 4px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | SF Pro Display Bold | 思源黑体 Bold, system-ui, sans-serif |
| 正文 | SF Pro Text Regular | 思源黑体 Regular, system-ui, sans-serif |
| 等宽 | SF Mono | JetBrains Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 44px (default) / 36px (small) / 52px (large)，圆角 12px，半透明背景 + 模糊 |
| 列表 | 行高 56px，毛玻璃分组背景，圆角分组容器 |
| 表单 | 标签上方浮动，输入框高度 44px，圆角 + 半透明背景 |
| 底部弹窗 | 圆角 20px，毛玻璃背景，从底部滑入 |
| 底部 Tab 栏 | 高度 56px + 安全区，毛玻璃背景模糊，图标 + 文字 |
| 顶部导航 | 高度 44px + 状态栏，毛玻璃背景模糊，大号标题 |
| FAB | 直径 50px，圆形，毛玻璃半透明背景 |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 右滑入 + 淡入 250ms |
| 底部弹窗 | 上滑 + 毛玻璃淡入 300ms |
| 按钮 hover/press | 缩放 0.96 + 背景透明度变化 150ms |
| 列表项点击 | 背景透明度变化 150ms |
| 毛玻璃模糊 | backdrop-filter 渐变 200ms |
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
    /* 主色系 - iOS 风格 */
    --color-primary: #007AFF;
    --color-primary-hover: #0066D6;
    --color-primary-active: #0055B3;
    --color-secondary: #34C759;
    --color-warning: #FF9500;
    --color-error: #FF3B30;

    /* 背景色系 - 浅色渐变 */
    --color-bg: #E8E8F0;
    --color-bg-gradient: linear-gradient(135deg, #E8E8F0 0%, #F0E8F5 50%, #E0F0F5 100%);

    /* 毛玻璃卡片 */
    --color-card-bg: rgba(255, 255, 255, 0.72);
    --color-card-bg-hover: rgba(255, 255, 255, 0.85);

    /* 文字色系 */
    --color-text-primary: #1C1C1E;
    --color-text-secondary: #8E8E93;
    --color-text-on-glass: #1C1C1E;

    /* 边框色系 */
    --color-border: rgba(255, 255, 255, 0.5);
    --color-border-glass: rgba(255, 255, 255, 0.3);

    /* 圆角 */
    --radius-card: 16px;
    --radius-button: 12px;
    --radius-input: 12px;
    --radius-bottom-sheet: 20px;
    --radius-fab: 25px;

    /* 间距系统 (4px 基数) */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;

    /* 字体 */
    --font-family-title: 'SF Pro Display', '思源黑体', system-ui, sans-serif;
    --font-family-body: 'SF Pro Text', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'SF Mono', 'JetBrains Mono', Consolas, monospace;

    /* 动效 */
    --transition-fast: 150ms ease;
    --transition-base: 200ms ease;
    --transition-slow: 300ms ease;

    /* 毛玻璃模糊 */
    --blur-light: blur(10px);
    --blur-medium: blur(20px);
    --blur-heavy: blur(30px);

    /* 柔和阴影 */
    --shadow-soft: 0 4px 12px rgba(0, 0, 0, 0.08);
    --shadow-glass: 0 8px 32px rgba(0, 0, 0, 0.06);

    /* 组件尺寸 */
    --btn-height-sm: 36px;
    --btn-height-default: 44px;
    --btn-height-lg: 52px;
    --list-row-height: 56px;
    --input-height: 44px;
    --bottom-sheet-radius: 20px;
    --tabbar-height: 56px;
    --navbar-height: 44px;
    --fab-size: 50px;
    --safe-area-bottom: 34px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg-gradient);
    color: var(--color-text-primary);
    line-height: 1.5;
    /* 模拟移动设备视口 */
    max-width: 414px;
    margin: 0 auto;
    min-height: 100vh;
  }

  /* 毛玻璃卡片基础样式 */
  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    backdrop-filter: var(--blur-medium);
    -webkit-backdrop-filter: var(--blur-medium);
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-glass);
    padding: var(--spacing-base);
    margin-bottom: var(--spacing-sm);
    transition: all var(--transition-fast);
  }
  .card:hover {
    background: var(--color-card-bg-hover);
  }

  /* 按钮基础样式 */
  .btn {
    height: var(--btn-height-default);
    padding: 0 var(--spacing-lg);
    border: none;
    border-radius: var(--radius-button);
    background: var(--color-card-bg);
    backdrop-filter: var(--blur-light);
    -webkit-backdrop-filter: var(--blur-light);
    color: var(--color-primary);
    cursor: pointer;
    transition: all var(--transition-fast);
    font-family: var(--font-family-body);
    font-size: 15px;
    font-weight: 600;
  }
  .btn-primary {
    background: var(--color-primary);
    color: #fff;
  }
  .btn:active {
    transform: scale(0.96);
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
    background: rgba(0, 0, 0, 0.05);
  }

  /* 毛玻璃列表分组 */
  .list-group {
    background: var(--color-card-bg);
    backdrop-filter: var(--blur-medium);
    -webkit-backdrop-filter: var(--blur-medium);
    border-radius: var(--radius-card);
    overflow: hidden;
    margin-bottom: var(--spacing-base);
  }

  /* 输入框基础样式 */
  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-sm);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    background: rgba(255, 255, 255, 0.6);
    backdrop-filter: var(--blur-light);
    -webkit-backdrop-filter: var(--blur-light);
    color: var(--color-text-primary);
    font-family: var(--font-family-body);
    font-size: 16px;
  }
  .input:focus {
    outline: none;
    border-color: var(--color-primary);
    background: rgba(255, 255, 255, 0.8);
  }

  /* 顶部导航栏 - 毛玻璃 */
  .navbar {
    height: calc(var(--navbar-height) + var(--safe-area-bottom));
    background: var(--color-card-bg);
    backdrop-filter: var(--blur-heavy);
    -webkit-backdrop-filter: var(--blur-heavy);
    border-bottom: 1px solid var(--color-border-glass);
    display: flex;
    align-items: flex-end;
    padding: 0 var(--spacing-base) var(--spacing-xs);
    position: sticky;
    top: 0;
    z-index: 100;
  }

  /* 底部 Tab 栏 - 毛玻璃 */
  .tabbar {
    height: calc(var(--tabbar-height) + var(--safe-area-bottom));
    background: var(--color-card-bg);
    backdrop-filter: var(--blur-heavy);
    -webkit-backdrop-filter: var(--blur-heavy);
    border-top: 1px solid var(--color-border-glass);
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
    cursor: pointer;
    transition: color var(--transition-fast);
  }
  .tabbar-item.active {
    color: var(--color-primary);
  }

  /* FAB 毛玻璃按钮 */
  .fab {
    width: var(--fab-size);
    height: var(--fab-size);
    border-radius: var(--radius-fab);
    background: var(--color-card-bg);
    backdrop-filter: var(--blur-medium);
    -webkit-backdrop-filter: var(--blur-medium);
    color: var(--color-primary);
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-glass);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    position: fixed;
    right: var(--spacing-base);
    bottom: calc(var(--tabbar-height) + var(--safe-area-bottom) + var(--spacing-base));
    z-index: 50;
    transition: all var(--transition-fast);
  }
  .fab:active {
    transform: scale(0.95);
  }

  /* 响应式断点 */
  @media (max-width: 1440px) { /* 大屏适配 */ }
  @media (max-width: 1024px) { /* 平板适配 */ }
  @media (max-width: 768px) { /* 小平板适配 */ }
  @media (max-width: 375px) { /* 手机适配 */ }
</style>
```
