# 标注层规范

> 本文件只在 Step 2 选择交互式 HTML 方式、生成或迭代原型时加载。定义页面内联标注层的实现机制（基于内嵌 `pm-prototype-prd` 的 `prototype-framework.js` 标注引擎）、`__addAnnotationOn` API 约定、编号/引线/标注卡渲染、两态切换、页面归属与多屏并排、与 proto JSON 字段映射。
>
> 本文件只管标注层规范。原型生成流程见 `prototype-method.md`；标注引擎为 `pm-prototype-prd/assets/prototype-framework.js`、构建指南见 `pm-prototype-prd/references/prototype-guide.md`；UI 风格预设见 `ui-design-style.md`；产出字段见 `../shared/output-contract.md`；落盘步骤见 `../shared/persist-guide.md`。

标注层由内嵌 pm-prototype-prd 的 `prototype-framework.js` 提供（墨刀/Axure 式页面内联标注 + 右侧注释面板 + 框选迭代），挂在原型 HTML 之上，不改动原型本身的 DOM 与交互。标注层上线后，它就是 Step 2 的主标注面，原型即文档。

---

## 1. 两态切换

标注层有两个状态，同一份 HTML 文件靠工具栏开关切换：

| 状态 | 用途 | 显示内容 |
| ---- | ---- | ---- |
| 预览态 | 演示、自测、给同事看 | 干净原型，没有任何标注 |
| 标注态 | 评审 | 编号标记 + 引线 + 标注卡 + 右侧注释面板 |

**切换机制**：由 `prototype-framework.js` 纳入的工具栏（浮动在页面右下角）切换标注显示；也支持 URL 参数（`?ann=1` 开启标注态）。框架初始化时按 URL 参数决定初始态。

---

## 2. 锚点约定（`__addAnnotationOn` selector 定位）

原型生成时，给每个被登记的关键交互元素用 **`__addAnnotationOn(selector, position, opts)`** 注册标注（框架基于 `getBoundingClientRect()` 自动定位编号标记，见 `pm-prototype-prd/references/prototype-guide.md` 的 API 与各组件定位规则）。

**编号规则**：框架按注册顺序自动生成编号（①②③…），标注卡逻辑标题用 `P<页面号>-E<元素号>` 标识（页面号按页面映射表顺序、元素号按页内从上到下从左到右）。

**稳定标识**：`__addAnnotationOn` 的第一个参数（selector / 目标元素）是稳定标识，局部迭代时只改被改模块的标注、未改模块不重排。推荐给目标元素加语义化 class（或 `data-ann="P1-E3"` 属性作显式锚点）以便定位。

**哪些元素需要标注**：
- 按钮、链接等可交互元素
- 表单输入项（输入框、下拉、开关等）
- 列表/表格的筛选区、操作列
- 弹窗/抽屉等动态容器
- 有异常状态展示的区域（空状态、加载中、错误状态）

---

## 3. 标注引擎嵌入（prototype-framework.js）

标注引擎为 `pm-prototype-prd/assets/prototype-framework.js`，**直接内联**进原型 HTML 的 `<script>`（放在 `</body>` 前、其他脚本之前，不使用 data URI）：

```html
<!-- 原型 HTML 末尾、其他脚本之前 -->
<script>{[将 pm-prototype-prd/assets/prototype-framework.js 内容直接内联在此]}</script>
<script>
  // 注册标注：用轮询等待模式，等框架就绪后再注册，避免 DOMContentLoaded 时序竞争
  (function () {
    function register() {
      if (typeof window.__addAnnotationOn !== 'function') { setTimeout(register, 50); return; }
      window.__setActivePage('pageOrderList');          // 多页：先设当前页（单页可省）
      window.__addAnnotationOn('#order-search', 'right', {
        title: 'P1-E3 订单搜索框',
        description: '【数据来源】订单号/客户名模糊匹配订单表\n【交互】实时搜索防抖 300ms\n【边界】无结果显示"未找到匹配的订单"',
        type: 'interaction'
      });
    }
    register();
  })();
</script>
```

**⚠️ 关键编码约束**：标注 `description` 用 JavaScript 单引号字符串，多行必须转义为 `\n`，禁止在单引号内放裸换行（否则 `<script>` 解析失败，标注引擎与页面交互全部失效）。

---

## 4. 标注卡内容

框架为每条标注渲染编号标记 + 引线 + 标注卡，同时归入右侧注释面板。标注卡承载四类信息：

| 信息类型 | 说明 | 来源字段 |
| ---- | ---- | ---- |
| 功能逻辑 | 这个元素干嘛用 | proto JSON `page_detail` 中的元素说明 |
| 交互规则 | 点了会发生什么、跳到哪 | proto JSON `page_detail` 中的元素"交互"列 |
| 校验规则 | 必填/格式/范围 | proto JSON `page_detail` 中的元素"备注"列 |
| 异常场景 | 空/加载/错误态文案 | proto JSON `page_detail` 中的"异常状态"段 |

