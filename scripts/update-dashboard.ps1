param(
    [string]$Repo = "monaxovdulov/homework-agent-lab",
    [string]$Output = "DASHBOARD.md"
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

$Issues = @(
    & gh issue list --repo $Repo --state all --limit 500 --json number,title,url,state,labels,updatedAt,createdAt |
        ConvertFrom-Json
)

$Prs = @(
    & gh pr list --repo $Repo --state all --limit 500 --json number,title,url,state,headRefName,body,updatedAt,createdAt |
        ConvertFrom-Json
)

function Get-Labels($Issue) {
    @($Issue.labels | ForEach-Object { $_.name })
}

function Get-LabelValue($Issue, [string]$Prefix, [string]$Default = "") {
    foreach ($Name in (Get-Labels $Issue)) {
        if ($Name.StartsWith($Prefix)) {
            return $Name.Substring($Prefix.Length)
        }
    }
    return $Default
}

function Md([string]$Text) {
    return ($Text -replace '\|', '\|' -replace "`r?`n", " ")
}

function ShortDate($Value) {
    if (-not $Value) {
        return ""
    }
    return ($Value -split "T")[0]
}

function CleanTitle([string]$Title) {
    return ($Title -replace '^\[homework\]\[[^\]]+\]\s*', '').Trim()
}

$Homework = @(
    foreach ($Issue in $Issues) {
        if ((Get-Labels $Issue) -contains "kind:homework") {
            $Issue
        }
    }
)

$PrsByIssue = @{}
foreach ($Pr in $Prs) {
    $MatchedIssues = New-Object System.Collections.Generic.HashSet[int]
    $Body = if ($null -eq $Pr.body) { "" } else { [string]$Pr.body }
    $Title = if ($null -eq $Pr.title) { "" } else { [string]$Pr.title }
    foreach ($Match in [regex]::Matches($Body, '(?i)Refs\s+#(\d+)')) {
        [void]$MatchedIssues.Add([int]$Match.Groups[1].Value)
    }
    $TitleMatch = [regex]::Match($Title, '\[[a-zA-Z0-9._-]+\]\[#(\d+)\]')
    if ($TitleMatch.Success) {
        [void]$MatchedIssues.Add([int]$TitleMatch.Groups[1].Value)
    }
    foreach ($IssueNumber in $MatchedIssues) {
        if (-not $PrsByIssue.ContainsKey($IssueNumber)) {
            $PrsByIssue[$IssueNumber] = New-Object System.Collections.Generic.List[object]
        }
        $PrsByIssue[$IssueNumber].Add($Pr)
    }
}

$Records = @(
    foreach ($Issue in $Homework) {
        $IssueNumber = [int]$Issue.number
        $Callsign = Get-LabelValue $Issue "student:" "unknown"
        $Status = Get-LabelValue $Issue "статус:" "неизвестно"
        $Mode = Get-LabelValue $Issue "mode:" "hints-only"
        $Storage = Get-LabelValue $Issue "storage:" "lab-public"
        $IssuePrs = if ($PrsByIssue.ContainsKey($IssueNumber)) { @($PrsByIssue[$IssueNumber]) } else { @() }
        $PrLinks = if ($IssuePrs.Count -gt 0) {
            (($IssuePrs | ForEach-Object { "[#$($_.number)]($($_.url)) $($_.state.ToLower())" }) -join ", ")
        } else {
            "-"
        }

        [PSCustomObject]@{
            Callsign = $Callsign
            Issue = $IssueNumber
            IssueLink = "[#$IssueNumber]($($Issue.url))"
            Title = CleanTitle $Issue.title
            State = $Issue.state
            Status = $Status
            Mode = $Mode
            Storage = $Storage
            Updated = ShortDate $Issue.updatedAt
            Created = ShortDate $Issue.createdAt
            Submission = "submissions/$Callsign/issue-$IssueNumber/"
            PrLinks = $PrLinks
        }
    }
) | Sort-Object Callsign, Issue

$StatusOrder = @(
    "ждет-ученика 🕯️",
    "ученик-работает ✏️",
    "нужна-помощь ❓",
    "нужны-правки 📝",
    "ждет-проверки 🔍",
    "зачтено ✅",
    "неизвестно"
)

$Lines = New-Object System.Collections.Generic.List[string]
$GeneratedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm 'UTC'")
$OpenRecords = @($Records | Where-Object { $_.State -eq "OPEN" })
$OpenPrs = @($Prs | Where-Object { $_.state -eq "OPEN" })

$Lines.Add("# Дашборд домашних заданий")
$Lines.Add("")
$Lines.Add("Источник: ``$Repo``")
$Lines.Add("Обновлено: ``$GeneratedAt``")
$Lines.Add("")
$Lines.Add("Этот файл публичный. В таблицах должны быть только позывные, Issue, PR и")
$Lines.Add("технические статусы. Не добавляйте реальные имена, контакты или секреты.")
$Lines.Add("")
$Lines.Add("## Сводка")
$Lines.Add("")
$Lines.Add("| Метрика | Значение |")
$Lines.Add("| --- | ---: |")
$Lines.Add("| Всего домашних Issue | $($Records.Count) |")
$Lines.Add("| Открытых домашних Issue | $($OpenRecords.Count) |")
$Lines.Add("| Открытых PR | $($OpenPrs.Count) |")
foreach ($Status in $StatusOrder) {
    $Count = @($Records | Where-Object { $_.Status -eq $Status }).Count
    if ($Count -gt 0) {
        $Lines.Add("| $(Md $Status) | $Count |")
    }
}
foreach ($Storage in @($Records | Select-Object -ExpandProperty Storage -Unique | Sort-Object)) {
    $Count = @($Records | Where-Object { $_.Storage -eq $Storage }).Count
    if ($Count -gt 0) {
        $Lines.Add("| storage:$(Md $Storage) | $Count |")
    }
}
$Lines.Add("")

$Lines.Add("## Ученики")
$Lines.Add("")
$Lines.Add("| Позывной | Активные | Ждет ученика | В работе | Нужна помощь | Нужны правки | Ждет проверки | Зачтено | Issue |")
$Lines.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
$Callsigns = @($Records | Select-Object -ExpandProperty Callsign -Unique | Sort-Object)
foreach ($Callsign in $Callsigns) {
    $Rows = @($Records | Where-Object { $_.Callsign -eq $Callsign })
    $Active = @($Rows | Where-Object { $_.State -eq "OPEN" -and $_.Status -ne "зачтено ✅" }).Count
    $IssuesText = (($Rows | ForEach-Object { $_.IssueLink }) -join ", ")
    $Lines.Add(
        "| ``$(Md $Callsign)`` | $Active | " +
        "$(@($Rows | Where-Object { $_.Status -eq 'ждет-ученика 🕯️' }).Count) | " +
        "$(@($Rows | Where-Object { $_.Status -eq 'ученик-работает ✏️' }).Count) | " +
        "$(@($Rows | Where-Object { $_.Status -eq 'нужна-помощь ❓' }).Count) | " +
        "$(@($Rows | Where-Object { $_.Status -eq 'нужны-правки 📝' }).Count) | " +
        "$(@($Rows | Where-Object { $_.Status -eq 'ждет-проверки 🔍' }).Count) | " +
        "$(@($Rows | Where-Object { $_.Status -eq 'зачтено ✅' }).Count) | $IssuesText |"
    )
}
$Lines.Add("")

$Lines.Add("## Доска По Статусам")
foreach ($Status in $StatusOrder) {
    $StatusRows = @($Records | Where-Object { $_.Status -eq $Status } | Sort-Object Updated, Callsign, Issue -Descending)
    if ($StatusRows.Count -eq 0) {
        continue
    }
    $Lines.Add("")
    $Lines.Add("### $Status")
    $Lines.Add("")
    $Lines.Add("| Позывной | Issue | Задание | Storage | PR | Обновлено | Сдача |")
    $Lines.Add("| --- | --- | --- | --- | --- | --- | --- |")
    foreach ($Row in $StatusRows) {
        $Lines.Add("| ``$(Md $Row.Callsign)`` | $($Row.IssueLink) | $(Md $Row.Title) | ``storage:$(Md $Row.Storage)`` | $($Row.PrLinks) | $($Row.Updated) | ``$(Md $Row.Submission)`` |")
    }
}
$Lines.Add("")

$ReviewRows = @($Records | Where-Object { $_.Status -eq "ждет-проверки 🔍" } | Sort-Object Updated)
$Lines.Add("## Очередь Проверки")
$Lines.Add("")
if ($ReviewRows.Count -gt 0) {
    $Lines.Add("| Позывной | Issue | Storage | PR | Обновлено | Что открыть |")
    $Lines.Add("| --- | --- | --- | --- | --- | --- |")
    foreach ($Row in $ReviewRows) {
        $Lines.Add("| ``$(Md $Row.Callsign)`` | $($Row.IssueLink) | ``storage:$(Md $Row.Storage)`` | $($Row.PrLinks) | $($Row.Updated) | ``$(Md $Row.Submission)`` |")
    }
} else {
    $Lines.Add("_Сейчас нет домашних в статусе ``статус:ждет-проверки 🔍``._")
}
$Lines.Add("")

$Lines.Add("## PR")
$Lines.Add("")
if ($Prs.Count -gt 0) {
    $Lines.Add("| PR | Статус | Branch | Обновлено |")
    $Lines.Add("| --- | --- | --- | --- |")
    foreach ($Pr in @($Prs | Sort-Object updatedAt -Descending)) {
        $Lines.Add("| [#$($Pr.number)]($($Pr.url)) $(Md $Pr.title) | $(Md $Pr.state) | ``$(Md $Pr.headRefName)`` | $(ShortDate $Pr.updatedAt) |")
    }
} else {
    $Lines.Add("_PR пока нет._")
}
$Lines.Add("")

$Lines.Add("## Обновление")
$Lines.Add("")
$Lines.Add("Bash:")
$Lines.Add("")
$Lines.Add("````bash")
$Lines.Add("scripts/update-dashboard.sh")
$Lines.Add("````")
$Lines.Add("")
$Lines.Add("Windows PowerShell:")
$Lines.Add("")
$Lines.Add("````powershell")
$Lines.Add("powershell -ExecutionPolicy Bypass -File scripts/update-dashboard.ps1")
$Lines.Add("````")

Set-Content -LiteralPath $Output -Value $Lines -Encoding UTF8
Write-Output "Updated $Output from $Repo"
