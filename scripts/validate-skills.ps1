param(
    [string]$RepoPath = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path -LiteralPath $RepoPath
$skillsRoot = Join-Path $repoRoot.Path 'skills'

if (-not (Test-Path -LiteralPath $skillsRoot)) {
    throw "Missing skills directory: $skillsRoot"
}

$skills = Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name
if (-not $skills) {
    throw "No skill directories found in $skillsRoot"
}

$failures = New-Object System.Collections.Generic.List[string]

foreach ($skill in $skills) {
    $skillMd = Join-Path $skill.FullName 'SKILL.md'
    $version = Join-Path $skill.FullName 'VERSION'
    $changelog = Join-Path $skill.FullName 'CHANGELOG.md'

    if ($skill.Name -notmatch '^[A-Za-z0-9-]+$') {
        $failures.Add("$($skill.Name): directory name must contain only letters, numbers, and hyphens")
    }

    if (-not (Test-Path -LiteralPath $skillMd)) {
        $failures.Add("$($skill.Name): missing SKILL.md")
    }
    else {
        $text = Get-Content -LiteralPath $skillMd -Raw
        if ($text -notmatch '(?m)^name:\s*\S+') {
            $failures.Add("$($skill.Name): SKILL.md missing frontmatter name")
        }
        if ($text -notmatch '(?m)^description:\s*.+') {
            $failures.Add("$($skill.Name): SKILL.md missing frontmatter description")
        }
    }

    if (-not (Test-Path -LiteralPath $version)) {
        $failures.Add("$($skill.Name): missing VERSION")
    }
    elseif (-not ((Get-Content -LiteralPath $version -Raw).Trim())) {
        $failures.Add("$($skill.Name): VERSION is empty")
    }

    if (-not (Test-Path -LiteralPath $changelog)) {
        $failures.Add("$($skill.Name): missing CHANGELOG.md")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "Skill validation failed with $($failures.Count) issue(s)."
}

Write-Host "Validated $($skills.Count) skill(s)."
