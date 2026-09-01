# Sprint 分解工作流

本文件是 Sprint 分解阶段（`workflow.state=sprint-planning`）的唯一执行流程与核心机制。基于用户故事阶段产物（User Story 的优先级/Story Points/旅程阶段/需求台账关联、溯源矩阵、旅程叙事线）+ 依赖关系 + 需求对齐度，输出首个 Sprint 的 Story 分解方案，落盘为迭代规划文档。

**职责边界**：本文件只管执行流程与机制。grilling 决策域与推导域见 `<skillPath>/references/detailed-design/shared/grilling-protocol.md`（第 3.4/4.4 节）；确认方法见 `<skillPath>/references/detailed-design/shared/confirmation-method.md`；产出字段见 `<skillPath>/references/detailed-design/shared/output-contract.md`（第 1.6/2.6 节）；落盘步骤见 `<skillPath>/references/detailed-design/shared/persist-guide.md`（第 3 节）。

---

## 1. 前置依赖（硬门禁）

- 用户故事阶段（story-map）全部产物已确认并落盘：

  - 全部应拆解的 User Story 已写入产品库 `<能力路径>/用户故事/`，含三段式、GWT 验收标准、优先级、Story Points、`journey_stage`、`requirementEntryId`（frontmatter refs `addresses`）
  - 溯源矩阵已生成（Story → Feature 映射与覆盖度）
  - 旅程叙事线已写入 `phase-summary.md`（Sprint 连贯性判断的横轴依据）
  - 需求台账条目已确认优先级（Story 优先级继承来源）

- 读取全部 User Story 的优先级（P0/P1/P2）、Story Points、`journey_stage` 与需求台账关联。
- 前置不满足时返回 `needs-input`，附缺失清单；不自行补拆 Story、不修改上游优先级。

---

## 2. 执行步骤

1. 读取所有 User Story 的优先级（P0/P1/P2）、Story Points 与 `journey_stage`（推导域，直接读取，见 `grilling-protocol.md` 第 4.4 节）；读取 `phase-summary.md` 中的旅程叙事线作为 Sprint 连贯性的横轴依据；对照需求台账核对优先级继承关系与需求条目对齐度。
2. **grilling 敲定决策域**：按 `grilling-protocol.md` 第 3.4 节逐轮敲定，每轮一问，收敛判据见协议第 6 节：

   - 团队产能与 Sprint 长度：人天/周期口径（选择题）
   - 风险容忍度：高风险 Story 前置（先啃硬骨头）还是后置（先交付确定价值）
   - 首 Sprint 目标口径：一句话交付目标（agent 给建议，用户裁决）
   - 依赖排序歧义：依赖关系不明确时的排序裁决（依赖明确则不问）

3. 按依赖关系排序（被依赖的排前面，推导域）。
4. 按优先级、依赖与旅程连贯性分配 Story 到 Sprint（分解原则见第 4 节）。
5. 预留 15-20% 缓冲（固定规则，不问）。
6. 标注高风险 Story（依赖外部、技术不确定，推导域）。
7. 为每个 Sprint 定义一句话目标（基于已裁决的首 Sprint 目标口径沿旅程叙事线展开）。
8. 输出 Sprint 分解方案草案（结构化草稿数据块，格式见 `output-contract.md` 第 1.6 节与 `persist-guide.md` 第 3.2 节）。

---

## 3. 如何询问

- grilling 决策域按 `grilling-protocol.md` 第 3.4 节逐轮敲定，每轮一问：先问产能口径，再问风险容忍度，再确认首 Sprint 目标。
- 推导域（优先级、Story Points、依赖排序、缓冲比例、高风险标注）直接读取或机械推导，不问。

**Sprint 容量确认选择题**：

```
首个 Sprint 的团队产能是多少？

A. 20 人天 / 2 周 -- 标准配置
B. 10 人天 / 1 周 -- 小团队快速迭代
C. 40 人天 / 4 周 -- 大团队完整迭代
补充描述：我自己填写
强制跳过：这个问题暂时不回答，记录为待验证并继续
```

