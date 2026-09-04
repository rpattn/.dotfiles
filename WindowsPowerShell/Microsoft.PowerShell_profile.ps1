function blobcat { & "$HOME\dev\bin\blobcat.ps1" @args }
function wakepc { & "$HOME\dev\bin\wakepc.ps1"}

Set-Alias c Clear-Host
Set-Alias c Clear-Host
Set-Alias which Get-Command
function ll { Get-ChildItem -Force @args }
function grep { Select-String @args }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git log --oneline --graph --decorate -20 @args }
function root { $r = git rev-parse --show-toplevel 2>$null; if ($LASTEXITCODE -eq 0) { Set-Location $r } }
function mkcd { param([string]$Path) New-Item -ItemType Directory -Force -Path $Path | Out-Null; Set-Location $Path }

fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
