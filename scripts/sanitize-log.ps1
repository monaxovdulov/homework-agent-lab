param(
    [string]$InputLog,
    [string]$OutputLog
)

$ErrorActionPreference = "Stop"

if ($InputLog) {
    $Text = Get-Content -LiteralPath $InputLog -Raw
} else {
    $Text = [Console]::In.ReadToEnd()
}

$Text = $Text -replace 'sk-[A-Za-z0-9_-]{10,}', '[SECRET]'
$Text = $Text -replace 'gh[pousr]_[A-Za-z0-9_]{20,}', '[SECRET]'
$Text = $Text -replace 'xox[baprs]-[A-Za-z0-9-]{10,}', '[SECRET]'
$Text = $Text -replace '-----BEGIN [A-Z ]*PRIVATE KEY-----', '[SECRET]'
$Text = $Text -replace '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[PERSONAL_DATA]'
$Text = $Text -replace '\+?[0-9][0-9 ()-]{8,}[0-9]', '[PERSONAL_DATA]'
$Text = $Text -replace '(?i)(?<!\p{L})(бля[дт]ь?|сука|хуй|хуе\p{L}*|пизд\p{L}*|еба\p{L}*|ёба\p{L}*|чмо|педик|тварь|дебил|идиот)(?!\p{L})', '[цензура]'
$Text = $Text -replace '[ \t]{3,}', ' '

if ($OutputLog) {
    Set-Content -LiteralPath $OutputLog -Value $Text -Encoding UTF8
} else {
    Write-Output $Text
}
