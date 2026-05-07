param(
    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Missing required command: gh"
}

& gh issue edit $Issue --repo $Repo `
    --remove-label "статус:ждет-ученика 🕯️" `
    --add-label "статус:ученик-работает ✏️"

$Body = @"
Домашка взята в работу Codex-наставником ученика.

claimed_at: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
"@

& gh issue comment $Issue --repo $Repo --body $Body
