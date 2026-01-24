$RootDir = "docs"

Get-ChildItem -Path $RootDir -Recurse -Filter *.md | ForEach-Object {

    $file = $_.FullName
    $content = Get-Content $file -Raw -Encoding UTF8

    # Skip files without front matter
    if (-not ($content -match '^\s*---')) {
        Write-Host "⚠ Skipping (no front matter): $file"
        return
    }

    # Calculate parent relative to docs
    $rootFull = (Resolve-Path $RootDir).Path
    $dirFull  = (Resolve-Path $_.DirectoryName).Path
    $rel      = $dirFull.Substring($rootFull.Length).Trim('\')
    $parent   = if ($rel -ne '') { $rel -replace '\\', '/' } else { $null }

    if (-not $parent) {
        Write-Host "ℹ No parent needed for: $file"
        return
    }

    # Split content into lines
    $lines = $content -split "`n"

    # Find front matter start and end
    $fmStart = ($lines | Select-String -Pattern '^\s*---' | Select-Object -First 1).LineNumber - 1
    $fmEndRel = ($lines[$fmStart+1..($lines.Length-1)] | Select-String -Pattern '^\s*---' | Select-Object -First 1).LineNumber
    $fmEnd = if ($fmEndRel) { $fmStart + $fmEndRel } else { $fmStart + 1 }

    # Extract front matter lines
    $fmLines = @()
    if ($fmEnd -gt $fmStart + 1) {
        $fmLines = $lines[($fmStart+1)..($fmEnd-1)]
        if (-not ($fmLines -is [Array])) { $fmLines = @($fmLines) }
    }

    # Remove ALL existing parent lines
    $fmLines = $fmLines | Where-Object { $_ -notmatch '^\s*parent:' }

    # Insert the new parent at the beginning of front matter
    $fmLines = @("parent: $parent") + $fmLines

    # Reassemble all lines
    $newLines = @()
    $newLines += $lines[0..$fmStart]        # opening ---
    $newLines += $fmLines                    # updated front matter
    if ($fmEnd -lt $lines.Length) {
        $newLines += $lines[$fmEnd..($lines.Length-1)]  # rest of content
    }

    # Save file
    Set-Content -Path $file -Value ($newLines -join "`n") -Encoding UTF8

    Write-Host "✔ Updated parent: $file -> $parent"
}
