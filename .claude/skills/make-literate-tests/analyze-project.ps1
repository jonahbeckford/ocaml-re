$ErrorActionPreference = 'Stop'

$outDir = ".make-literate-tests"
$outFile = Join-Path $outDir "analysis.txt"

if (-not (Test-Path -Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

# Create a .gitignore file to ignore the output directory
$gitignorePath = Join-Path $outDir ".gitignore"
if (-not (Test-Path -Path $gitignorePath)) {
    Set-Content -Path $gitignorePath -Value "*" -Encoding UTF8
}

# Create/empty the file with UTF-8 (no BOM) encoding
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path $outDir).Path + "\analysis.txt", "", $utf8NoBom)

function Write-Utf8 {
    param([string]$Path, [string[]]$Lines)
    $enc = New-Object System.Text.UTF8Encoding($false)
    $lf = [char]10
    [System.IO.File]::AppendAllText($Path, (($Lines -join $lf) + $lf), $enc)
}

$absOut = (Resolve-Path $outFile).Path

Write-Utf8 -Path $absOut -Lines @("=== dune-project ===")
Write-Utf8 -Path $absOut -Lines (Get-Content dune-project)

Get-ChildItem -Recurse -Filter "dune" | ForEach-Object {
    $rel = Resolve-Path -Relative $_.FullName
    Write-Utf8 -Path $absOut -Lines @("", "=== $rel ===")
    Write-Utf8 -Path $absOut -Lines (Get-Content $_.FullName)
}

# 1. Find directories containing .ml files with "let%expect_test"
$expectDirs = Get-ChildItem -Recurse -Filter "*.ml" |
    Where-Object { Select-String -Pattern "let%expect_test" -Path $_.FullName -Quiet } |
    ForEach-Object { $_.DirectoryName } |
    Sort-Object -Unique

# 2. Recursively collect _all_ .ml files in those directories.
# There may be test support files that don't have "let%expect_test",
# but we expect them to co-reside in the same directories as the expect tests.
$mlFiles = @()
foreach ($d in $expectDirs) {
    $mlFiles += Get-ChildItem -Path $d -Recurse -Filter "*.ml" -File
}
$mlFiles = $mlFiles | Sort-Object FullName -Unique

foreach ($f in $mlFiles) {
    $rel = Resolve-Path -Relative $f.FullName
    Write-Utf8 -Path $absOut -Lines @("", "=== $rel ===")
    Write-Utf8 -Path $absOut -Lines (Get-Content $f.FullName)
}

# get full path to $absOut, and write summary
$absOut = (Resolve-Path $absOut).Path
Write-Host "Analysis complete. Output written to ``$absOut``."
Write-Host "Please provide the contents back to the agent before proceeding."
