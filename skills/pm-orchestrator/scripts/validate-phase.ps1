#requires -version 7.0
<#
.SYNOPSIS
    阶段转换校验脚本：检查项目目录下文档的存在性和 frontmatter 完整性。

.DESCRIPTION
    pm-orchestrator 在阶段转换时调用本脚本，辅助校验当前阶段产出的文档：
    - 文件存在性：检查关键文档是否已生成
    - frontmatter 完整性：检查每份文档是否包含 id/type/projectId/title/status/refs
    - refs.json 注册：检查产出文档是否已注册到 refs.json

    本脚本只做机械校验，内容质量判断仍需结合各阶段 checklist.md 人工评估。

.PARAMETER projectPath
    项目目录路径（.claude/product-design-projects/<project-id>）

.PARAMETER phase
    要校验的阶段：requirement-analysis | user-story-breakdown | detailed-design

.EXAMPLE
    .\validate-phase.ps1 -projectPath "C:\Users\me\.claude\product-design-projects\net-res-mgmt" -phase requirement-analysis
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$projectPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("requirement-analysis", "user-story-breakdown", "detailed-design")]
    [string]$phase
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $projectPath)) {
    Write-Error "项目目录不存在: $projectPath"
    exit 1
}

$docsPath = Join-Path $projectPath "docs"
$requiredFields = @("id", "type", "projectId", "title", "status", "refs")

# 各阶段期望产出的文档（glob 形式）
$phaseExpectations = @{
    "requirement-analysis" = @{
        Files = @(
            @{ Pattern = "strategic/req-*.md";     Desc = "需求卡片" },
            @{ Pattern = "strategic/epic-*.md";     Desc = "Epic 文档" },
            @{ Pattern = "requirement/feature-*.md"; Desc = "Feature 文档" }
        )
    }
    "user-story-breakdown" = @{
        Files = @(
            @{ Pattern = "design/story-*.md";   Desc = "User Story" },
            @{ Pattern = "design/matrix-*.md";  Desc = "溯源矩阵" }
        )
    }
    "detailed-design" = @{
        Files = @(
            @{ Pattern = "design/flow-*.md";     Desc = "结构与流程图" },
            @{ Pattern = "design/proto-*.md";    Desc = "原型文档" },
            @{ Pattern = "design/contract-*.md"; Desc = "交互契约" },
            @{ Pattern = "execution/rules-*.md"; Desc = "规则摘要" },
            @{ Pattern = "execution/sprint-*.md"; Desc = "Sprint 规划" }
        )
    }
}

function Get-Frontmatter {
    param([string]$filePath)
    $content = Get-Content $filePath -Raw -Encoding UTF8
    if ($content -notmatch '(?s)^---\r?\n(.*?)\r?\n---') {
        return $null
    }
    $yaml = $matches[1]
    $fm = @{}
    $currentKey = $null
    $inArray = $false

    foreach ($line in ($yaml -split "`r?`n")) {
        # Match single-line key: value
        if ($line -match '^\s*([A-Za-z_]+)\s*:\s*(.*)$') {
            $currentKey = $matches[1]
            $value = $matches[2].Trim()

            # If value is empty, might be start of multi-line array
            if ([string]::IsNullOrWhiteSpace($value)) {
                $fm[$currentKey] = @()
                $inArray = $true
            } else {
                $fm[$currentKey] = $value
                $inArray = $false
            }
        }
        # Match array item (e.g., "  - value")
        elseif ($inArray -and $line -match '^\s*-\s+(.+)$') {
            if ($null -ne $currentKey) {
                if ($fm[$currentKey] -isnot [array]) {
                    $fm[$currentKey] = @()
                }
                $fm[$currentKey] += $matches[1].Trim()
            }
        }
    }
    return $fm
}

$expectation = $phaseExpectations[$phase]
$issues = @()
$checkedFiles = @()

Write-Host "==== 校验阶段: $phase ====" -ForegroundColor Cyan
Write-Host "项目: $projectPath`n"

# 1. 文件存在性 + frontmatter 完整性
foreach ($fileExpect in $expectation.Files) {
    $pattern = $fileExpect.Pattern
    $desc = $fileExpect.Desc
    $fullPattern = Join-Path $docsPath $pattern
    $found = Get-ChildItem -Path $fullPattern -File -ErrorAction SilentlyContinue

    if (-not $found -or $found.Count -eq 0) {
        $issues += "[缺失] $desc : 未找到匹配 $pattern 的文件"
        continue
    }

    foreach ($f in $found) {
        $checkedFiles += $f.FullName
        $fm = Get-Frontmatter -filePath $f.FullName
        if ($null -eq $fm) {
            $issues += "[frontmatter] $($f.Name) : 缺少 frontmatter 块"
            continue
        }
        foreach ($field in $requiredFields) {
            if (-not $fm.ContainsKey($field)) {
                $issues += "[frontmatter] $($f.Name) : 缺少字段 $field"
            }
            elseif ($field -eq "refs") {
                # refs can be array or string, just check it exists and is not empty
                if ($fm[$field] -is [array]) {
                    if ($fm[$field].Count -eq 0) {
                        $issues += "[frontmatter] $($f.Name) : refs 数组为空"
                    }
                }
                elseif ([string]::IsNullOrWhiteSpace($fm[$field])) {
                    $issues += "[frontmatter] $($f.Name) : refs 字段为空"
                }
            }
            elseif ([string]::IsNullOrWhiteSpace($fm[$field])) {
                $issues += "[frontmatter] $($f.Name) : 缺少字段 $field"
            }
        }
    }
}

# 2. refs.json 注册校验
$refsPath = Join-Path $projectPath "refs.json"
if (Test-Path $refsPath) {
    try {
        $refs = Get-Content $refsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $registeredIds = @()
        if ($refs.nodes) {
            $registeredIds = $refs.nodes | ForEach-Object { $_.id }
        }
        foreach ($f in $checkedFiles) {
            $fm = Get-Frontmatter -filePath $f
            if ($fm -and $fm.id) {
                if ($registeredIds -notcontains $fm.id) {
                    $issues += "[refs.json] $($f | Split-Path -Leaf) : id=$($fm.id) 未在 refs.json 注册"
                }
            }
        }
    } catch {
        $issues += "[refs.json] 解析失败: $($_.Exception.Message)"
    }
} else {
    $issues += "[缺失] refs.json 不存在"
}

# 3. 输出结果
Write-Host "---- 校验结果 ----" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "✅ 全部通过: $($checkedFiles.Count) 份文档已校验" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ 发现 $($issues.Count) 个问题:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
    exit 1
}
