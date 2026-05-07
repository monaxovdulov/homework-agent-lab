param(
    [string]$Repo = "monaxovdulov/homework-agent-lab"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "Missing required command: gh"
}

$Root = (& git rev-parse --show-toplevel 2>$null)
if (-not $Root) {
    $Root = (Get-Location).Path
}
Set-Location $Root

$IssuesRaw = & gh issue list --repo $Repo --state open --limit 200 --json number,title,url,labels
$Issues = @($IssuesRaw | ConvertFrom-Json)

$Rows = @(
    foreach ($Issue in $Issues) {
        $Labels = @($Issue.labels | ForEach-Object { $_.name })
        if ($Labels -notcontains "kind:homework") {
            continue
        }

        $StudentLabel = @($Labels | Where-Object { $_ -like "student:*" } | Select-Object -First 1)
        if ($StudentLabel.Count -eq 0) {
            $Callsign = "unknown"
        } else {
            $Callsign = $StudentLabel[0] -replace '^student:', ''
        }

        $StatusLabel = @($Labels | Where-Object { $_ -like "статус:*" } | Select-Object -First 1)
        if ($StatusLabel.Count -eq 0) {
            $Status = "неизвестно"
        } else {
            $Status = $StatusLabel[0] -replace '^статус:', ''
        }

        [PSCustomObject]@{
            Callsign = $Callsign
            Issue = [int]$Issue.number
            Url = $Issue.url
            Title = $Issue.title
            Status = $Status
            Path = "submissions/$Callsign/issue-$($Issue.number)/"
        }
    }
) | Sort-Object Callsign, Issue

$Lines = New-Object System.Collections.Generic.List[string]
$Lines.Add("# Домашки")
$Lines.Add("")
$Lines.Add("Публичный индекс домашних заданий по позывным.")
$Lines.Add("")
$Lines.Add("Этот файл нужен как устойчивый вход для учеников, потому что GitHub label-фильтры")
$Lines.Add("могут показывать пустой список до обновления поискового индекса. Источник")
$Lines.Add("задания все равно находится в GitHub Issue; здесь лежат только прямые ссылки.")
$Lines.Add("")
$Lines.Add("## Как проверять входящие")
$Lines.Add("")
$Lines.Add("Основной способ для Codex-наставника:")
$Lines.Add("")
$Lines.Add("````bash")
$Lines.Add("scripts/poll-homework.sh --callsign diogen")
$Lines.Add("````")
$Lines.Add("")
$Lines.Add("На Windows PowerShell:")
$Lines.Add("")
$Lines.Add("````powershell")
$Lines.Add("powershell -ExecutionPolicy Bypass -File scripts/poll-homework.ps1 -Callsign diogen")
$Lines.Add("````")
$Lines.Add("")
$Lines.Add("Если GitHub Issues или label-фильтр показывают пусто, сначала открой этот файл,")
$Lines.Add("а потом переходи по прямой ссылке на Issue.")

if ($Rows.Count -eq 0) {
    $Lines.Add("")
    $Lines.Add("_Открытых домашних заданий не найдено._")
} else {
    $Current = $null
    foreach ($Row in $Rows) {
        if ($Row.Callsign -ne $Current) {
            $Current = $Row.Callsign
            $Lines.Add("")
            $Lines.Add("## $Current")
            $Lines.Add("")
            $Lines.Add("| Issue | Тема | Статус | Сдача |")
            $Lines.Add("| --- | --- | --- | --- |")
        }

        $Title = $Row.Title -replace '\|', '\|'
        $Status = $Row.Status -replace '\|', '\|'
        $Lines.Add("| [#$($Row.Issue)]($($Row.Url)) | $Title | $Status | ``$($Row.Path)`` |")
    }
}

Set-Content -LiteralPath "HOMEWORK.md" -Value $Lines -Encoding UTF8
Write-Output "Updated HOMEWORK.md from $Repo"
