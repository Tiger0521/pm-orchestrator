#requires -version 5.1
<#!
.SYNOPSIS
    Move persisted user-story-breakdown artifacts into Feature-scoped requirement-analysis folders.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$projectRoot,

    [Parameter(Mandatory = $true)]
    [string]$projectPath
)

$ErrorActionPreference = "Stop"
$Utf8 = [System.Text.UTF8Encoding]::new($false)

function Get-CanonicalPath {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path).TrimEnd('\', '/')
}

function Get-StoryFeatureId {
    param([string]$Content, [string]$FileName)

    $matches = [regex]::Matches(
        $Content,
        '(?ms)^refs:\s*\r?\n\s*-\s+id:\s*["'']?(feature-\d{3,})["'']?\s*\r?\n\s+relation:\s*["'']?implements["'']?\s*(?:\r?\n|$)'
    )
    if ($matches.Count -ne 1) {
        throw "$FileName must have exactly one implements reference to feature-<nnn>."
    }
    return $matches[0].Groups[1].Value
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

$sourceDir = Join-Path $project 'docs/design'
$requirementsDir = Join-Path $project 'docs/requirement-analysis'
$refsPath = Join-Path $project 'refs.json'
if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) {
    throw "Legacy Story directory does not exist: $sourceDir"
}
if (-not (Test-Path -LiteralPath $requirementsDir -PathType Container)) {
    throw "Requirement-analysis directory does not exist: $requirementsDir"
}
if (-not (Test-Path -LiteralPath $refsPath -PathType Leaf)) {
    throw "Missing refs.json: $refsPath"
}

$stories = @(Get-ChildItem -LiteralPath $sourceDir -Filter 'story-*.md' -File | Sort-Object Name)
$matrices = @(Get-ChildItem -LiteralPath $sourceDir -Filter 'matrix-*.md' -File | Sort-Object Name)
if ($stories.Count -eq 0) {
    throw "No legacy Story files found in $sourceDir"
}
if ($matrices.Count -eq 0) {
    throw "No legacy matrix files found in $sourceDir"
}

$manifest = @()
foreach ($story in $stories) {
    $content = [System.IO.File]::ReadAllText($story.FullName, [System.Text.Encoding]::UTF8)
    $idMatch = [regex]::Match($content, '(?m)^id:\s*["'']?(story-\d{3,})["'']?\s*$')
    if (-not $idMatch.Success -or $idMatch.Groups[1].Value -ne $story.BaseName) {
        throw "$($story.Name) must have a matching story-<nnn> frontmatter id."
    }
    $featureId = Get-StoryFeatureId $content $story.Name
    $targetDir = Join-Path $requirementsDir $featureId
    if ((Test-Path -LiteralPath $targetDir) -and ((Get-Item -LiteralPath $targetDir).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Feature directory must not be a reparse point: $targetDir"
    }
    $target = Join-Path $targetDir $story.Name
    if (Test-Path -LiteralPath $target) {
        throw "Target already exists: $target"
    }
    $manifest += [PSCustomObject]@{
        Source = $story.FullName
        TargetDirectory = $targetDir
        Target = $target
        OldPath = "docs/design/$($story.Name)"
        NewPath = "docs/requirement-analysis/$featureId/$($story.Name)"
    }
}
foreach ($matrix in $matrices) {
    $content = [System.IO.File]::ReadAllText($matrix.FullName, [System.Text.Encoding]::UTF8)
    $idMatch = [regex]::Match($content, '(?m)^id:\s*["'']?(matrix-\d{3,})["'']?\s*$')
    if (-not $idMatch.Success -or $idMatch.Groups[1].Value -ne $matrix.BaseName) {
        throw "$($matrix.Name) must have a matching matrix-<nnn> frontmatter id."
    }
    $target = Join-Path $requirementsDir $matrix.Name
    if (Test-Path -LiteralPath $target) {
        throw "Target already exists: $target"
    }
    $manifest += [PSCustomObject]@{
        Source = $matrix.FullName
        TargetDirectory = $requirementsDir
        Target = $target
        OldPath = "docs/design/$($matrix.Name)"
        NewPath = "docs/requirement-analysis/$($matrix.Name)"
    }
}

$refsContent = [System.IO.File]::ReadAllText($refsPath, [System.Text.Encoding]::UTF8)
foreach ($entry in $manifest) {
    $count = [regex]::Matches($refsContent, [regex]::Escape($entry.OldPath)).Count
    if ($count -ne 1) {
        throw "refs.json must contain $($entry.OldPath) exactly once; found $count occurrence(s)."
    }
    $refsContent = $refsContent.Replace($entry.OldPath, $entry.NewPath)
}

foreach ($entry in $manifest) {
    [System.IO.Directory]::CreateDirectory($entry.TargetDirectory) | Out-Null
    Move-Item -LiteralPath $entry.Source -Destination $entry.Target
}
[System.IO.File]::WriteAllText($refsPath, $refsContent, $Utf8)

$storyCount = @($manifest | Where-Object { $_.NewPath -match '/story-' }).Count
$matrixCount = @($manifest | Where-Object { $_.NewPath -match '/matrix-' }).Count
Write-Output "Migrated $storyCount Story file(s) and $matrixCount matrix file(s)."