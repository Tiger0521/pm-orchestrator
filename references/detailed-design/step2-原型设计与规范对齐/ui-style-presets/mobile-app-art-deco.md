# 风格预设：艺术装饰 - Mobile App

## 基本信息
- 平台: Mobile App
- 风格: 艺术装饰（Art Deco）
- 适用场景: 奢侈品电商、高端会员服务、精品酒店预订、收藏品展示 App

## 设计 Token
| Token | 值 |
| ---- | ---- |
| 主色 | #C9A45C |
| 辅助色 | #0F2E25 |
| 警告色 | #D4A017 |
| 错误色 | #B0413E |
| 背景色 | #0F2E25 |
| 卡片背景 | #14382D |
| 文字主色 | #F5F0E6 |
| 文字次色 | #8FA89B |
| 边框色 | #2A4A3E |
| 圆角 | 0px (几何直角) / 2px (输入框) |
| 间距基数 | 8px (4/8/12/16/24/32)，对称布局，左右边距相等 |

## 字体配对
| 用途 | 字体 | 回退 |
| ---- | ---- | ---- |
| 标题 | Cormorant Garamond SemiBold | 思源宋体 Medium, serif |
| 正文 | Montserrat Regular | 思源黑体 Regular, system-ui |
| 等宽 | Space Mono | SF Mono, Consolas, monospace |

## 组件风格
| 组件 | 规格 |
| ---- | ---- |
| 按钮 | 高度 48px，直角，金色细描边 1px 透明底（幽灵按钮为主）；主操作金色填充墨绿字 |
| 卡片 | 直角，深绿底，金色细边框 1px，顶部居中扇形/太阳纹装饰线条 |
| 列表 | 对称网格（2 列等宽），卡片间距 16px，图标居中对称 |
| 表单 | 输入框高度 48px，直角，深绿底金色底线，标签小号大写间距加宽 |
| 弹窗 | 底部抽屉式，直角顶部居中金色菱形分隔符，对称留白 |
| 底部导航 | 高 64px + 安全区，墨绿底金色上边线 1px，活跃项金色图标 + 菱形下标记 |
| 分隔符 | 居中装饰性分隔：菱形 ◆ + 两侧金色细线（代替普通 hr） |

## 动效规则
| 场景 | 动效 |
| ---- | ---- |
| 页面切换 | 优雅淡入 250ms（不位移，保持庄重） |
| 卡片入场 | 对称展开（中心向两侧 reveal）300ms |
| 按钮 active | 金色描边内发光 150ms |
| 底部导航切换 | 菱形标记水平滑动 200ms |
| 图片加载 | 淡入 + 轻微放大 1.02 → 1 收敛 400ms |

## 反"AI 味"硬规则
- 禁止 emoji 图标，必须用 SVG 图标（细线几何风格，线宽 1px，可用金色描边）
- 禁止紫色渐变背景
- 禁止使用 Inter / Roboto / Arial 作为主标题字体（标题必须衬线 Garamond 系）
- hover / focus / active 三态必须完整实现（反馈克制但不缺席）
- 对比度达到 WCAG AA 4.5:1 标准（金色 #C9A45C 用于大字和装饰，小号正文用象牙白）
- 触控区域最小 44x44px（本风格按钮统一 48px）
- 动画时长 150-300ms
- 对称纪律：Art Deco 的灵魂是对称——列表、卡片、分隔符一律居中对称，禁止随手左对齐堆砌
- 金色细线原则：装饰靠 1px 金线、菱形、扇形纹样，不靠渐变和阴影堆砌
- 安全区适配：底部导航 padding 需处理 iOS Home Indicator（env(safe-area-inset-bottom)）
- 每个页面有独立视觉记忆点（本风格通常是居中扇形纹 + 衬线大标题）

## HTML 生成模板（供交互式 HTML 方式直接引用）

