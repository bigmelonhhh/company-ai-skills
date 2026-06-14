param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$SourceRepoPath = '',
    [string]$RepoUrl = 'https://github.com/bigmelonhhh/company-ai-skills.git',
    [string]$CachePath = (Join-Path $env:USERPROFILE '.company-ai\company-ai-skills'),
    [switch]$SkipPull
)

$ErrorActionPreference = 'Stop'

$ExcludedFileNames = @('.installed-version', '.DS_Store')
$ExcludedFilePatterns = @('*.tmp', '*.log')
$ExcludedDirNames = @('node_modules', '__pycache__')

function Get-FullPath {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Assert-PathInside {
    param(
        [string]$ChildPath,
        [string]$ParentPath
    )

    $child = Get-FullPath $ChildPath
    $parent = (Get-FullPath $ParentPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $parent = $parent + [System.IO.Path]::DirectorySeparatorChar

    if (-not ($child.StartsWith($parent, [System.StringComparison]::OrdinalIgnoreCase))) {
        throw "Refusing to modify path outside project: $child"
    }
}

function Invoke-Git {
    param([string[]]$Arguments)

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Resolve-SourceRepo {
    if ($SourceRepoPath) {
        $resolved = Resolve-Path -LiteralPath $SourceRepoPath
        return $resolved.Path
    }

    $scriptRepo = Split-Path -Parent $PSScriptRoot
    if (Test-Path -LiteralPath (Join-Path $scriptRepo 'skills')) {
        return $scriptRepo
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is required when SourceRepoPath is not provided.'
    }

    if (-not (Test-Path -LiteralPath (Join-Path $CachePath '.git'))) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CachePath) | Out-Null
        Invoke-Git @('clone', $RepoUrl, $CachePath)
    }
    elseif (-not $SkipPull) {
        Invoke-Git @('-C', $CachePath, 'pull', '--ff-only')
    }

    return (Resolve-Path -LiteralPath $CachePath).Path
}

function Should-SkipItem {
    param([System.IO.FileSystemInfo]$Item)

    if ($Item.PSIsContainer -and ($ExcludedDirNames -contains $Item.Name)) {
        return $true
    }

    if (-not $Item.PSIsContainer) {
        if ($ExcludedFileNames -contains $Item.Name) {
            return $true
        }

        foreach ($pattern in $ExcludedFilePatterns) {
            if ($Item.Name -like $pattern) {
                return $true
            }
        }
    }

    return $false
}

function Copy-FilteredTree {
    param(
        [string]$Source,
        [string]$Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        if (Should-SkipItem $_) {
            return
        }

        $childDestination = Join-Path $Destination $_.Name
        if ($_.PSIsContainer) {
            Copy-FilteredTree -Source $_.FullName -Destination $childDestination
        }
        else {
            Copy-Item -LiteralPath $_.FullName -Destination $childDestination -Force
        }
    }
}

$projectRoot = Get-FullPath $ProjectPath
New-Item -ItemType Directory -Force -Path $projectRoot | Out-Null

$sourceRepo = Resolve-SourceRepo
$sourceSkills = Join-Path $sourceRepo 'skills'
if (-not (Test-Path -LiteralPath $sourceSkills)) {
    throw "Source repository does not contain a skills directory: $sourceSkills"
}

$codexDir = Join-Path $projectRoot '.codex'
$targetSkills = Join-Path $codexDir 'skills'
$tempSkills = Join-Path $codexDir ("skills.tmp-" + [System.Guid]::NewGuid().ToString('N'))
$lockFile = Join-Path $codexDir 'skills.lock.json'

Assert-PathInside -ChildPath $codexDir -ParentPath $projectRoot
Assert-PathInside -ChildPath $targetSkills -ParentPath $projectRoot
Assert-PathInside -ChildPath $tempSkills -ParentPath $projectRoot
Assert-PathInside -ChildPath $lockFile -ParentPath $projectRoot

New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

try {
    Copy-FilteredTree -Source $sourceSkills -Destination $tempSkills

    if (Test-Path -LiteralPath $targetSkills) {
        Remove-Item -LiteralPath $targetSkills -Recurse -Force
    }
    Move-Item -LiteralPath $tempSkills -Destination $targetSkills
}
finally {
    if (Test-Path -LiteralPath $tempSkills) {
        Remove-Item -LiteralPath $tempSkills -Recurse -Force
    }
}

$commit = 'unknown'
if (Test-Path -LiteralPath (Join-Path $sourceRepo '.git')) {
    $commit = (& git -C $sourceRepo rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $commit) {
        $commit = 'unknown'
    }
}

$skillCount = (Get-ChildItem -LiteralPath $targetSkills -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')
} | Measure-Object).Count

$lock = [ordered]@{
    source = $RepoUrl
    sourceRepoPath = $sourceRepo
    commit = $commit
    syncedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    targetDir = '.codex/skills'
    skillCount = $skillCount
}

$lock | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $lockFile -Encoding utf8

Write-Host "Skills synced to $targetSkills"
Write-Host "Source commit: $commit"
Write-Host "Skill count: $skillCount"
