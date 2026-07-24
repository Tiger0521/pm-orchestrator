# 需求拆解意图

当第 1 步把目标识别为 `user-story-breakdown` 时完整读取本文件。此意图只允许路由到 `pm-orchestrator:story-breakdown-analyst`，不得进入需求分析 intake 或产品匹配。

## 1. 确定项目

1. 用户指定项目时验证并确认该项目；未指定时读取有效的工作区 `current-project.json`。
2. 没有当前项目时扫描已有项目并让用户选择。不得为需求拆解创建新项目或新 intake。
3. 读取项目 `progress.json` 和 `phase-summary.md`，并复核项目记录的产品库与第 0 步产品库一致。

## 2. 检查阶段

- intake 内部状态：说明项目仍在需求分析 intake，让用户选择继续 intake 或切换已完成上游阶段的项目。不要调用 `requirement-analyst`，不要执行产品匹配。
- `requirement-analysis`：检查需求分析阶段是否已完成。未完成时列出缺失条件并等待用户选择；不要自动继续需求分析。完成时读取 `phase-transition.md`，校验、确认并迁移到 `user-story-breakdown`。
- `user-story-breakdown`：允许继续。
- `detailed-design`：说明已有拆解产物，让用户选择查看、明确回退或继续详细设计。
- `completed`：只汇报完成状态和可选操作。

从 `requirement-analysis` 不得直接跳到 `detailed-design`；阶段迁移必须相邻。

## 3. 准备上下文

状态为 `user-story-breakdown` 后：

1. 询问是否有新增背景材料，读取固定 `docs/background/` 中已有或新增内容；用户可明确跳过。
2. 从 `refs.json` 定位已确认的 Requirement Card、Epic 和 Feature，作为 `upstreamDocs`。
3. 传递项目与产品库路径、总体架构设计路径、`projectType`、用户本轮指定的 Feature 或拆解范围。
4. 将 `outputTargets` 限定为项目内 `docs/design/` 及相应记忆索引。

## 4. 委派

再次确认 `workflow.state=user-story-breakdown`，读取共享委派协议，以 `mode=draft` 委派 `pm-orchestrator:story-breakdown-analyst`。用户确认完整草稿前不得使用 `persist`。
