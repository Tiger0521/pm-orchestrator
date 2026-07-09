#requires -version 5.1
<#
.SYNOPSIS
    Validate pm-orchestrator phase artifacts and traceability metadata.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$projectRoot,

    [Parameter(Mandatory = $true)]
    [string]$projectPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("requirement-analysis", "user-story-breakdown", "detailed-design")]
    [string]$phase
)

$ErrorActionPreference = "Stop"
$allowedStatuses = @("draft", "review", "approved")
$allowedRelations = @("derived-from", "belongs-to", "implements", "contains", "references")
$requiredFields = @("id", "type", "projectId", "title", "status", "refs")

$phaseExpectations = @{
    "requirement-analysis" = @(
        @{ Pattern = "requirement-analysis/req-*.md"; Type = "requirement-card"; Prefix = "req-" },
        @{ Pattern = "requirement-analysis/epic-*.md"; Type = "epic"; Prefix = "epic-" },
        @{ Pattern = "requirement-analysis/feature-*.md"; Type = "feature"; Prefix = "feature-" }
    )
    "user-story-breakdown" = @(
        @{ Pattern = "design/story-*.md"; Type = "user-story"; Prefix = "story-" },
        @{ Pattern = "design/matrix-*.md"; Type = "traceability-matrix"; Prefix = "matrix-" }
    )
    "detailed-design" = @(
        @{ Pattern = "design/flow-*.md"; Type = "structure-flow"; Prefix = "flow-" },
        @{ Pattern = "design/proto-*.md"; Type = "prototype"; Prefix = "proto-" },
        @{ Pattern = "design/contract-*.md"; Type = "interaction-contract"; Prefix = "contract-" },
        @{ Pattern = "execution/rules-*.md"; Type = "rules-summary"; Prefix = "rules-" },
        @{ Pattern = "execution/sprint-*.md"; Type = "sprint"; Prefix = "sprint-" }
    )
}

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
    if ($content -notmatch '(?s)\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)') {
        return $null
    }

    $yaml = $matches[1]
    $values = @{}
    foreach ($line in ($yaml -split "`r?`n")) {
        if ($line -match '^([A-Za-z][A-Za-z0-9_-]*)\s*:\s*(.*)$') {
            $values[$matches[1]] = $matches[2].Trim()
        }
    }

    $refs = @()
    $inRefs = $false
    $currentRef = $null
    foreach ($line in ($yaml -split "`r?`n")) {
        if ($line -match '^refs\s*:') {
            $inRefs = $true
            continue
        }
        if ($inRefs -and $line -match '^[A-Za-z][A-Za-z0-9_-]*\s*:') {
            $inRefs = $false
        }
        if (-not $inRefs) { continue }

        if ($line -match '^\s*-\s+id\s*:\s*(.+)$') {
            if ($null -ne $currentRef) { $refs += [PSCustomObject]$currentRef }
            $currentRef = @{ id = Remove-YamlQuotes $matches[1]; relation = $null }
        } elseif ($null -ne $currentRef -and $line -match '^\s+relation\s*:\s*(.+)$') {
            $currentRef.relation = Remove-YamlQuotes $matches[1]
        }
    }
    if ($null -ne $currentRef) { $refs += [PSCustomObject]$currentRef }

    return [PSCustomObject]@{ Values = $values; Refs = $refs }
}

if (-not (Test-Path -LiteralPath $projectRoot -PathType Container)) {
    throw "Project root does not exist: $projectRoot"
}
if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) {
    throw "Project path does not exist: $projectPath"
}

$root = Get-CanonicalPath $projectRoot
$project = Get-CanonicalPath $projectPath
$expectedParent = [System.IO.Path]::GetDirectoryName($project)
if ($expectedParent -ne $root) {
    throw "Project path must be a direct child of project root."
}
if ((Get-Item -LiteralPath $project).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw "Project path must not be a reparse point."
}

$progressPath = Join-Path $project "progress.json"
if (-not (Test-Path -LiteralPath $progressPath -PathType Leaf)) {
    throw "Missing progress.json."
}
$progress = Get-Content -LiteralPath $progressPath -Raw -Encoding UTF8 | ConvertFrom-Json
$projectId = [string]$progress.projectId
if ($projectId -notmatch '^[a-z0-9][a-z0-9-]{0,62}$') {
    throw "Invalid projectId in progress.json."
}
if ((Split-Path -Leaf $project) -ne $projectId) {
    throw "Project directory name must equal progress.json projectId."
}

$docsPath = Join-Path $project "docs"
$issues = @()
$documents = @()

