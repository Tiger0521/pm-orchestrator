# 高保真HTML原型生成指南

本文档说明如何基于 prototype-framework.js 生成可交互的高保真HTML原型页面。

## CSS 变量注入模板（必读）

**无论是否有参考图，所有原型 HTML 的 `:root` 都必须注入 CSS 变量。** 后续所有组件样式使用 `var(--xxx)` 引用，而非硬编码色值。

### 有参考图时（从 Step 0 提取的 `--ref-*` 变量）

```css
:root {
  /* ===== 从参考图提取的设计规范 ===== */
  --primary-color: #1677ff;
  --primary-hover: #4096ff;
  --success-color: #52c41a;
  --warning-color: #faad14;
  --danger-color: #ff4d4f;
  --bg-color: #f5f5f5;
  --card-bg: #ffffff;
  --text-primary: #262626;
  --text-secondary: #595959;
  --text-muted: #8c8c8c;
  --border-color: #d9d9d9;
  --border-light: #f0f0f0;
  --font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Microsoft YaHei', sans-serif;
  --font-size-sm: 12px;
  --font-size: 14px;
  --font-size-lg: 16px;
  --font-size-xl: 18px;
  --radius: 6px;
  --radius-lg: 8px;
  --shadow: 0 1px 2px rgba(0,0,0,0.06);
  --shadow-hover: 0 4px 12px rgba(0,0,0,0.08);
  --nav-height: 56px;
  --input-height: 32px;
  --btn-padding: 4px 16px;
}
/* 所有组件样式使用 var() 引用，而非硬编码 */
body { background: var(--bg-color); color: var(--text-primary); }
.button { background: var(--primary-color); border-radius: var(--radius); }
```

### 无参考图时（Ant Design 5.x 默认值）

```css
:root {
  --primary-color: #1677ff;
  --primary-hover: #4096ff;
  --success-color: #52c41a;
  --warning-color: #faad14;
  --danger-color: #ff4d4f;
  --bg-color: #f5f5f5;
  --card-bg: #ffffff;
  --text-primary: #262626;
  --text-secondary: #595959;
  --text-muted: #8c8c8c;
  --border-color: #d9d9d9;
  --border-light: #f0f0f0;
  --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
  --font-size-sm: 12px;
  --font-size: 14px;
  --font-size-lg: 16px;
  --font-size-xl: 18px;
  --radius: 6px;
  --radius-lg: 8px;
  --shadow: 0 1px 2px rgba(0,0,0,0.06);
  --shadow-hover: 0 4px 12px rgba(0,0,0,0.08);
  --nav-height: 56px;
  --input-height: 32px;
  --btn-padding: 4px 16px;
}
```

**强制规则**：生成原型时，禁止在 CSS 中硬写色值/圆角/字号。一律使用 `var(--xxx)` 引用。这样当后续需要更换设计系统或对齐新参考图时，只需修改 `:root` 中的变量值即可。

## 完整 HTML 模板结构

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>原型：{[页面名称]}</title>
  <style>
    /* ===== CSS 变量注入（从参考图提取 或 Ant Design 默认） ===== */
    :root {
      --primary-color: #1677ff;
      --primary-hover: #4096ff;
      --bg-color: #f5f5f5;
      --card-bg: #ffffff;
      --text-primary: #262626;
      --text-secondary: #595959;
      --text-muted: #8c8c8c;
      --border-color: #d9d9d9;
      --border-light: #f0f0f0;
      --font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Microsoft YaHei', sans-serif;
      --font-size: 14px;
      --radius: 6px;
      --radius-lg: 8px;
      --shadow: 0 1px 2px rgba(0,0,0,0.06);
      --input-height: 32px;
      --nav-height: 56px;
    }

    /* ===== 全局重置 & 基础样式 ===== */
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: var(--font-family);
      background: var(--bg-color);
      color: var(--text-primary);
      font-size: var(--font-size);
      min-height: 100vh;
    }

    /* ===== 页面布局样式 (使用 var() 引用 CSS 变量) ===== */
    /* ... 你的页面样式写在这里 ... */
  </style>
