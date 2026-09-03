#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$directory = "."
$requestedExtensions = New-Object 'System.Collections.Generic.List[string]'
$limit = 15
$copyAll = $false
$view = $false
$lineNumbers = $true
$condensed = $false
$contextLines = 2
$directorySet = $false

function Show-Usage {
@"
blobcat - concatenate project files from a Git repository

Usage:
  blobcat [directory] [options]

Options:
  -d, --dir DIR             Directory to search. Default: current directory
  -e, --ext EXT[,EXT...]    File extensions. May be repeated. Default: py
  -a, --all                 Include all matching files instead of first 15
      --limit N             Change the default file limit
  -c, --condensed           Condense Python files to structural lines + context
      --context N           Lines before/after matches. Default: 2
  -v, --view                Print to terminal instead of clipboard
      --no-line-numbers     Disable line numbers
  -h, --help                Show this help

Examples:
  blobcat
  blobcat src
  blobcat -e py,yaml
  blobcat -e py -e json -e toml --all
  blobcat src -e py --condensed
  blobcat src -e py --condensed --context 4
  blobcat --view

Extension aliases:
  yaml / yml    matches both .yaml and .yml
"@
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $baseFull = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/')
    $targetFull = [System.IO.Path]::GetFullPath($TargetPath).TrimEnd('\', '/')

    if ($baseFull.Equals(
        $targetFull,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        return "."
    }

    $separator = [System.IO.Path]::DirectorySeparatorChar
    $baseUri = New-Object System.Uri($baseFull + $separator)
    $targetUri = New-Object System.Uri($targetFull)

    $relative = $baseUri.MakeRelativeUri($targetUri).ToString()
    $relative = [System.Uri]::UnescapeDataString($relative)

    return $relative.Replace('/', '\')
}

function Add-Extensions {
    param([string]$Value)

    foreach ($item in $Value.Split(",")) {
        $ext = $item.Trim().TrimStart(".").ToLowerInvariant()

        if ($ext) {
            $requestedExtensions.Add($ext)
        }
    }
}

function Get-CondensedRanges {
    param(
        [string[]]$Lines,
        [int]$Context
    )

    if ($Lines.Count -eq 0) {
        return @()
    }

    $pattern = '^\s*(?:' +
        'from\s+\S+\s+import\b|' +
        'import\s+\S+|' +
        '@[\w.]+' +
        '(?:\(.*)?|' +
        'class\s+\w+|' +
        '(?:async\s+)?def\s+\w+' +
        ')'

    $ranges = New-Object 'System.Collections.Generic.List[object]'

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch $pattern) {
            continue
        }

        $start = [Math]::Max(0, $i - $Context)
        $end = [Math]::Min($Lines.Count - 1, $i + $Context)

        if ($ranges.Count -eq 0) {
            $ranges.Add([PSCustomObject]@{
                Start = $start
                End   = $end
            })

            continue
        }

        $last = $ranges[$ranges.Count - 1]

        if ($start -le ($last.End + 1)) {
            $last.End = [Math]::Max($last.End, $end)
        }
        else {
            $ranges.Add([PSCustomObject]@{
                Start = $start
                End   = $end
            })
        }
    }

    return $ranges
}

function Append-FileLines {
    param(
        [System.Text.StringBuilder]$Builder,
        [string[]]$Lines,
        [bool]$UseLineNumbers,
        [bool]$UseCondensed,
        [int]$Context
    )

    if ($Lines.Count -eq 0) {
        return
    }

    $width = [Math]::Max(1, $Lines.Count.ToString().Length)

    if (-not $UseCondensed) {
        for ($i = 0; $i -lt $Lines.Count; $i++) {
            if ($UseLineNumbers) {
                $number = ($i + 1).ToString().PadLeft($width)
                [void]$Builder.AppendLine("$number | $($Lines[$i])")
            }
            else {
                [void]$Builder.AppendLine($Lines[$i])
            }
        }

        return
    }

    $ranges = @(Get-CondensedRanges -Lines $Lines -Context $Context)

    if ($ranges.Count -eq 0) {
        [void]$Builder.AppendLine("[no structural Python matches]")
        return
    }

    for ($r = 0; $r -lt $ranges.Count; $r++) {
        if ($r -gt 0) {
            [void]$Builder.AppendLine("...")
        }

        for ($i = $ranges[$r].Start; $i -le $ranges[$r].End; $i++) {
            if ($UseLineNumbers) {
                $number = ($i + 1).ToString().PadLeft($width)
                [void]$Builder.AppendLine("$number | $($Lines[$i])")
            }
            else {
                [void]$Builder.AppendLine($Lines[$i])
            }
        }
    }
}

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        { $_ -in "-a", "--all" } {
            $copyAll = $true
            continue
        }

        { $_ -in "-v", "--view" } {
            $view = $true
            continue
        }

        { $_ -in "-c", "--condensed" } {
            $condensed = $true
            continue
        }

        "--no-line-numbers" {
            $lineNumbers = $false
            continue
        }

        { $_ -in "-e", "--ext", "--extension" } {
            if (++$i -ge $args.Count) {
                throw "$_ requires one or more extensions"
            }

            Add-Extensions $args[$i]
            continue
        }

        { $_ -in "-d", "--dir", "--directory" } {
            if (++$i -ge $args.Count) {
                throw "$_ requires a directory"
            }

            $directory = $args[$i]
            $directorySet = $true
            continue
        }

        "--limit" {
            if (++$i -ge $args.Count) {
                throw "--limit requires a number"
            }

            $limit = [int]$args[$i]

            if ($limit -lt 1) {
                throw "--limit must be at least 1"
            }

            continue
        }

        "--context" {
            if (++$i -ge $args.Count) {
                throw "--context requires a number"
            }

            $contextLines = [int]$args[$i]

            if ($contextLines -lt 0) {
                throw "--context must be zero or greater"
            }

            continue
        }

        { $_ -in "-h", "--help" } {
            Show-Usage
            exit 0
        }

        { $_.StartsWith("-") } {
            throw "Unknown option: $_"
        }

        default {
            if ($directorySet) {
                throw "Only one directory may be specified"
            }

            $directory = $_
            $directorySet = $true
        }
    }
}

