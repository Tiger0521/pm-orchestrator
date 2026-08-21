# pm-orchestrator 统一安装脚本（一份 skill，装到 Claude Code 或 ZCode）——【可选】便捷工具
# 用法：powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target claude
#       powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target zcode
# 是否必需：不是。两种宿主都支持"把整个 skill 文件夹拷到 skills 目录即用"：
#   - Claude Code：目录自带 .claude-plugin/plugin.json，重启后自动识别为插件，agents/ 平铺即得 pm-orchestrator: 命名空间，零注册。
#   - ZCode：skill 每次运行时自检，自动把 agents/zcode/*.md 补齐到 ~/.zcode/agents/（ZCode 唯一能发现 subagent 的位置）。
# 本脚本只是替你完成上面两件事（铺干净副本 + 预置 zcode subagent），嫌每次手动拷贝麻烦或要做整包重装时可选用。
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('claude','zcode')]
  [string]$Target,
  # 可选：完整 skill 文件夹路径。缺省时取本脚本所在目录（兼容 PS2.0：不能用 $PSScriptRoot）。
  [string]$SkillSrc
)
$ErrorActionPreference = 'Stop'
$HomeDir = $env:USERPROFILE
if (-not $SkillSrc) { $SkillSrc = Split-Path -Parent $MyInvocation.MyCommand.Path }
$name = Split-Path -Leaf $SkillSrc
$srcFull = (Get-Item $SkillSrc).FullName

function Install-SkillFolder([string]$root) {
  $t = Join-Path $root $name
  $tFull = if (Test-Path $t) { (Get-Item $t).FullName } else { $t }
  # 防自删护栏：目标若包含源码、或被源码包含（例如源码仓库恰好躺在 ~/.claude/skills 下），
  # 就绝不删除目标，只跳过 skill 复制并继续后续步骤。
  if ($tFull -eq $srcFull -or $srcFull -like "$tFull*" -or $tFull -like "$srcFull*") {
    Write-Host "   $tFull 与源码重合或互为包含，跳过 skill 复制（仓库即 live skill，继续后续步骤）"
    return
  }
  New-Item -ItemType Directory -Path $t -Force | Out-Null
  if (Get-ChildItem $t -Force | Select-Object -First 1) { Remove-Item "$t\*" -Recurse -Force }
  # robocopy 拷贝运行时内容，排除 dev 专属目录/文件，使已装 skill 干净
  # 注意：.claude-plugin/plugin.json 必须保留（Claude 靠它自动识别 pm-orchestrator 插件）
  & robocopy $SkillSrc $t /E `
    /XD .git evals .claude .uploads `
    /XF .gitignore README.md install-zcode.ps1 `
    /NFL /NDL /NJH /NJS /NC /NS
  if ($LASTEXITCODE -ge 8) { throw "robocopy 复制失败（目标 $t），退出码 $LASTEXITCODE" }
  Write-Host "   skill -> $t  （已排除 dev 目录：.git/evals/.claude 等）"
}

function Install-AgentsFor([string]$agentDir, [string]$srcAg) {
  if (-not (Test-Path $srcAg)) { throw "在 $srcAg 找不到 subagent，请从源码仓库的完整 skill 目录运行本脚本" }
  New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
  Get-ChildItem $srcAg -Filter *.md | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $agentDir $_.Name) -Force
  }
  Write-Host "   agents -> $agentDir"
}

function Remove-OldFlatClaudeAgents {
  # 旧版把 agent 平铺进 ~/.claude/agents/，会以裸名被发现，与"必须带前缀"冲突；迁移后清理
  $dir = Join-Path $HomeDir '.claude\agents'
  if (-not (Test-Path $dir)) { return }
  Get-ChildItem $dir -Filter *.md | ForEach-Object {
    if ($_.BaseName -match '^(requirement-analyst|story-breakdown-analyst|detailed-design-designer|story-map-designer)$') {
      Remove-Item $_.FullName -Force
      Write-Host "   清理旧平铺 agent: $($_.FullName)"
    }
  }
}

if ($Target -eq 'claude') {
  Write-Host "== 安装 pm-orchestrator 到 Claude Code =="
  Install-SkillFolder (Join-Path $HomeDir '.claude\skills')
  Remove-OldFlatClaudeAgents
  Write-Host "   claude 版 agent 位于 skill 的 agents/ 下，由 .claude-plugin/plugin.json 自动识别为 pm-orchestrator 命名空间，无需插件注册。"
} else {
  Write-Host "== 安装 pm-orchestrator 到 ZCode =="
  Install-SkillFolder (Join-Path $HomeDir '.zcode\skills')
  Install-SkillFolder (Join-Path $HomeDir '.agents\skills')
  Install-AgentsFor   (Join-Path $HomeDir '.zcode\agents') (Join-Path $SkillSrc 'agents\zcode')
}
Write-Host "DONE"