</head>
<body>

  <!-- ===== 页面 UI 内容 ===== -->
  <!-- 构建你的页面原型 -->

  <!-- ===== 注释引擎（直接内联，避免 data URI 在某些浏览器中加载异常） ===== -->
  <script>{[将 prototype-framework.js 的内容直接内联在此处]}</script>
  <script>
    // ===== 注册页面注释 =====
    // 使用 __onAnnotationsReady 确保注释在框架初始化完成后才注册
    // 不要使用 DOMContentLoaded，因为框架的初始化顺序可能存在竞争
    window.__onAnnotationsReady = function () {

      // 用法1 (推荐): 相对于元素自动定位
      __addAnnotationOn('#searchInput', 'right', {
        title: '搜索框交互说明',
        description: '输入关键词后，300ms防抖自动搜索。支持回车触发搜索。为空时展示最近搜索记录。',
        type: 'interaction'
      });

      // 用法2 (手动): 指定精确坐标
      __addAnnotation({
        title: '表格操作权限',
        description: '普通用户仅可查看本部门数据；管理员可编辑和删除；超级管理员可查看全部。',
        type: 'permission',
        x: 400,
        y: 320,
      });

      // ... 更多注释
    };
    });
  </script>
</body>
</html>
```

## 注释类型说明

| type | 中文 | 颜色 | 用途 |
|------|------|------|------|
| `interaction` | 交互说明 | 蓝 #1677ff | 点击、悬停、弹窗、路由跳转、输入校验等交互行为描述 |
| `business` | 业务逻辑 | 橙 #fa8c16 | 数据规则、计算逻辑、状态流转、排序算法、审核流程等 |
| `edgecase` | 边界异常 | 红 #ff4d4f | 空数据态、网络异常、重复提交、权限不足、加载失败等 |
| `permission` | 权限规则 | 绿 #52c41a | 角色可见范围、操作权限、字段权限、数据隔离等 |
| `note` | 备注 | 紫 #722ed1 | 待确认点、研发注意事项、产品备注等 |

## 交互式元素要求

生成的HTML原型应具备基本的可交互性，满足评审和演示需求：

1. **导航/Tab切换**：点击Tab或导航项时切换显示对应的内容区块
2. **弹窗/模态框**：点击"新增/编辑/详情"等按钮时弹出对应的模态框
3. **折叠/展开**：侧边栏、筛选面板等支持展开收起
4. **数据模拟**：使用内联模拟数据(JSON数组)填充表格、列表、图表
5. **分页**：点击分页按钮时切换数据页
6. **表单**：输入框可输入，下拉框可选，但不需要提交后端

## 设计系统 (PC Web)

所有原型必须使用 CSS 变量注入模式。以下是各变量的含义和默认值（Ant Design 5.x）：

| CSS 变量 | 默认值 | 用途 |
|----------|--------|------|
| `--primary-color` | `#1677ff` | 主色/按钮/链接/选中态 |
| `--primary-hover` | `#4096ff` | 主色悬浮态 |
| `--success-color` | `#52c41a` | 成功状态 |
| `--warning-color` | `#faad14` | 警告状态 |
| `--danger-color` | `#ff4d4f` | 危险/错误状态 |
| `--bg-color` | `#f5f5f5` | 页面背景 |
| `--card-bg` | `#ffffff` | 卡片/容器背景 |
| `--text-primary` | `#262626` | 主文字色 |
| `--text-secondary` | `#595959` | 次要文字色 |
| `--text-muted` | `#8c8c8c` | 辅助文字色 |
| `--border-color` | `#d9d9d9` | 边框色 |
| `--border-light` | `#f0f0f0` | 浅分割线色 |
| `--radius` | `6px` | 组件圆角 |
| `--radius-lg` | `8px` | 卡片圆角 |
| `--shadow` | `0 1px 2px rgba(0,0,0,0.06)` | 卡片默认阴影 |
| `--shadow-hover` | `0 4px 12px rgba(0,0,0,0.08)` | 卡片悬浮阴影 |
| `--input-height` | `32px` | 输入框高度 |
| `--nav-height` | `56px` | 导航栏高度 |

