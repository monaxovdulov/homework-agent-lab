param(
    [Parameter(Mandatory = $true)]
    [string]$Callsign,

    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"
$Failed = $false

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
        Warn "no README.md or reflection.md found; teacher review may ask for explanation"
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
    } catch {
        Warn "could not read Issue labels through gh"
    }
} else {
    Warn "gh is not installed; skipped Issue label checks"
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