**description 结构模板**（pm-prototype-prd 质量标准）：每条标注按"数据来源 / 排序规则 / 字段组成 / 业务规则 / 边界异常"组织：

```
【数据逻辑】数据来源 + 数据范围说明
【排序规则】排序依据 + 升序/降序
【字段组成】字段1 + 字段2 + ...（各字段格式说明）
【业务规则】触发条件 → 处理流程 → 结果/输出
【边界异常】异常条件 → 系统行为 → 用户感知
```

**标注类型与颜色**：

| type | 中文 | 颜色 | 用途 |
|------|------|------|------|
| `interaction` | 交互说明 | 蓝 #1677ff | 点击、悬停、弹窗、路由、校验等交互行为 |
| `business` | 业务逻辑 | 橙 #fa8c16 | 数据规则、计算逻辑、状态流转、排序等 |
| `edgecase` | 边界异常 | 红 #ff4d4f | 空数据态、网络异常、重复提交、权限不足等 |
| `permission` | 权限规则 | 绿 #52c41a | 角色可见范围、操作权限、字段权限、数据隔离 |
| `note` | 备注 | 紫 #722ed1 | 待确认点、研发注意事项、产品备注、样式复刻来源 |

---

## 5. 与 proto JSON 字段映射

标注层渲染所需的数据直接取自现有 `proto-*.json`（或 Step 2 草案）的已有字段，不新增 JSON 结构。映射关系如下：

| proto JSON 字段 | 标注层用途 |
| ---- | ---- |
| `page_list` | 页面编号 P1/P2/… 的顺序来源，映射为 `.page-section` 页面 id（`pageXxxName`） |
| `page_detail`（每页的元素说明表） | 标注卡的功能逻辑、交互规则、校验规则（写入 `__addAnnotationOn` 的 description） |
| `page_detail`（每页的异常状态段） | 标注卡的异常场景（`edgecase` 类型） |
| `component_reuse` | 跨页面复用组件的标注（在组件首次出现时标注"此组件在 P2/P3 复用"） |
| `proto_method` | 判断是否为交互式 HTML 方式（是则启用标注层） |

**数据流转**：生成原型时，agent 把 proto JSON（或 Step 2 草案）的"元素说明 + 异常状态 + 组件复用"结构化为 `__addAnnotationOn(...)` 调用的 title/description 字段，内联进 HTML。

---

## 6. 页面归属与多屏并排

**多页面归属**：多页原型的每个页面用 `<div class="page-section" id="pageXxxName">` 包裹。注册标注前先 `__setActivePage('pageId')`，后续注册的标注自动归属该页；页面切换时调用 `__setActivePage(newPageId)` 通知框架隐藏/显示对应标注（传统多页模式）。标注 `page` 为 `null` 时视为全局标注。

**多屏并排**（多个页面同时可见，如登录+注册并排）：所有页面同时有 `active` class、用 flex 横向排布，注册注释前调 `__setMultiScreenMode(true, { pageId: '标签' })`；右侧面板自动显示页面筛选 Tab + 二级分组（页→类型），点击面板注释滚动定位而非切换页。模板与 API 见 `pm-prototype-prd/references/prototype-guide.md`。

**实现形态**：不再自建独立 `annotation-overlay.js`，统一复用内嵌 `prototype-framework.js`（内置标注引擎 + 右侧面板 + 框选工具 + 拖拽定位 + 双击编辑 + 删除注释）。原型 DOM 与标注 DOM 解耦，预览态干净、标注态完整。

---

## 7. 局部迭代时的标注层同步

当用户要求框选局部修改（见 `prototype-method.md` 第 3 节，pm-prototype-prd Step 4 框选修改）时，标注层同步更新规则：

1. **框选→回传**：用户在浏览器点「✂️ 框选模式」框选区域并填写修改描述 → 框架生成结构化修改请求 → 用户粘贴回会话 → agent 解析坐标与描述、定位目标组件
2. **只更新被改模块的标注卡**：只重写被改模块对应 `__addAnnotationOn` 调用的 description/title
3. **未改模块的编号保持不变**：用稳定 selector/锚点（`#order-search` / `data-ann="P1-E3"`）而非按注册顺序依赖，避免改一处全页重排
4. **新增元素需注册新标注**：新增交互元素补一条 `__addAnnotationOn`
5. **删除元素需清理标注**：被删元素的标注一并移除，其余编号不变；更新页面版本标注栏升号（V1.0→V1.1）
