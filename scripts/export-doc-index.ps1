#requires -version 5.1
<#
.SYNOPSIS
    Export a formal document index or a Mermaid traceability graph.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$projectRoot,

    [Parameter(Mandatory = $true)]
    [string]$projectPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("index", "graph")]
    [string]$format = "index",

    [Parameter(Mandatory = $false)]
    [string]$outputPath
)

$ErrorActionPreference = "Stop"

function Get-CanonicalPath {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path).TrimEnd('\', '/')
}

function Remove-YamlQuotes {
    param([string]$Value)
    if ($null -eq $Value) { return $null }
    return $Value.Trim().Trim('"').Trim("'")
}

function Get-Frontmatter {
    param([string]$FilePath)
    $content = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
    if ($content -notmatch '(?s)\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)') { return $null }
    $values = @{}
    foreach ($line in ($matches[1] -split "`r?`n")) {
        if ($line -match '^([A-Za-z][A-Za-z0-9_-]*)\s*:\s*(.*)$') {
            $values[$matches[1]] = Remove-YamlQuotes $matches[2]
        }
    }
    return $values
}

if (-not (Test-Path -LiteralPath $projectRoot -PathType Container)) {
    throw "Project root does not exist: $projectRoot"
}
if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) {
    throw "Project path does not exist: $projectPath"
}

$root = Get-CanonicalPath $projectRoot
$project = Get-CanonicalPath $projectPath
if ([System.IO.Path]::GetDirectoryName($project) -ne $root) {
    throw "Project path must be a direct child of project root."
}
if ((Get-Item -LiteralPath $project).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw "Project path must not be a reparse point."
}

if ($format -eq "graph") {
    $refsPath = Join-Path $project "refs.json"
    if (-not (Test-Path -LiteralPath $refsPath -PathType Leaf)) {
        throw "Missing refs.json."
    }
    $refs = Get-Content -LiteralPath $refsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $lines = @("graph TD")
    foreach ($node in @($refs.nodes)) {
        $safeId = ([string]$node.id) -replace '[^A-Za-z0-9_]', '_'
        $safeLabel = (([string]$node.title) -replace '"', "'")
        $lines += "  $safeId[`"$($node.id): $safeLabel`"]"
    }
    foreach ($edge in @($refs.edges)) {
        $from = ([string]$edge.from) -replace '[^A-Za-z0-9_]', '_'
        $to = ([string]$edge.to) -replace '[^A-Za-z0-9_]', '_'
        $relation = ([string]$edge.relation) -replace '"', "'"
        $lines += "  $from -->|$relation| $to"
    }
    $output = $lines -join [Environment]::NewLine
} else {
    $docsPath = Join-Path $project "docs"
    $formalLayers = @("requirement-analysis", "design", "execution")
    $layerOrder = @{ "requirement-analysis" = 1; "design" = 2; "execution" = 3 }
    $entries = @()

    foreach ($layer in $formalLayers) {
        $layerPath = Join-Path $docsPath $layer
        if (-not (Test-Path -LiteralPath $layerPath -PathType Container)) { continue }
        foreach ($doc in (Get-ChildItem -LiteralPath $layerPath -Recurse -Filter "*.md" -File)) {
            $frontmatter = Get-Frontmatter $doc.FullName
            if ($null -eq $frontmatter) { continue }
            $entries += [PSCustomObject]@{
                Layer = $layer
                LayerOrder = $layerOrder[$layer]
                Id = $frontmatter.id
                Type = $frontmatter.type
                Title = $frontmatter.title
                Status = $frontmatter.status
                Path = $doc.FullName.Substring($project.Length).TrimStart('\', '/').Replace('\', '/')
            }
        }
    }

    $entries = $entries | Sort-Object LayerOrder, Id
    $rows = $entries | ForEach-Object {
        "| $($_.Layer) | $($_.Id) | $($_.Type) | $($_.Title) | $($_.Status) | $($_.Path) |"
    }
    $output = @(
        "# Document Index",
        "",
        "Project: $project",
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Documents: $($entries.Count)",
        "",
        "| Layer | ID | Type | Title | Status | Path |",
        "|---|---|---|---|---|---|",
        $rows
    ) -join [Environment]::NewLine
}

if ($outputPath) {
    $target = [System.IO.Path]::GetFullPath($outputPath)
    $projectPrefix = $project + [System.IO.Path]::DirectorySeparatorChar
    if (-not $target.StartsWith($projectPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Output path must be inside the project directory."
    }
    $output | Out-File -LiteralPath $target -Encoding UTF8
    Write-Host "Exported: $target" -ForegroundColor Green
} else {
    Write-Output $output
}
