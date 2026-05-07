param(
    [Parameter(Mandatory = $true)]
    [string]$Callsign,

    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"
$Failed = $false
$Storage = "lab-public"

function Fail([string]$Message) {
    Write-Error "FAIL: $Message" -ErrorAction Continue
    $script:Failed = $true
}

function Warn([string]$Message) {
    Write-Host "WARN: $Message"
}

function Ok([string]$Message) {
    Write-Host "OK: $Message"
}

if ($Callsign -notmatch '^[a-zA-Z0-9._-]+$') {
    Fail "callsign may contain only letters, numbers, dot, underscore, and dash"
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "missing required command: git"
    exit 1
}

$Root = (& git rev-parse --show-toplevel 2>$null)
if (-not $Root) {
    $Root = (Get-Location).Path
}
Set-Location $Root

$Dir = "submissions/$Callsign/issue-$Issue"
$Manifest = "$Dir/submission.md"

if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
    Fail "submission directory not found: $Dir"
} else {
    Ok "submission directory exists: $Dir"
}

if (Test-Path -LiteralPath $Dir -PathType Container) {
    $Files = @(Get-ChildItem -LiteralPath $Dir -File -Recurse -Force)
    if ($Files.Count -eq 0) {
        Fail "submission directory has no files"
    } else {
        Ok "files in submission directory: $($Files.Count)"
    }

    if ((-not (Test-Path -LiteralPath "$Dir/README.md" -PathType Leaf)) -and
        (-not (Test-Path -LiteralPath "$Dir/reflection.md" -PathType Leaf))) {
        Ok "README.md/reflection.md not found; submission.md is the required manifest"
    } else {
        Ok "README.md or reflection.md found"
    }
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        $Labels = @(& gh issue view $Issue --repo $Repo --json labels --jq '.labels[].name')
        if ($Labels -notcontains "student:$Callsign") {
            Fail "Issue #$Issue does not have label student:$Callsign"
        } else {
            Ok "Issue has label student:$Callsign"
        }

        if ($Labels -notcontains "kind:homework") {
            Fail "Issue #$Issue does not have label kind:homework"
        } else {
            Ok "Issue has label kind:homework"
        }

        $StorageLabels = @($Labels | Where-Object { $_ -like "storage:*" })
        if ($StorageLabels.Count -eq 0) {
            Warn "Issue has no storage:* label; assuming storage:lab-public"
        } elseif ($StorageLabels.Count -ne 1) {
            Fail "Issue must have exactly one storage:* label"
            $StorageLabels | ForEach-Object { Write-Error $_ -ErrorAction Continue }
        } else {
            $Storage = $StorageLabels[0] -replace '^storage:', ''
        }
    } catch {
        Warn "could not read Issue labels through gh"
    }
} else {
    Warn "gh is not installed; skipped Issue label checks"
}

if (@("lab-public", "student-public-repo", "student-private-repo", "external-link", "no-code") -contains $Storage) {
    Ok "storage mode: storage:$Storage"
} else {
    Fail "unknown storage mode: storage:$Storage"
}