---

## 4. Sprint 分解原则

Sprint 分解基于已确认的 User Story（含优先级/Story Points/旅程阶段/需求台账关联）+ 依赖关系 + 旅程叙事线，输出首个 Sprint 的 Story 分解方案：

| 原则 | 说明 |
| ---- | ---- |
| 优先级驱动 | P0 Story 优先进入首个 Sprint；优先级继承需求台账条目（经 Story 的 `requirementEntryId` 核对，不做二次裁决） |
| 依赖排序 | 被依赖的 Story 排在前面（如"用户认证"先于"订单管理"） |
| 旅程连贯 | 单个 Sprint 内的 Story 沿旅程叙事线连贯推进，不横跳阶段；跨阶段依赖用关键依赖标注 |
| 需求对齐 | 每条 Story 的 `requirementEntryId` 对应需求条目在 Sprint 内闭环；同一台账条目的衍生 Story 尽量同批交付 |
| 容量控制 | 预留 15-20% 缓冲，不排满 |
| 高风险标注 | 依赖外部的、技术不确定的 Story 标注为高风险 |
| Sprint 目标明确 | 每个 Sprint 用一句话说清交付什么（沿旅程叙事线表述） |

**机制边界**：Sprint 分解的最终裁决者是用户。agent 按优先级、依赖、旅程与对齐信号给出分解建议，用户确认后执行。Sprint 容量是否合理由用户把控，agent 只给建议值。

---

## 5. 用户确认点

- 展示 Sprint 分解方案（Sprint 目标、Story 列表、优先级、风险标注、依赖说明）
- 给出理解回执（Sprint 数、Story 分布、总工作量与产能对比）
- 提出"以上 Sprint 分解方案是否反映优先级和依赖关系？容量是否合理？"

## 6. 产出

迭代规划文档（`详细设计/迭代规划/<简称>-迭代规划.md`）。**用户确认后立即落盘**：将已确认数据写入 `docs/_extracted/.design/sprint-*.json`，调用 `render-doc.sh` 渲染到产品库，`validate-paradigm.sh` 零警告后更新记忆文件。落盘步骤见 `persist-guide.md` 第 3 节，产出字段见 `output-contract.md` 第 1.6 节。更新 `phase-summary.md` 时随写 `phase_status`（供 `references/phase-navigator.md` 读取：草稿确认后 `confirmed`，迭代规划落盘后 `persisted`）。

```bash
bash "<skillPath>/scripts/render-doc.sh" \
  "<projectPath>/docs/_extracted/.design/sprint-<nnn>.json" \
  "<selectedProductLibraryPath>/<产品全名>" \
  "<产品简称>" "<产品全名>"
```

## 7. 质量门

- Sprint 目标明确（每个 Sprint 一句话目标，且沿旅程叙事线连贯）
- 每个 Sprint 包含的 Story 已列出（含 ID、优先级、Story Points、风险）
- Story 优先级、依赖与旅程阶段已标注
- 所有 Story 的 `requirementEntryId` 已核对，Sprint 内容与需求台账对齐
- 高风险 Story 已标注
- 总工作量未超过团队可用产能
- 预留 15-20% 缓冲

---

## 8. 规模自适应

项目类型在需求分析 intake 中收敛，写入 `progress.json` 的 `projectType` ：

| 环节 | 全新项目 (`new`) | 迭代项目 (`iteration`) | 重构项目 (`refactor`) |
| ---- | -------- | -------- | -------- |
| 分解对象 | 全部已确认 Story | 新增 Story（与已有迭代规划合并或独立追加 Sprint） | 重构任务型 Story（性能/安全/兼容性） |
| 优先级核对 | 全量台账条目 | 新增条目 | 受影响条目 |
| 旅程连贯 | 完整叙事线分段 | 沿新增能力旅程并入 | 沿受影响能力旅程校验 |

迭代/重构项目在已有 `详细设计/迭代规划/` 上原地增量更新（沿用 ID），不重排已完成 Sprint。