param(
    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Missing required command: gh"
}

& gh issue edit $Issue --repo $Repo `
    --remove-label "статус:ждет-ученика 🕯️" `
    --remove-label "статус:ученик-работает ✏️" `
    --remove-label "статус:ждет-проверки 🔍" `
    --remove-label "статус:нужны-правки 📝" `
    --add-label "статус:нужна-помощь ❓"

$Body = @"
Нужна подсказка учителя: $Message

requested_at: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
"@

& gh issue comment $Issue --repo $Repo --body $Body
