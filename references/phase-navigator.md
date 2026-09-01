# 阶段导航器

本文件是 pm-orchestrator 的全局阶段地图与状态检测规范。主调度器在用户无明确阶段意图时读取本文件展示进度；每次 subagent 委派前依据本文件判定「当前阶段 + 进度」并注入 `navigationContext`；委派返回后按阶段产出更新进度。

## 全局阶段地图

| 阶段 | 名称 | 前置条件 | 核心产出 | 完成标志 | 对应 agent |
|------|------|---------|---------|---------|-----------|
| 1 | 需求分析 | 无 | 需求卡片 + 需求台账 | 台账已 persist | `requirement-analyst` |
| 2 | 能力划分 | 阶段 1 完成 | Epic + Feature + 业务文档 | Feature 已 persist | `requirement-analyst` |
| 3 | 用户故事+故事地图 | 阶段 2 完成 | Story + 旅程 + 故事地图 | Story 已 persist + 地图已 persist | `story-map-designer` |
| 4 | 详细设计 | 阶段 3 完成 | 功能架构 + 原型 + 交互规则 | Step 1-3 已 persist | `detailed-design-designer` |
| 5 | Sprint 分解 | 阶段 3 完成 | Sprint 计划 | Sprint 已 persist | `sprint-planner` |

> **与 `workflow.state` 的对应**：上述第 1、2 行同属 `requirement-analysis` 状态（`requirement-analyst` 内的 `requirement-epic` 与 `features` 两个批次，按 `artifactScope` 区分）；第 3 行对应 `story-map`；第 4 行对应 `detailed-design`；第 5 行对应 `sprint-planning`；全部完成对应 `completed`。Sprint 分解的前置是「阶段 3 完成」，可与详细设计（阶段 4）并行或前后执行。

## 状态检测逻辑

1. **扫描产品库目录结构**：检查 `<产品全名>/` 下各资产目录的产出物，判断哪些阶段已产出 —— 需求卡片/Epic/Feature 与需求台账（`<简称>-需求卡片.md`、`<简称>-设计文档.md`、`<简称>-需求台账.md`、`<能力路径>/能力文档`）、User Story（`<能力路径>/用户故事/story-*.md`）与故事地图（`<能力路径>/用户故事地图/`）、详细设计（`<产品全名>/详细设计/` 下各子目录）、迭代规划（`<产品全名>/详细设计/迭代规划/`）。
2. **读取过程项目 `phase-summary.md` 的阶段条目**：取各阶段条目的 `phase_status`（`draft` / `confirmed` / `persisted`）判断当前进度；`workflow.state` 给出所处状态，`docs/_extracted/` 下 JSON 草稿给出细节进度。
3. **对比前置条件**：按上表前置条件判断用户可以做什么 —— 已满足全部前置且当前阶段未完成时推荐继续当前阶段；当前阶段已完成时推荐进入后继阶段或等待新任务。

### phase_status 取值语义

| 取值 | 含义 | 导航器行为 |
|------|------|-----------|
| `draft` | 阶段已开始，产物仍在草稿/确认中 | 地图显示「进行中」 |
| `confirmed` | 阶段产物已全部经用户确认（尚差最终落盘或阶段内批次确认完毕） | 地图显示「已确认，待落盘/继续」 |
| `persisted` | 阶段全部产出已持久化（阶段完成） | 地图显示「已完成」 |

`phase_status` 写入到 `phase-summary.md` 对应阶段条目，由各阶段 persist/output-contract 在追加恢复摘要时随写；无独立模板文件，按此约定维护。

## 导航输出格式

### 无明确意图时（入口引导）

```
你正在做「{产品名}」。当前进度：
- [x] 需求分析（已完成）
- [x] 能力划分（已完成）
- [ ] 用户故事+故事地图（进行中：Story 草稿生成中）
- [ ] 详细设计
- [ ] Sprint 分解

你可以继续当前阶段，或选择其他操作。
```

检测到 `phase_status=persisted` 的条目显示 ✓/已完成；`draft`/`confirmed` 显示进行中并附最近进度短语（从对应 instruction 返回状态与 `docs/_extracted/` 草稿推断）；尚未开始的阶段显示待办。

### 阶段开始时

```
即将进入「{阶段名}」阶段。
- 目标：{核心产出}
- 预计交互：{步骤概述}
- 完成标志：{完成条件}
准备好后告诉我开始。
```

### 阶段结束时

```
「{阶段名}」阶段已完成。
- 产出：{产出文件列表}
- 下一步：你可以进入「{下一阶段名}」，或者先回顾产出。

需要我继续吗？
```

## 注入机制

- `SKILL.md` 主路由：用户输入无明确阶段意图时，先按本文件展示进度与可用操作；意图模糊时按检测结果推荐当前阶段。
- `references/orchestrator-operations.md`：每次 subagent 委派前，将「当前阶段 + 进度」注入 `navigationContext` handoff 字段；委派返回后读取 `phase-summary.md` 更新进度。
- 各阶段 instruction.md：开始时输出阶段简介与预期产出，结束时输出完成确认与下一步建议（输出格式见上）。