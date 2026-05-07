param(
    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [string]$Repo = "monaxovdulov/homework-agent-lab",

    [switch]$Close
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Missing required command: gh"
}

& gh issue edit $Issue --repo $Repo `
    --remove-label "статус:ждет-ученика 🕯️" `
    --remove-label "статус:ученик-работает ✏️" `
    --remove-label "статус:ждет-проверки 🔍" `
    --remove-label "статус:нужна-помощь ❓" `
    --remove-label "статус:нужны-правки 📝" `
    --add-label "статус:зачтено ✅"

$Body = @"
Зачтено.

Итог проверки: $Summary

accepted_at: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
"@

& gh issue comment $Issue --repo $Repo --body $Body

if ($Close) {
    & gh issue close $Issue --repo $Repo --comment "Issue закрыт учителем после зачета."
}