## 小功能迭代输出规范

对于小功能迭代（非0-1大项目），应采用轻量化输出模式：

1. **原型为主**：直接生成可交互HTML原型，原型上带注释标题即可
2. **注释精简**：每个注释的description控制在3行以内，只说明"改了啥"和"为什么"
3. **不写PRD**：不需要输出独立的PRD文档，所有信息都在原型的注释中体现
4. **变更标注**：迭代版本中，在页面上方的"版本标注栏"用不同颜色区分新增/修改/删除的模块；**版本标注栏容器统一写 `<div id="aptVersionBar"></div>`**，迭代原型中框架会自动往里面追加版本记录（见「版本管理与回退」章节）

## 版本管理与回退（框架代管，v1.2）

prototype-framework.js v1.2 起，版本号由框架代管：**每次「框选确认修改」自动升版（V1.0→V1.1…）并记录版本台账**，AI 不再需要手工算版本号（AI 直接改文件的场景除外，仍按 SKILL.md「修改模式执行前必读」门禁手动升版）。

### 工作机制

| 环节 | 行为 |
|------|------|
| 框选确认修改 | 自动升版；版本号写入请求文本（`版本号: 1.1`）；记录台账条目（版本/日期/变更描述）；尝试保存当前页面快照 |
| aptVersion 标注 | 工具条里的灰色版本标注由 JS 驱动，升版后自动同步（如 `原型 V1.1`）；保留页面原有的“原型 V”/“原型 ”前缀写法 |
| 版本标注栏 | 页面有 `id="aptVersionBar"`（或 `data-apt-version-bar`）容器时，自动追加 `v1.1 · 日期 变更摘要` 条目 |
| 本地台账 | localStorage 中按页面标题指纹隔离存储（最多 30 条）；不可用时降级为会话内存，刷新后消失（面板会提示） |
| 快照 | 各版本确认时的页面状态存 localStorage（最多 6 份、单份 ≤450KB，超限自动清理最旧）；快照已剔除运行时注入的工具栏/面板，重新打开时框架会重建 |

### 「📜 版本」工具条按钮

工具栏新增「📜 版本」按钮，点击弹出版本面板：

- **当前版本 + 台账列表**：每行 = 一个版本（版本号 / 日期 / 变更摘要）
- **导出当前页面 / 导出（某版本）**：Chromium 内核浏览器（Chrome/Edge）会先弹出**系统保存位置选择**，可直接选产品库 `详细设计/原型/`（过程文件夹）落成文件随项目留档；其他浏览器或取消时回退为下载到浏览器默认下载目录（也可对页面 Ctrl+S 另存为任意路径）。**用文件保存旧版本是最可靠的留存方式**（可配合 git / 文件历史）
- **快照落盘约定（AI 侧）**：AI 每次迭代落盘交付新版本前，先把**当前（修改前）版本**另存为 `<简称>-原型-vX.X.html` 快照文件写入产品库 `详细设计/原型/` 过程文件夹，与新版并存 —— 项目文件夹里的快照文件才是正式版本史（可进 git），浏览器导出只是应急通道
- **回退（某版本）**：有快照 → 新标签页打开该版本快照（原文件不受影响，可 Ctrl+S 另存为替换）；无快照 → 生成「回退指令」文本复制给 AI，让 AI 把文件改回该版本
- 存储不可用时面板给出提示：台账仅本次会话有效、刷新后消失

### 生成原型时的必做事项