if (Test-Path -LiteralPath $Dir -PathType Container) {
    if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
        Fail "missing required manifest: $Manifest"
    } else {
        Ok "submission manifest found: $Manifest"
        $ManifestText = Get-Content -LiteralPath $Manifest -Raw

        if ($ManifestText -notmatch "(?im)^Issue:\s*#?$Issue(\s|$)") {
            Fail "manifest must contain: Issue: #$Issue"
        } else {
            Ok "manifest references Issue #$Issue"
        }

        if ($ManifestText -notmatch "(?im)^Callsign:\s*$([regex]::Escape($Callsign))(\s|$)") {
            Fail "manifest must contain: Callsign: $Callsign"
        } else {
            Ok "manifest references callsign $Callsign"
        }

        if ($ManifestText -notmatch "(?im)^Storage:\s*(storage:)?$([regex]::Escape($Storage))(\s|$)") {
            Fail "manifest must contain: Storage: $Storage"
        } else {
            Ok "manifest storage matches storage:$Storage"
        }

        if ($ManifestText -notmatch "(?im)^(Checks|Проверки|Проверка):|^##\s*(Checks|Проверки|Проверка)") {
            Fail "manifest must describe checks"
        } else {
            Ok "manifest describes checks"
        }

        if ($ManifestText -notmatch "(?im)^(Reflection|Рефлексия):|^##\s*(Reflection|Рефлексия)") {
            Fail "manifest must include reflection"
        } else {
            Ok "manifest includes reflection"
        }

        switch ($Storage) {
            { $_ -in @("student-public-repo", "external-link") } {
                if ($ManifestText -notmatch "(?im)^(Submission URL|URL|Repo|PR|Link|Ссылка):\s*https?://") {
                    Fail "manifest for storage:$Storage must include a public-safe Submission URL/Repo/PR/Link"
                } else {
                    Ok "manifest includes public-safe external URL"
                }
                break
            }
            "student-private-repo" {
                if ($ManifestText -notmatch "(?im)^(Access|Доступ):") {
                    Fail "manifest for storage:student-private-repo must describe teacher access without exposing secrets"
                } else {
                    Ok "manifest describes private repo access"
                }
                break
            }
            "lab-public" {
                $NonManifestCount = @(Get-ChildItem -LiteralPath $Dir -File -Recurse -Force | Where-Object { $_.Name -ne "submission.md" }).Count
                if ($NonManifestCount -eq 0) {
                    Warn "storage:lab-public usually includes code or answer files next to submission.md"
                }
                break
            }
            "no-code" {
                if ((-not (Test-Path -LiteralPath "$Dir/answer.md" -PathType Leaf)) -and
                    ($ManifestText -notmatch "(?im)^(Answer|Ответ):|^##\s*(Answer|Ответ)")) {
                    Warn "storage:no-code usually includes answer.md or an Answer section in submission.md"
                }
                break
            }
        }
    }
}

if (Test-Path -LiteralPath $Dir -PathType Container) {
    $RiskyFiles = @(
        Get-ChildItem -LiteralPath $Dir -File -Recurse -Force |
            Where-Object {
                $_.Name -eq ".env" -or
                $_.Name -eq "id_rsa" -or
                $_.Name -eq "id_ed25519" -or
                $_.Name -like "*.pem" -or
                $_.Name -like "*.key"
            } |
            ForEach-Object { $_.FullName }
    )

    if ($RiskyFiles.Count -gt 0) {
        Fail "risky secret-like file names found:"
        $RiskyFiles | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    } else {
        Ok "no risky secret-like file names found"
    }

    $SecretPatterns = @(
        'sk-[A-Za-z0-9_-]{10,}',
        'gh[pousr]_[A-Za-z0-9_]{20,}',
        '-----BEGIN [A-Z ]*PRIVATE KEY-----',
        'xox[baprs]-[A-Za-z0-9-]{10,}'
    )
    $PersonalDataPatterns = @(
        '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
        '\+?[0-9][0-9 ()-]{8,}[0-9]'
    )

    $SecretFiles = New-Object System.Collections.Generic.HashSet[string]
    $PersonalDataFiles = New-Object System.Collections.Generic.HashSet[string]

    foreach ($File in $Files) {
        try {
            $Text = Get-Content -LiteralPath $File.FullName -Raw -ErrorAction Stop
        } catch {
            continue
        }

        foreach ($Pattern in $SecretPatterns) {
            if ($Text -match $Pattern) {
                [void]$SecretFiles.Add($File.FullName)
            }
        }

        foreach ($Pattern in $PersonalDataPatterns) {
            if ($Text -match $Pattern) {
                [void]$PersonalDataFiles.Add($File.FullName)
            }
        }
    }

    if ($SecretFiles.Count -gt 0) {
        Fail "possible secret found in these files:"
        $SecretFiles | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    } else {
        Ok "no obvious API keys or private keys found"
    }

    if ($PersonalDataFiles.Count -gt 0) {
        Warn "possible email or phone-like personal data found in these files:"
        $PersonalDataFiles | ForEach-Object { Write-Host $_ }
    } else {
        Ok "no obvious email or phone-like data found"
    }
}

if ($Failed) {
    exit 1
}

Ok "preflight passed"