```html
<style>
  :root {
    --color-primary: #C9A45C;
    --color-primary-hover: #D9B878;
    --color-primary-active: #B08D46;
    --color-secondary: #0F2E25;
    --color-warning: #D4A017;
    --color-error: #B0413E;
    --color-bg: #0F2E25;
    --color-card-bg: #14382D;
    --color-text-primary: #F5F0E6;
    --color-text-secondary: #8FA89B;
    --color-border: #2A4A3E;
    --color-gold: #C9A45C;
    --radius-card: 0px;
    --radius-button: 0px;
    --radius-input: 2px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-base: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    --font-family-title: 'Cormorant Garamond', '思源宋体', serif;
    --font-family-body: 'Montserrat', '思源黑体', system-ui, sans-serif;
    --font-family-mono: 'Space Mono', 'SF Mono', Consolas, monospace;
    --transition-fast: 150ms ease;
    --transition-base: 200ms ease;
    --transition-slow: 250ms ease;
    --btn-height: 48px;
    --input-height: 48px;
    --tabbar-height: 64px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family-body);
    background: var(--color-bg);
    color: var(--color-text-primary);
    line-height: 1.6;
    min-height: 100vh;
  }

  .phone-frame {
    max-width: 414px;
    margin: 0 auto;
    min-height: 100vh;
    padding-bottom: calc(var(--tabbar-height) + env(safe-area-inset-bottom, 0px));
  }

  .page-header {
    padding: var(--spacing-lg) var(--spacing-base) var(--spacing-base);
    text-align: center;
  }
  .page-title {
    font-family: var(--font-family-title);
    font-size: 34px;
    font-weight: 600;
    letter-spacing: 0.04em;
    line-height: 1.2;
  }
  .page-subtitle {
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.25em;
    color: var(--color-gold);
    margin-top: var(--spacing-xs);
  }

  .deco-divider {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--spacing-sm);
    margin: var(--spacing-base) 0;
  }
  .deco-divider::before,
  .deco-divider::after {
    content: '';
    height: 1px;
    width: 64px;
    background: linear-gradient(90deg, transparent, var(--color-gold));
  }
  .deco-divider::after {
    background: linear-gradient(90deg, var(--color-gold), transparent);
  }
  .deco-diamond {
    width: 8px;
    height: 8px;
    background: var(--color-gold);
    transform: rotate(45deg);
  }

  .card {
    background: var(--color-card-bg);
    border: 1px solid var(--color-gold);
    padding: var(--spacing-base);
    position: relative;
    text-align: center;
    transition: border-color var(--transition-fast);
  }
  .card:active { border-color: var(--color-primary-hover); }

  .card::before {
    content: '';
    position: absolute;
    top: 0; left: 50%;
    transform: translateX(-50%);
    width: 48px;
    height: 2px;
    background: var(--color-gold);
  }

  .grid-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--spacing-base);
    padding: 0 var(--spacing-base);
  }

  .btn {
    height: var(--btn-height);
    padding: 0 var(--spacing-lg);
    border-radius: var(--radius-button);
    border: 1px solid var(--color-gold);
    background: transparent;
    color: var(--color-gold);
    cursor: pointer;
    font-family: var(--font-family-body);
    font-size: 13px;
    font-weight: 500;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    transition: background var(--transition-fast), color var(--transition-fast), box-shadow var(--transition-fast);
  }
  .btn:active {
    box-shadow: inset 0 0 12px rgba(201, 164, 92, 0.25);
  }
  .btn-primary {
    background: var(--color-gold);
    color: var(--color-bg);
  }
  .btn-primary:active {
    background: var(--color-primary-active);
  }

  .input {
    height: var(--input-height);
    padding: 0 var(--spacing-sm);
    border: none;
    border-bottom: 1px solid var(--color-border);
    border-radius: var(--radius-input);
    background: var(--color-card-bg);
    color: var(--color-text-primary);
    font-size: 15px;
    width: 100%;
    text-align: center;
    transition: border-color var(--transition-fast);
  }
  .input:focus {
    border-bottom-color: var(--color-gold);
    outline: none;
  }

  .form-label {
    display: block;
    text-align: center;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.2em;
    color: var(--color-text-secondary);
    margin-bottom: var(--spacing-xs);
  }

  .tabbar {
    position: fixed;
    left: 0; right: 0; bottom: 0;
    height: calc(var(--tabbar-height) + env(safe-area-inset-bottom, 0px));
    padding-bottom: env(safe-area-inset-bottom, 0px);
    background: var(--color-bg);
    border-top: 1px solid var(--color-gold);
    display: flex;
    justify-content: space-around;
    align-items: center;
    z-index: 40;
  }
  .tabbar-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    min-width: 56px;
    min-height: 44px;
    justify-content: center;
    cursor: pointer;
    color: var(--color-text-secondary);
    position: relative;
    transition: color var(--transition-fast);
  }
  .tabbar-item.active { color: var(--color-gold); }
  .tabbar-item.active::after {
    content: '';
    position: absolute;
    bottom: 4px;
    width: 5px;
    height: 5px;
    background: var(--color-gold);
    transform: rotate(45deg);
  }

  @media (max-width: 1440px) { }
  @media (max-width: 1024px) { }
  @media (max-width: 768px) { }
  @media (max-width: 375px) { }
</style>
```
