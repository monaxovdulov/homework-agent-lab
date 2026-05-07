param(
    [Parameter(Mandatory = $true)]
    [string]$Callsign,

    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [string]$Repo = "monaxovdulov/homework-agent-lab",

    [switch]$Draft
)

$ErrorActionPreference = "Stop"

if ($Callsign -notmatch '^[a-zA-Z0-9._-]+$') {
    throw "FAIL: callsign may contain only letters, numbers, dot, underscore, and dash"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "FAIL: missing required command: git"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "FAIL: missing required command: gh"
}

$Root = (& git rev-parse --show-toplevel 2>$null)
if (-not $Root) {
    $Root = (Get-Location).Path
}
Set-Location $Root

$Dir = "submissions/$Callsign/issue-$Issue"
$Branch = "student/$Callsign/issue-$Issue"

& "$PSScriptRoot/preflight-homework.ps1" -Callsign $Callsign -Issue $Issue -Repo $Repo

$CurrentBranch = (& git branch --show-current)
if ($CurrentBranch -ne $Branch) {
    & git show-ref --verify --quiet "refs/heads/$Branch"
    if ($LASTEXITCODE -eq 0) {
        & git switch $Branch
    } else {
        & git switch -c $Branch
    }
}

& git add "$Dir/"

$Staged = @(& git diff --cached --name-only -- "$Dir/")
if ($Staged.Count -gt 0) {
    & git commit -m "[$Callsign][#$Issue] Submit homework"
} else {
    Write-Host "No new staged changes in $Dir; reusing existing branch state."
}

& git push -u origin $Branch

$ExistingPr = (& gh pr list --repo $Repo --head $Branch --state open --json url --jq '.[0].url // empty')

if ($ExistingPr) {
    $PrUrl = $ExistingPr
    Write-Host "Reusing existing PR: $PrUrl"
} else {
    $PrBody = @"
Refs #$Issue

## Что сделал

$Summary

## Как проверил

- Ученик описал проверки или примеры запуска в `$Dir/submission.md`.
- Автоматически запущен ``scripts/preflight-homework.ps1 -Callsign $Callsign -Issue $Issue``.

## Что понял

- См. рефлексию ученика в `$Dir/submission.md`.

## Где лежит решение

````text
$Dir/
````

## Что проверить учителю

- Соответствие Issue #$Issue.
- Корректность решения и проверок.
"@
    $PrBodyFile = New-TemporaryFile
    Set-Content -LiteralPath $PrBodyFile -Value $PrBody -Encoding UTF8

    $CreateArgs = @(
        "pr", "create",
        "--repo", $Repo,
        "--title", "[$Callsign][#$Issue] Решение домашки",
        "--body-file", $PrBodyFile
    )
    if ($Draft) {
        $CreateArgs += "--draft"
    }

    $PrUrl = (& gh @CreateArgs)
    Remove-Item -LiteralPath $PrBodyFile -Force
}

& "$PSScriptRoot/complete-homework.ps1" -Issue $Issue -Summary "$Summary PR: $PrUrl" -Repo $Repo

Write-Output $PrUrl
