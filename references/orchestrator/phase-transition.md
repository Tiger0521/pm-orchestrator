# 阶段转换

只有主调度器可以执行相邻阶段转换。正常意图需要推进阶段，或快捷指令执行 `!next` / `!back` 时读取本文件。唯一例外是 `requirement-analyst` 在 `mode=intake` 获得用户确认后调用 `init-project.sh`，以显式初始化把 `collect-background` 变为 `requirement-analysis`；这不是阶段转换操作。

## 推进阶段

1. 读取当前阶段的校验清单：`requirement-analysis` 为 `references/requirement-analysis/guides/checklist.md`，`user-story-breakdown` 为 `references/user-story-breakdown/checklist.md`，`detailed-design` 为 `references/detailed-design/shared/checklist.md`。
2. 以 `mode=validate` 委派当前阶段 subagent 做内容校验，不创建新产出。
3. 运行 `scripts/validate-phase.sh --project-root <root> --project-path <project> --phase <phase>` 做文件和 frontmatter 机械校验。
4. 任一校验失败时列出缺失项，停留当前阶段。
5. 全部通过后展示当前状态、相邻目标状态和校验结果，等待用户明确确认。
6. 确认后调用：

```bash
bash <skillPath>/scripts/transition-project-state.sh \
  <projectPath>/progress.json \
  <from-state> \
  <to-state> \
  <event>
```

7. 重新读取 `progress.json`，确认状态、revision 和时间戳已经更新，再更新 `phase-summary.md`。

合法阶段边：

| 当前状态 | 下一状态 |
| --- | --- |
| `requirement-analysis` | `user-story-breakdown` |
| `user-story-breakdown` | `detailed-design` |
| `detailed-design` | `completed` |

不要跨越中间阶段。迁移到 `completed` 成功后，把顶层 `status` 更新为 `completed`，把详细设计阶段标记为已完成并写入完成时间，再复核顶层 `workflow.state=completed`。

## 关键校验

- 需求分析到需求拆解：需求卡片、Epic、Feature 字段完整，标题自然，用户已确认。需求分析文档已直接写入产品库，无需独立的导出步骤。
- 需求拆解到详细设计：每个 Story 使用三段式，包含 3-8 条 GWT，覆盖正常和异常路径，用户已确认。
- 详细设计到完成：核心原型、交互契约、规则摘要和 迭代规划完整，用户已确认。
- `iteration`：确认已有 Epic 未被修改。
- `refactor`：确认已有 Epic、Feature、User Story 未被修改。

## 回退阶段

回退前展示影响并等待用户确认。只允许：

- `user-story-breakdown -> requirement-analysis`
- `detailed-design -> user-story-breakdown`

确认后调用同一状态迁移脚本，重新读取状态并更新 `phase-summary.md`。不得自动从 `completed` 回退，不得删除后续阶段产物；把它们标记为需要重新校验。

## Intake 状态

`collect-background` 是 `requirement-analyst` 的 `mode=intake` 内部状态。主调度器只读取项目状态并以 `mode=intake` 重新委派该 agent，不读取或驱动 intake 的背景材料、产品匹配或项目类型确认细节。只有该 agent 显式调用 `init-project.sh` 后，项目才进入 `requirement-analysis`；在此之前不能用阶段转换跳到需求拆解或详细设计。