1. **版本标注栏容器**：轻量模式/迭代原型在页面顶部放 `<div id="aptVersionBar"></div>`（样式自定），框架自动追加变更记录，与「更新版本标注栏」门禁匹配
2. **不要手工写死版本号**：`aptVersion` 标注初始值由生成时写（如 `原型 V1.0`），之后浏览器内的升版由框架自动完成；AI 落盘时把文件内标注/版本标注栏同步为请求文本里的 `version`（不要重复升号）
3. **页面标题要唯一**：台账按「标题」隔离，同名标题的多个原型会共享台账（file:// 下 localStorage 是共享域名，靠标题区分）
4. **快照落盘到过程文件夹**：AI 每次迭代落盘前先把修改前的旧版本另存快照文件（`<简称>-原型-vX.X.html`）写入产品库 `详细设计/原型/`，与新版并存；正式版本史以这些快照文件 + git 为准，浏览器内快照/导出只是应急通道

### API 速查（v1.2 新增）

| API | 说明 |
|-----|------|
| `window.__getPrototypeVersion()` | 返回当前版本号（如 `'1.1'`） |
| `window.__getVersionHistory()` | 返回版本台账数组（副本） |

## 参考图复刻指南（CSS 变量模式）

当用户提供参考截图时（已在 SKILL.md Step 0 完成提取），按以下规则注入样式：

### 1. 将提取值注入 :root CSS 变量

```css
:root {
  --primary-color: 【从参考图提取的主色, 如 #1677ff】;
  --bg-color: 【页面背景色】;
  --card-bg: 【卡片背景色】;
  --text-primary: 【主文字色】;
  --border-color: 【边框色】;
  --radius: 【组件圆角】;
  --input-height: 【输入框高度】;
  --nav-height: 【导航栏高度】;
  /* ... 所有 Step 0 提取的变量 ... */
}
```

### 2. 所有组件样式使用 var() 引用

所有 CSS 中的色值、圆角、字号用 `var(--xxx)` 引用，绝不能出现硬编码：
- ❌ 错误：`button { background: #1677ff; border-radius: 6px; }`
- ✅ 正确：`button { background: var(--primary-color); border-radius: var(--radius); }`

### 3. 视觉对齐检查

生成原型后，逐项比对参考图与原型的一致性：
- 主色调是否一致
- 按钮样式（圆角、高度、填充色）是否一致
- 输入框样式（高度、边框色、focus态）是否一致
- 表格样式（表头色、行高、边框）是否一致
- 导航栏样式（高度、背景、字体）是否一致

### 4. 注释标注类型

在 type: 'note' 的注释中标注样式来源。格式参考：
- "导航栏样式复刻自参考图（高度56px，白色背景，底部1px #e8e8e8 边框）"
- "按钮样式复刻自参考图（蓝色填充，圆角6px，高度32px，padding 4px 16px）"
- "表格样式复刻自参考图（表头灰底#fafafa，行悬浮变色，12px表头字号）"

## 辅助API：__addAnnotationOn(selector, position, opts)

`__addAnnotationOn` 是框架内置的智能定位函数，推荐在所有原型中使用。

### 用法

```javascript
__addAnnotationOn('#目标元素CSS选择器', '位置', {
  title: '注释标题',
  description: '注释内容',
  type: 'interaction'   // interaction | business | edgecase | permission | note
});
```

### position 参数

| 值 | 说明 | 标记位置 |
|----|------|---------|
| `'right'` | 目标右侧 (默认) | `target.right + 10px` |
| `'left'` | 目标左侧 | `target.left - 34px` |
| `'top'` | 目标上方 | `target.top - 34px` |
| `'bottom'` | 目标下方 | `target.bottom + 10px` |

### 优势

- **自动计算坐标**：基于 `getBoundingClientRect()`，不再需要手动算偏移
- **居中布局兼容**：无论元素在页面的什么位置（居中/偏移/弹窗内），标记位置都正确
- **视口约束**：自动限制在视口范围内，不会超出屏幕边界
- **高亮绑定**：自动设置 `targetSelector`，点击注释时高亮目标元素

### 各组件定位规则