foreach ($expected in $phaseExpectations[$phase]) {
    $found = Get-ChildItem -Path (Join-Path $docsPath $expected.Pattern) -File -ErrorAction SilentlyContinue
    if (-not $found) {
        $issues += "[missing] $($expected.Pattern)"
        continue
    }

    foreach ($file in $found) {
        $frontmatter = Get-Frontmatter $file.FullName
        if ($null -eq $frontmatter) {
            $issues += "[frontmatter] $($file.Name): missing block"
            continue
        }

        foreach ($field in $requiredFields) {
            if (-not $frontmatter.Values.ContainsKey($field)) {
                $issues += "[frontmatter] $($file.Name): missing $field"
            }
        }
        if ($issues | Where-Object { $_ -like "*$($file.Name)*missing*" }) { continue }

        $id = Remove-YamlQuotes $frontmatter.Values.id
        $type = Remove-YamlQuotes $frontmatter.Values.type
        $docProjectId = Remove-YamlQuotes $frontmatter.Values.projectId
        $status = Remove-YamlQuotes $frontmatter.Values.status
        $title = Remove-YamlQuotes $frontmatter.Values.title

        if ($id -notmatch ('^' + [regex]::Escape($expected.Prefix) + '\d{3,}$')) {
            $issues += "[id] $($file.Name): invalid id $id"
        }
        if ($file.BaseName -ne $id) {
            $issues += "[id] $($file.Name): filename must equal id"
        }
        if ($type -ne $expected.Type) {
            $issues += "[type] $($file.Name): expected $($expected.Type), got $type"
        }
        if ($docProjectId -ne $projectId) {
            $issues += "[projectId] $($file.Name): expected $projectId"
        }
        if ($allowedStatuses -notcontains $status) {
            $issues += "[status] $($file.Name): invalid status $status"
        }
        if ([string]::IsNullOrWhiteSpace($title)) {
            $issues += "[title] $($file.Name): title is empty"
        }
        if ($type -ne "requirement-card" -and $frontmatter.Refs.Count -eq 0) {
            $issues += "[refs] $($file.Name): at least one reference is required"
        }
        foreach ($ref in $frontmatter.Refs) {
            if ([string]::IsNullOrWhiteSpace($ref.id)) {
                $issues += "[refs] $($file.Name): reference id is empty"
            }
            if ($allowedRelations -notcontains $ref.relation) {
                $issues += "[refs] $($file.Name): invalid relation $($ref.relation)"
            }
        }

        $relativePath = $file.FullName.Substring($project.Length).TrimStart('\', '/').Replace('\', '/')
        $documents += [PSCustomObject]@{
            Id = $id
            Path = $relativePath
            File = $file
            Frontmatter = $frontmatter
        }
    }
}

$duplicateDocIds = $documents | Group-Object Id | Where-Object Count -gt 1
foreach ($duplicate in $duplicateDocIds) {
    $issues += "[duplicate] document id $($duplicate.Name)"
}

if ($phase -eq "requirement-analysis") {
    foreach ($legacyPattern in @("strategic/req-*.md", "strategic/epic-*.md", "requirement/feature-*.md")) {
        if (Get-ChildItem -Path (Join-Path $docsPath $legacyPattern) -File -ErrorAction SilentlyContinue) {
            $issues += "[directory] legacy artifact found: $legacyPattern"
        }
    }
}

$refsPath = Join-Path $project "refs.json"
if (-not (Test-Path -LiteralPath $refsPath -PathType Leaf)) {
    $issues += "[missing] refs.json"
} else {
    try {
        $refsJson = Get-Content -LiteralPath $refsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $nodes = @($refsJson.nodes)
        $edges = @($refsJson.edges)

        foreach ($duplicate in ($nodes | Group-Object id | Where-Object Count -gt 1)) {
            $issues += "[refs.json] duplicate node id $($duplicate.Name)"
        }
        foreach ($duplicate in ($nodes | Group-Object path | Where-Object Count -gt 1)) {
            $issues += "[refs.json] duplicate node path $($duplicate.Name)"
        }

        foreach ($document in $documents) {
            $node = @($nodes | Where-Object id -eq $document.Id)
            if ($node.Count -ne 1) {
                $issues += "[refs.json] $($document.Id): expected exactly one node"
                continue
            }
            if (($node[0].path -replace '\\', '/') -ne $document.Path) {
                $issues += "[refs.json] $($document.Id): node path mismatch"
            }
            foreach ($ref in $document.Frontmatter.Refs) {
                if (-not ($nodes | Where-Object id -eq $ref.id)) {
                    $issues += "[refs.json] $($document.Id): missing target node $($ref.id)"
                }
                if (-not ($edges | Where-Object {
                    $_.from -eq $document.Id -and $_.to -eq $ref.id -and $_.relation -eq $ref.relation
                })) {
                    $issues += "[refs.json] $($document.Id): missing edge to $($ref.id) ($($ref.relation))"
                }
            }
        }
    } catch {
        $issues += "[refs.json] parse failed: $($_.Exception.Message)"
    }
}

if ($issues.Count -gt 0) {
    Write-Host "Validation failed with $($issues.Count) issue(s)." -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

Write-Host "Validation passed for $($documents.Count) document(s)." -ForegroundColor Green
exit 0