if ($requestedExtensions.Count -eq 0) {
    $requestedExtensions.Add("py")
}

$extensions = New-Object 'System.Collections.Generic.HashSet[string]' (
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($ext in $requestedExtensions) {
    switch ($ext) {
        { $_ -in "yaml", "yml" } {
            [void]$extensions.Add("yaml")
            [void]$extensions.Add("yml")
        }

        default {
            [void]$extensions.Add($ext)
        }
    }
}

$target = (Resolve-Path -LiteralPath $directory).Path

$repoRoot = & git -C $target rev-parse --show-toplevel 2>$null

if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw "Not inside a Git repository: $target"
}

$repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path

$targetRelative = (
    Get-RelativePath -BasePath $repoRoot -TargetPath $target
).Replace("\", "/")

$gitFiles = @(
    & git -C $repoRoot `
        ls-files `
        --cached `
        --others `
        --exclude-standard `
        -- `
        $targetRelative
)

if ($LASTEXITCODE -ne 0) {
    throw "git ls-files failed"
}

$files = @(
    $gitFiles |
        Where-Object {
            if (-not $_) {
                return $false
            }

            $fileExtension = [System.IO.Path]::GetExtension($_).
                TrimStart(".").
                ToLowerInvariant()

            $extensions.Contains($fileExtension)
        } |
        Sort-Object
)

$totalMatching = $files.Count

if (-not $copyAll) {
    $files = @($files | Select-Object -First $limit)
}

if ($files.Count -eq 0) {
    $extList = ($extensions | Sort-Object) -join ", "
    throw "No matching files ($extList) found under $target"
}

$blob = New-Object System.Text.StringBuilder

foreach ($repoRelativePath in $files) {
    $fullPath = Join-Path $repoRoot $repoRelativePath

    $displayPath = (
        Get-RelativePath -BasePath $target -TargetPath $fullPath
    ).Replace("\", "/")

    $fileExtension = [System.IO.Path]::GetExtension($fullPath).
        TrimStart(".").
        ToLowerInvariant()

    [void]$blob.AppendLine("===== ./$displayPath =====")

    $lines = [System.IO.File]::ReadAllLines($fullPath)

    Append-FileLines `
        -Builder $blob `
        -Lines $lines `
        -UseLineNumbers $lineNumbers `
        -UseCondensed ($condensed -and $fileExtension -eq "py") `
        -Context $contextLines

    [void]$blob.AppendLine()
}

$text = $blob.ToString()

if ($view) {
    [Console]::Write($text)
    exit 0
}

if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    Set-Clipboard -Value $text
}
elseif (Get-Command clip.exe -ErrorAction SilentlyContinue) {
    $text | clip.exe
}
else {
    throw "No clipboard command found. Use --view instead."
}

$count = $files.Count
$extensionSummary = ($extensions | Sort-Object) -join ", "

if (-not $copyAll -and $totalMatching -gt $limit) {
    Write-Host "Copied $count of $totalMatching matching files [$extensionSummary]. Use --all for all files."
}
else {
    Write-Host "Copied $count matching files [$extensionSummary] to clipboard."
}