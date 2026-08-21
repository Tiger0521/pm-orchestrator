# 风格预设：活力撞色 - Mobile App

## 基本信息
- 平台: Mobile App
- 风格: 活力撞色
- 适用场景: 年轻人社交、运动健身、创意社区、潮牌电商 App

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #FF2E88 |
| 辅助色 | #1B6CFF |
| 警告色 | #FF8A00 |
| 错误色 | #E5484D |
| 背景色 | #FFD233 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #141414 |
| 文字次色 | #5C5C38 |
| 边框色 | #141414 |
| 圆角 | 16px (卡片) / 999px (按钮胶囊) / 0px (强调块) |
| 间距基数 | 8px (4/8/12/16/24/32) |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Archivo Black | 思源黑体 Heavy, system-ui |
| 正文 | Inter Regular | 思源黑体 Regular, system-ui |
| 等宽 | Space Mono | SF Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 52px（触控优先），胶囊圆角 999px，品红填充黑描边 2px，按下位移 2px |
| 卡片 | 圆角 16px，白底，2px 黑描边，硬阴影 4px 4px 0 #141414（不模糊） |
| 列表 | 大图卡片流，卡片间距 16px，图片占卡片 60% 高度 |
| 表单 | 输入框高度 52px，圆角 12px，白底黑描边 2px，焦点描边变品红 |
| 弹窗 | 底部抽屉式（bottom sheet），圆角顶部 24px，黄色底，黑描边 |
| 底部导航 | 高 64px + 安全区，白底黑顶线，活跃项品红底圆形色块 + 黑图标 |
| 标签 chip | 胶囊形，撞色填充（蓝/黄/品红轮换），黑描边 1.5px |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 横向推入 250ms（有方向感） |
| 卡片入场 | 列表 staggered 入场，每张延迟 60ms，上移 + 淡入 |
| 按钮按压 | 位移 2px + 硬阴影消失 100ms（实体按压感） |
| 底部导航切换 | 图标弹性缩放 1 → 1.15 → 1（spring 曲线 200ms） |
| 点赞/收藏 | 图标弹跳 + 撞色粒子迸发 300ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标（粗描边 2px 填充风格）
- 禁止紫色渐变背景（本风格靠撞色不靠渐变）
- 禁止使用 Inter / Roboto / Arial 作为主标题字体（标题必须 Archivo Black 级别的重无衬线）
- hover / focus / active 三态必须完整实现（移动端重点是 active 按压态）
- 对比度达到 WCAG AA 4.5:1 标准（黄底黑字天然达标，品红底用白字需过检）
- 触控区域最小 44x44px（本风格按钮统一 52px）
- 动画时长 150-300ms
- 撞色纪律：一套界面最多 3 个亮色（黄底 + 品红 + 电蓝），不可再加第四色
- 硬阴影不模糊：4px 4px 0 纯色偏移阴影是本风格签名，禁止改成柔和大阴影
- 安全区适配：底部导航 padding 需处理 iOS Home Indicator（env(safe-area-inset-bottom)）
- 每个页面有独立视觉记忆点

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #FF2E88;
    --color-primary-hover: #FF559F;
    --color-primary-active: #D91F73;
    --color-secondary: #1B6CFF;
    --color-warning: #FF8A00;
    --color-error: #E5484D;
    --color-bg: #FFD233;
    --color-card-bg: #FFFFFF;
    --color-text-primary: #141414;
    --color-text-secondary: #5C5C38;
    --color-border: #141414;
    --radius-card: 16px;
    --radius-button: 999px;
    --radius-input: 12px;
    --radius-sheet: 24px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    --font-family-title: 'Archivo Black', '思源黑体 Heavy', system-ui, sans-serif;
    --font-family-body: 'Inter', '思源黑体 Regular', system-ui, sans-serif;
    --font-family-mono: 'Space Mono', 'SF Mono', Consolas, monospace;
    --transition-fast: 100ms ease;
    --transition-base: 150ms ease;
    --transition-slow: 250ms ease;
    --btn-height: 52px;
    --input-height: 52px;
    --tabbar-height: 64px;
    --shadow-hard: 4px 4px 0 #141414;
    --shadow-hard-sm: 2px 2px 0 #141414;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.5;
    min-height: 100vh;
  }

  .phone-frame {
    max-width: 414px;
    margin: 0 auto;
    min-height: 100vh;
    position: relative;
    padding-bottom: calc(var(--tabbar-height) + env(safe-area-inset-bottom, 0px));
  }

  .page-header {
    padding: var(--spacing-lg) var(--spacing-base) var(--spacing-base);
  }
  .page-title {
    font-family: var(--font-family-title);
    font-size: 32px;
    line-height: 1.1;
    text-transform: uppercase;
    letter-spacing: -0.5px;
  }

  .card {
    background: var(--color-card-bg);
    border-radius: var(--radius-card);
    border: 2px solid var(--color-border);
    box-shadow: var(--shadow-hard);
    padding: var(--spacing-base);
    margin-bottom: var(--spacing-base);
    transition: transform var(--transition-fast), box-shadow var(--transition-fast);
  }
  .card:active {
    transform: translate(2px, 2px);
    box-shadow: var(--shadow-hard-sm);
  }

  .chip {
    display: inline-block;
    padding: 6px 14px;
    border-radius: var(--radius-button);
    border: 1.5px solid var(--color-border);
    font-size: 13px;
    font-weight: 600;
    margin-right: var(--spacing-sm);
  }
  .chip-pink { background: var(--color-primary); color: #fff; }
  .chip-blue { background: var(--color-secondary); color: #fff; }
  .chip-white { background: var(--color-card-bg); color: var(--color-text-primary); }

  .btn {
    height: var(--btn-height);
    padding: 0 var(--spacing-lg);
    border-radius: var(--radius-button);
    border: 2px solid var(--color-border);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    cursor: pointer;
    font-family: var(--font-family-body);
    font-size: 16px;
    font-weight: 700;
    box-shadow: var(--shadow-hard-sm);
    transition: transform var(--transition-fast), box-shadow var(--transition-fast), background var(--transition-fast);
  }
  .btn:active {
    transform: translate(2px, 2px);
    box-shadow: none;
  }
  .btn-primary {
    background: var(--color-primary);
    color: #fff;
  }
  .btn-primary:active {
    background: var(--color-primary-active);
  }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-base);
    border-radius: var(--radius-input);
    border: 2px solid var(--color-border);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    font-size: 16px;
    width: 100%;
    transition: border-color var(--transition-fast);
  }
  .input:focus {
    border-color: var(--color-primary);
    outline: none;
  }

  .bottom-sheet {
    position: fixed;
    left: 0; right: 0; bottom: 0;
    background: var(--color-bg);
    border-top: 2px solid var(--color-border);
    border-radius: var(--radius-sheet) var(--radius-sheet) 0 0;
    padding: var(--spacing-lg) var(--spacing-base) calc(var(--spacing-lg) + env(safe-area-inset-bottom, 0px));
    transform: translateY(100%);
    transition: transform var(--transition-slow) cubic-bezier(0.32, 0.72, 0, 1);
    z-index: 50;
  }
  .bottom-sheet.open { transform: translateY(0); }

  .tabbar {
    position: fixed;
    left: 0; right: 0; bottom: 0;
    height: calc(var(--tabbar-height) + env(safe-area-inset-bottom, 0px));
    padding-bottom: env(safe-area-inset-bottom, 0px);
    background: var(--color-card-bg);
    border-top: 2px solid var(--color-border);
    display: flex;
    justify-content: space-around;
    align-items: center;
    z-index: 40;
  }
  .tabbar-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    min-width: 56px;
    min-height: 44px;
    justify-content: center;
    cursor: pointer;
    color: var(--color-text-primary);
  }
  .tabbar-item.active {
    color: var(--color-primary);
  }
  .tabbar-item.active .tab-icon {
    background: var(--color-primary);
    color: #fff;
    border-radius: 50%;
    transform: scale(1.05);
  }
  .tab-icon {
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform 200ms cubic-bezier(0.34, 1.56, 0.64, 1);
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