| 组件类型 | 标记定位公式 | 说明 |
|----------|-------------|------|
| **顶部导航栏按钮**（提问/通知/头像） | `x = 按钮左侧-10, y = 按钮top+5` | 放在按钮左上方，不遮挡按钮文字 |
| **搜索框** | `x = 搜索框右侧+10, y = 搜索框top+8` | 放在搜索框右侧，对齐高度 |
| **Tab 切换栏** | `x = 选中Tab右侧+10, y = tab栏bottom+5` | 放在当前Tab右上 |
| **侧边栏菜单项** | `x = 菜单项左侧-28, y = 菜单项top+8` | 放在菜单项左侧，circle在菜单左侧显示 |
| **卡片/列表** | `x = 卡片右侧-20, y = 卡片top+10` | 放在卡片右上角，不遮挡内容 |
| **分页器** | `x = 分页区域右侧+10, y = 分页top+5` | 放在分页器右侧 |
| **弹窗/模态框** | `x = 弹窗右上角-20, y = 弹窗top+10` | 放在弹窗右上角 |
| **表格** | `x = 表格右上-20, y = 表头top+8` | 放在表格表头右上 |
| **表单字段** | `x = 字段右侧+8, y = 字段top-5` | 放在字段右上方 |

### 获取坐标的方法

当生成原型时，根据页面布局和固定定位计算坐标：

```
示例 - 导航栏在 top:0, height:56px:
- 搜索框在 x≈320, y≈12（相对于导航栏内）
- 所以全局 y = 56 + 12 = 68, x = 320

示例 - 侧边栏 sidebar:
- "产品"菜单项在 sidebar y≈140（相对于sidebar top）
- sidebar 本身 fixed 在 top:56
- 所以全局 y = 56 + 140 = 196, x = 24

示例 - 主内容区卡片:
- 第一张卡片在 main-content 内 y≈80, x≈260
- main-content margin-left:220 (sidebar宽度) + padding:32
- 所以全局 x = 220 + 32 + 260 = 512, y = 56(nav) + 80 = 136
```

### 注意事项

- 标记之间保持至少 40px 间距，避免视觉重叠
- 标记优先放在组件的右上/右外侧，不遮挡组件内容
- 如果标记会遮挡重要内容，放在相对空旷的一侧
- 多个标记在同一区域时，沿对角线错开排列

## 多屏并排展示模式（Side-by-Side Multi-Screen）

当原型包含多个页面且需要**同时可见**时（如移动端登录+注册两个手机并排展示），使用多屏并排模式。

### 何时使用

| 场景 | 模式 | 说明 |
|------|------|------|
| PC 后台多 Tab 页面切换 | 传统多页模式 | 侧边栏点击切换，同时只显示一个页面 |
| 移动端登录+注册并排 | **多屏并排模式** | 两个手机同时可见，点击"注册"滚动到右侧 |
| 流程对比（如审批前后） | **多屏并排模式** | 左右并排展示流程变更前后状态 |
| 单页面 | 单页模式 | 默认，无需特殊处理 |

### 布局模板

```html
<!-- 多屏容器：flex 横向排列 -->
<div style="display:flex; gap:60px; justify-content:center; padding:40px 20px;">

  <!-- 屏幕 1：登录页 -->
  <div class="phone-mockup page-section active" id="pageLogin">
    <!-- 手机外框 + 页面内容 -->
    <div class="phone-frame">
      <div class="phone-screen">
        <!-- 登录页 UI -->
      </div>
    </div>
  </div>

  <!-- 屏幕 2：注册页 -->
  <div class="phone-mockup page-section active" id="pageRegister">
    <div class="phone-frame">
      <div class="phone-screen">
        <!-- 注册页 UI -->
      </div>
    </div>
  </div>

</div>
```

**关键区别**：
- 传统多页模式：`page-section` 默认 `display: none`，只有 `.active` 为 `display: block`
- 多屏并排模式：**所有** `page-section` 都有 `active` class（都 `display: block`），用 flex 横向排列

### 页面切换（滚动定位）

