param(
    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Missing required command: gh"
}

$Body = @"
Готово к проверке учителем.

Итог: $Summary

completed_at: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
"@

& gh issue comment $Issue --repo $Repo --body $Body
& gh issue edit $Issue --repo $Repo `
    --remove-label "статус:ждет-ученика 🕯️" `
    --remove-label "статус:ученик-работает ✏️" `
    --remove-label "статус:нужна-помощь ❓" `
    --remove-label "статус:нужны-правки 📝" `
    --add-label "статус:ждет-проверки 🔍"
