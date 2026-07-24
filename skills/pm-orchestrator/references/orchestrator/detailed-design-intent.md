# 详细设计意图

当第 1 步把目标识别为 `detailed-design` 时完整读取本文件。此意图只允许路由到 `pm-orchestrator:detailed-design-designer`，不得进入需求分析 intake 或产品匹配。

## 1. 确定项目

1. 用户指定项目时验证并确认该项目；未指定时读取有效的工作区 `current-project.json`。
2. 没有当前项目时扫描已有项目并让用户选择。不得为详细设计创建新项目或新 intake。
3. 读取项目 `progress.json` 和 `phase-summary.md`，并复核项目记录的产品库与第 0 步产品库一致。

## 2. 检查阶段

- intake 内部状态：说明需求分析 intake 未完成，让用户选择继续 intake 或切换项目。不要调用 `requirement-analyst`，不要执行产品匹配。
- `requirement-analysis`：说明需求拆解尚未完成，不能进入详细设计。让用户选择先进入需求拆解或切换项目；不要自动委派其他 agent。
- `user-story-breakdown`：检查拆解阶段是否已完成。未完成时列出缺失条件并等待用户选择；完成时读取 `phase-transition.md`，校验、确认并迁移到 `detailed-design`。
- `detailed-design`：允许继续。
- `completed`：说明已有详细设计产物，让用户选择查看、明确回退或新建项目。

## 3. 准备上下文

状态为 `detailed-design` 后：

1. 询问是否有新增背景材料，读取固定 `docs/background/` 中已有或新增内容；用户可明确跳过。
2. 从 `refs.json` 定位已确认的 Feature、User Story、GWT 和溯源矩阵，作为 `upstreamDocs`。
3. 传递项目与产品库路径、总体架构设计路径、`projectType`、用户本轮指定的页面或设计范围。
4. 将 `outputTargets` 限定为项目内 `docs/design/`、`docs/execution/` 及相应记忆索引。

## 4. 委派

再次确认 `workflow.state=detailed-design`，读取共享委派协议，以 `mode=draft` 委派 `pm-orchestrator:detailed-design-designer`。用户确认完整草稿前不得使用 `persist`。
