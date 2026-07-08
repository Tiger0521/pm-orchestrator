#requires -version 5.1
<#
.SYNOPSIS
    导出项目文档索引：扫描项目 docs/ 目录，生成文档索引清单。

.DESCRIPTION
    pm-orchestrator 调用本脚本，扫描项目 docs/ 目录下所有 .md 文档，
    提取 frontmatter 的 id/type/title/status，生成索引清单并输出。
    便于用户快速查看项目产出全貌，也可作为 !list / !doc 快捷指令的底层数据。

.PARAMETER projectPath
    项目目录路径（.claude/product-design-projects/<project-id>）

.PARAMETER outputPath
    可选。索引清单输出路径，默认输出到 stdout。

.EXAMPLE
    .\export-doc-index.ps1 -projectPath "C:\Users\me\.claude\product-design-projects\net-res-mgmt"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$projectPath,

    [Parameter(Mandatory = $false)]
    [string]$outputPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $projectPath)) {
    Write-Error "项目目录不存在: $projectPath"
    exit 1
}

$docsPath = Join-Path $projectPath "docs"
if (-not (Test-Path $docsPath)) {
    Write-Host "项目 docs/ 目录不存在，尚无文档产出。" -ForegroundColor Yellow
    exit 0
}

function Get-Frontmatter {
    param([string]$filePath)
    $content = Get-Content $filePath -Raw -Encoding UTF8
    if ($content -notmatch '(?s)^---\r?\n(.*?)\r?\n---') {
        return $null
    }
    $yaml = $matches[1]
    $fm = @{}
    foreach ($line in ($yaml -split "`r?`n")) {
        if ($line -match '^\s*([A-Za-z_]+)\s*:\s*(.*)$') {
            $fm[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
        }
    }
    return $fm
}

$layerOrder = @{ "requirement-analysis" = 1; "design" = 2; "execution" = 3; "strategic" = 9; "requirement" = 9 }
$docs = Get-ChildItem -Path $docsPath -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue

$entries = @()
foreach ($doc in $docs) {
    $relPath = $doc.FullName.Substring($projectPath.Length).TrimStart('\', '/')
    $layer = ($relPath -split '[\\/]')[1]
    $fm = Get-Frontmatter -filePath $doc.FullName
    $entries += [PSCustomObject]@{
        Layer    = $layer
        LayerOrder = $layerOrder[$layer]
        Id       = if ($fm) { $fm.id } else { "(无)" }
        Type     = if ($fm) { $fm.type } else { "(无)" }
        Title    = if ($fm -and $fm.title) { $fm.title } else { $doc.BaseName }
        Status   = if ($fm) { $fm.status } else { "(无)" }
        Path     = $relPath
    }
}

$entries = $entries | Sort-Object LayerOrder, Id

$output = @"
# 文档索引

项目: $projectPath
生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
文档总数: $($entries.Count)

| 层级 | ID | 类型 | 标题 | 状态 | 路径 |
|------|-----|------|------|------|------|
$($entries | ForEach-Object { "| $($_.Layer) | $($_.Id) | $($_.Type) | $($_.Title) | $($_.Status) | $($_.Path) |" })
"@

if ($outputPath) {
    $output | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Host "文档索引已导出到: $outputPath" -ForegroundColor Green
} else {
    Write-Host $output
}