```javascript
// 点击"立即注册" → 滚动到注册页
function switchToRegister() {
  document.getElementById('pageRegister').scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// 点击"返回登录" → 滚动到登录页
function switchToLogin() {
  document.getElementById('pageLogin').scrollIntoView({ behavior: 'smooth', block: 'center' });
}
```

### 启用多屏模式 + 注册注释

```javascript
(function() {
  function register() {
    if (typeof window.__setMultiScreenMode !== 'function') {
      setTimeout(register, 50);
      return;
    }

    // ① 启用多屏模式，传入页面标签（Tab 显示用）
    window.__setMultiScreenMode(true, {
      'pageLogin': '📱 登录页',
      'pageRegister': '📲 注册页'
    });

    // ② 设置当前页面 → 注册的注释自动归属该页面
    window.__setActivePage('pageLogin');
    window.__addAnnotationOn('#loginPhone', 'right', {
      title: '手机号输入',
      description: '输入11位手机号，实时格式校验',
      type: 'interaction'
    });
    // ... 更多登录页注释

    // ③ 切换到注册页注册注释
    window.__setActivePage('pageRegister');
    window.__addAnnotationOn('#regPhone', 'right', {
      title: '手机号注册',
      description: '输入手机号，格式校验 + 已注册检测',
      type: 'interaction'
    });
    // ... 更多注册页注释

    // ④ 多屏模式下不需要切回默认页面
    // （传统多页模式需要切回：window.__setActivePage('pageLogin');）
  }
  register();
})();
```

### 多屏模式下的注释面板行为

| 行为 | 传统多页模式 | 多屏并排模式 |
|------|-------------|-------------|
| 面板顶部 Tab | 无 | 全部 / 📱 登录页 / 📲 注册页 |
| 面板分组 | 按类型一级分组 | 按页面 → 类型二级分组 |
| 默认显示 | 当前页面注释 | **全部注释** |
| 点击面板注释 | 切换到目标页面 → 高亮 | **滚动定位**到目标元素 → 高亮 |
| 标记可见性 | 只有当前页面的可见 | 全部可见（可按 Tab 筛选） |

### API 速查

| API | 说明 |
|-----|------|
| `window.__setMultiScreenMode(enabled, pageLabels)` | 启用/禁用多屏模式。`pageLabels` 为 `{ pageId: '显示标签' }` |
| `window.__setPageFilter(filter)` | 切换面板筛选。`'all'` 或具体 `pageId` |
| `window.__setActivePage(pageId)` | 设置当前页面（注册注释时用），多屏模式下不影响显示，只影响注释归属 |



生成原型时，框选工具（Selection Tool）默认通过 prototype-framework.js 自动启用。

1. 用户框选区域 → 填写修改描述 → 确认
2. 框架自动格式化修改请求为结构化文本，复制到剪贴板
3. 页面弹出"框选修改请求已就绪"面板，展示完整的修改请求文本
4. 用户将文本粘贴到对话框发送给 AI（面板上有复制按钮）
5. AI 收到请求后解析并执行对应修改

**确认修改后的 UI 呈现**：用户确认后，页面会显示一个位于顶部的卡片，包含：
- 框选坐标位置
- 修改描述
- 格式化的请求文本（可复制）
- "复制修改请求并发送给AI"按钮
- 自动复制状态提示

### 在生成原型时的必做事项

每个原型生成时，必须在代码中确保框选工具的 `aptSelConfirm` 回调实现了上述回传机制（复制到剪贴板 + 展示信息面板）。这是新版本框架的标准行为，生成时不要删除或简化这部分的代码。

| 端类型 | 布局特征 | 交互特征 |
|--------|----------|----------|
| PC | 宽度1200-1440px，侧边栏+内容区，表格布局 | hover状态，右键菜单，分页组件 |
| APP | 宽度375-414px，单列卡片布局 | 触摸手势(长按/滑动)，底部弹出 |
| 小程序 | 宽度375-414px，遵循微信设计规范，原生导航 | 禁止外链，分包加载 |
| H5 | 响应式，安全区适配 | 触屏tap事件，无hover态 |
