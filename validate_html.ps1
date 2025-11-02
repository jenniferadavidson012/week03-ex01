# Lightweight HTML validator in PowerShell
# Checks: doctype, html/head/body/title presence, lang attr, link href/rel, unescaped ampersands
$path = "c:\Users\bdavi\OneDrive\index.html\week03-ex01\index.html week3 -ex01"
if (-not (Test-Path $path)){
    Write-Host "File not found: $path" -ForegroundColor Red
    exit 2
}
$content = Get-Content -Raw -LiteralPath $path -ErrorAction Stop

function Check([string]$desc, [bool]$passed, [string]$msg){
    if ($passed){
        Write-Host "PASS: $desc" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $desc" -ForegroundColor Red
        Write-Host "  -> $msg"
    }
}

# 1 DOCTYPE
$hasDoctype = [regex]::IsMatch($content, '<!DOCTYPE\s+html', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
Check "DOCTYPE declaration present" $hasDoctype "Add <!DOCTYPE html> at top if missing."

# 2 html open/close
$htmlOpen = ([regex]::Matches($content,'<html\b',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$htmlClose = ([regex]::Matches($content,'</html>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
Check "Single <html> open/close" ($htmlOpen -eq 1 -and $htmlClose -eq 1) "Found opens: $htmlOpen, closes: $htmlClose."

# 3 lang attribute on html
 # simpler lang presence check
 $hasLang = [regex]::IsMatch($content, '<html[^>]*\blang\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
Check "<html> has lang attribute" $hasLang "Add lang=\"en\" (or appropriate) to <html> tag."

# 4 head and body
$hasHeadOpen = [regex]::IsMatch($content, '<head\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$hasHeadClose = [regex]::IsMatch($content, '</head>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$bodyOpenCount = ([regex]::Matches($content,'<body\b',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$bodyCloseCount = ([regex]::Matches($content,'</body>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
Check "<head> present and closed" ($hasHeadOpen -and $hasHeadClose) "Ensure <head>...</head> exists and closed."
Check "<body> present and single closed" ($bodyOpenCount -eq 1 -and $bodyCloseCount -eq 1) "Found <body> opens: $bodyOpenCount, closes: $bodyCloseCount."

# 5 title inside head
 $hasTitleInHead = [regex]::IsMatch($content, '<head[\s\S]*?<title>.*?</title>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
Check "<title> present inside <head>" $hasTitleInHead "Add a <title> inside <head> to improve accessibility and SEO."

# 6 link tags have href and rel
$linkMatches = [regex]::Matches($content, '<link\s+([^>]+)>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$badLinks = @()
foreach ($m in $linkMatches){
    $attrs = $m.Groups[1].Value
    $hasHref = [regex]::IsMatch($attrs, '\bhref\s*=\s*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $hasRel = [regex]::IsMatch($attrs, '\brel\s*=\s*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not ($hasHref -and $hasRel)){
        $badLinks += $attrs
    }
}
Check "All <link> tags have href and rel" ($badLinks.Count -eq 0) "Problematic <link> count: $($badLinks.Count)"
if ($badLinks.Count -gt 0){
    Write-Host "Examples:"; $badLinks | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
}

# 7 unescaped ampersands
$lines = $content -split "\r?\n"
$ampProblems = @()
for ($i=0;$i -lt $lines.Count; $i++){
    if ([regex]::IsMatch($lines[$i], '&(?!(#?[0-9]+|#x[0-9a-fA-F]+|[a-zA-Z]+);)')){
        $ampProblems += @{Line=$i+1; Text=$lines[$i].Trim()}
    }
}
Check "No unescaped ampersands" ($ampProblems.Count -eq 0) "Found $($ampProblems.Count) line(s) with literal '&' that may need escaping."
if ($ampProblems.Count -gt 0){
    Write-Host "Examples:"; $ampProblems | Select-Object -First 5 | ForEach-Object { Write-Host "  Line $($_.Line): $($_.Text)" }
}

# Summary and exit code
$results = @(
    $hasDoctype, ($htmlOpen -eq 1 -and $htmlClose -eq 1), $hasLang,
    ($hasHeadOpen -and $hasHeadClose), ($bodyOpenCount -eq 1 -and $bodyCloseCount -eq 1), $hasTitleInHead, ($badLinks.Count -eq 0), ($ampProblems.Count -eq 0)
)
$passedAll = ($results -notcontains $false)
$overall = if ($passedAll) { 'PASS' } else { 'FAIL' }
Write-Host "`nOverall: $overall" -ForegroundColor Yellow
if ($passedAll){ exit 0 } else { exit 1 }