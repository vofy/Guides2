$RootDir = "docs"

Get-ChildItem -Path $RootDir -Recurse -Filter *.md | ForEach-Object {

    $file = $_.FullName
    $content = Get-Content $file -Raw -Encoding UTF8

    # přeskoč soubory, které už mají YAML front matter
    if ($content -match '^\s*---') {
        return
    }

    $title = $_.BaseName `
        -replace '[-_]', ' ' `
        -replace '\b(\p{L})', { $args[0].Value.ToUpper() }

    $newContent = @"
---
title: $title
---

$content
"@

    Set-Content -Path $file -Value $newContent -Encoding UTF8

    Write-Host "✔ Added front matter: $file"
}
