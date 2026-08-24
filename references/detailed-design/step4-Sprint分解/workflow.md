# Step 4 工作流：Sprint 分解

本文件是 Step 4 的唯一执行流程与核心机制。基于功能详细设计产物 + 优先级 + 依赖关系，输出首个 Sprint 的 Story 分解方案。

**职责边界**：本文件只管 Step 4 执行流程与机制。grilling 决策域与推导域见 `../shared/grilling-protocol.md` 第 3.4/4.4 节；确认方法见 `../shared/confirmation-method.md`；产出字段见 `../shared/output-contract.md`；落盘步骤见 `../shared/persist-guide.md`。

---

## 1. 前置依赖（硬门禁）

- Step 1-3 的全部产出必须已用户确认（业务流、页面映射、原型、交互契约、规则摘要），否则不得进入本步
- 读取全部 User Story 的优先级（P0/P1/P2）和 Story Points
- 前置不满足时返回 `needs-input`

---

## 2. 执行步骤

1. 读取所有 User Story 的优先级（P0/P1/P2）和 Story Points（推导域，直接读取，见 `../shared/grilling-protocol.md` 第 4.4 节）
2. **grilling 敲定决策域**：按 `../shared/grilling-protocol.md` 第 3.4 节逐轮敲定，每轮一问，收敛判据见协议第 6 节：
   - 团队产能与 Sprint 长度：人天/周期口径（选择题，见第 3 节）
   - 风险容忍度：高风险 Story 前置（先啃硬骨头）还是后置（先交付确定价值）
   - 首 Sprint 目标口径：一句话交付目标（agent 给建议，用户裁决）
   - 依赖排序歧义：依赖关系不明确时的排序裁决（依赖明确则不问）
3. 按依赖关系排序（被依赖的排前面，推导域）
4. 按优先级和依赖分配 Story 到 Sprint（分解原则见第 4 节）
5. 预留 15-20% 缓冲（固定规则，不问）
6. 标注高风险 Story（依赖外部、技术不确定，推导域）
7. 为每个 Sprint 定义一句话目标（基于已裁决的首 Sprint 目标口径展开）
8. 输出 Sprint 分解方案草案（结构化草稿数据块，格式见 `../shared/output-contract.md` 第 4 节）

---

## 3. 如何询问

- grilling 决策域按 `../shared/grilling-protocol.md` 第 3.4 节逐轮敲定，每轮一问：先问产能口径，再问风险容忍度，再确认首 Sprint 目标
- 推导域（优先级、Story Points、依赖排序、缓冲比例、高风险标注）直接读取或机械推导，不问（见协议第 4.4 节）

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

Sprint 分解基于已评审的 Epic/Feature/User Story + 优先级 + 依赖关系，输出首个 Sprint 的 Story 分解方案：

| 原则 | 说明 |
| ---- | ---- |
| 优先级驱动 | P0 Story 优先进入首个 Sprint |
| 依赖排序 | 被依赖的 Story 排在前面（如"用户认证"先于"订单管理"） |
| 容量控制 | 预留 15-20% 缓冲，不排满 |
| 高风险标注 | 依赖外部的、技术不确定的 Story 标注为高风险 |
| Sprint 目标明确 | 每个 Sprint 用一句话说清交付什么 |

**机制边界**：Sprint 分解的最终裁决者是用户。agent 按优先级和依赖信号给出分解建议，用户确认后执行。Sprint 容量是否合理由用户把控，agent 只给建议值。

---

## 5. 用户确认点

- 展示 Sprint 分解方案（Sprint 目标、Story 列表、优先级、风险标注、依赖说明）
- 给出理解回执（Sprint 数、Story 分布、总工作量与产能对比）
- 提出"以上 Sprint 分解方案是否反映优先级和依赖关系？容量是否合理？"

## 6. 产出

迭代规划文档（`详细设计/迭代规划/<简称>-迭代规划.md`）。**用户确认后立即步级落盘**：将已确认数据写入 `docs/_extracted/.design/sprint-*.json`，调用 `render-doc.sh` 渲染到产品库，校验零警告后更新记忆文件。落盘步骤见 `../shared/persist-guide.md` 第 3 节，产出字段见 `../shared/output-contract.md` 第 1.6 节。

## 7. 质量门

- Sprint 目标明确（每个 Sprint 一句话目标）
- 每个 Sprint 包含的 Story 已列出（含 ID、优先级、Story Points、风险）
- Story 优先级和依赖已标注
- 高风险 Story 已标注
- 总工作量未超过团队可用产能
- 预留 15-20% 缓冲
