param(
    [string]$Callsign,
    [switch]$Json,
    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"

if ($Callsign -and $Callsign -notmatch '^[a-zA-Z0-9._-]+$') {
    throw "--callsign may contain only letters, numbers, dot, underscore, and dash"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Missing required command: gh"
}

$IssuesRaw = & gh issue list --repo $Repo --limit 100 --json number,title,url,labels,updatedAt
$Issues = @($IssuesRaw | ConvertFrom-Json)

$Filtered = @(
    foreach ($Issue in $Issues) {
        $Labels = @($Issue.labels | ForEach-Object { $_.name })
        $Matches = $Labels -contains "role:student" -and
            $Labels -contains "kind:homework" -and
            $Labels -contains "статус:ждет-ученика 🕯️"

        if ($Callsign) {
            $Matches = $Matches -and ($Labels -contains "student:$Callsign")
        }

        if ($Matches) {
            $Issue
        }
    }
)

if ($Json) {
    $Filtered | ConvertTo-Json -Depth 10
} else {
    foreach ($Issue in $Filtered) {
        Write-Output "#$($Issue.number)`t$($Issue.title)`t$($Issue.updatedAt)`t$($Issue.url)"
    }
}
