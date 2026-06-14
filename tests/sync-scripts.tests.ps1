$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$scriptsRoot = Join-Path $repoRoot 'scripts'
$syncScript = Join-Path $scriptsRoot 'sync-to-project.ps1'
$validateScript = Join-Path $scriptsRoot 'validate-skills.ps1'

if (-not (Test-Path -LiteralPath $syncScript)) {
    throw "Missing sync script: $syncScript"
}

if (-not (Test-Path -LiteralPath $validateScript)) {
    throw "Missing validation script: $validateScript"
}

& $validateScript -RepoPath $repoRoot

$projectPath = Join-Path ([System.IO.Path]::GetTempPath()) ("company-skills-sync-test-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $projectPath | Out-Null

try {
    & $syncScript -ProjectPath $projectPath -SourceRepoPath $repoRoot -SkipPull

    $targetSkills = Join-Path $projectPath '.codex\skills'
    $lockFile = Join-Path $projectPath '.codex\skills.lock.json'

    if (-not (Test-Path -LiteralPath (Join-Path $targetSkills 'using-superpowers\SKILL.md'))) {
        throw 'Expected using-superpowers skill to be synced'
    }

    if (-not (Test-Path -LiteralPath $lockFile)) {
        throw 'Expected .codex/skills.lock.json to be created'
    }

    $lock = Get-Content -LiteralPath $lockFile -Raw | ConvertFrom-Json
    if ($lock.targetDir -ne '.codex/skills') {
        throw "Unexpected lock targetDir: $($lock.targetDir)"
    }

    $excluded = Get-ChildItem -LiteralPath $targetSkills -Recurse -Force |
        Where-Object {
            $_.Name -eq '.installed-version' -or
            $_.Name -eq '.DS_Store' -or
            $_.Name -like '*.tmp' -or
            $_.Name -like '*.log' -or
            ($_.PSIsContainer -and ($_.Name -eq 'node_modules' -or $_.Name -eq '__pycache__'))
        }

    if ($excluded) {
        throw "Excluded files were synced: $($excluded[0].FullName)"
    }
}
finally {
    if (Test-Path -LiteralPath $projectPath) {
        Remove-Item -LiteralPath $projectPath -Recurse -Force
    }
}
