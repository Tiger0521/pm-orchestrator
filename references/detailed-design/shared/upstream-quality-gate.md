# 上游质量门

本文件定义详细设计阶段的上游文档读取顺序和设计前质量门检查项。四个 Step 开始前均按本文件读取上游。仅在执行设计动作时读取。

**职责边界**：本文件只管上游读取与质量门。各 Step 执行流程见对应 step 文件夹的 `workflow.md`；产出契约见 `output-contract.md`。

---

## 1. 上游文档读取顺序

subagent 进入详细设计阶段时，按以下顺序读取上游文档：

1. 读取 `refs.json`，获取已有文档节点列表，筛选出 `type=user-story` 和 `type=traceability-matrix` 的节点
2. 读取所有 User Story 文档的 frontmatter（id、title、status、refs）和正文（尤其三段式描述、GWT 验收标准、优先级、Story Points 字段）
3. 读取溯源矩阵文档，确认 Story-Feature 映射关系和覆盖度
4. 通过 `refs.json` 的 `implements` 边追溯到 Feature，读取 Feature 文档的业务流程、业务规则、用户角色字段（作为规则摘要和页面映射的素材来源）
5. 检查上游文档是否已确认（`status=approved` 或 `status=review`）；若有 User Story 仍为 `draft`，向主调度器报告 `needs-input`，要求先完成需求拆解阶段确认
6. 读取 `productArchitectureDesignPath`，提取产品事实和总体设计约束
7. Step 1 额外参考产品库用户故事地图：扫描 `<产品库产品目录>/用户故事地图/`（如存在），提取用户旅程叙事线、P0 主干行走路径、各旅程节点的故事分布

## 2. 上游质量门检查项

设计前检查上游文档质量。以下检查项任一不通过，subagent 向主调度器返回 `needs-input`，并附注缺失字段清单：

- **User Story 三段式描述非空**：角色具体（不能是"用户"这种泛称）、活动描述用户意图（不能是"操作系统"这种无指向描述）、价值清晰（不能为空）
- **User Story GWT 验收标准非空**：覆盖正常路径 + 异常路径，不能只有正常路径
- **溯源矩阵覆盖度检查通过**：每个 Feature 至少被一条 Story 实现，不能有 Feature 无 Story 实现
- **上游文档字段缺失或内容空洞**：如果上游文档存在字段缺失或内容空洞，向主调度器返回 `needs-input`，附注缺失字段清单
