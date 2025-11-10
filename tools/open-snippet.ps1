<#
Simple helper to list files in the snippets folder and copy a selected file to clipboard.
Usage:
  .\tools\open-snippet.ps1           # interactive selection, copies to clipboard
  .\tools\open-snippet.ps1 -Open    # also opens the file in notepad after copying

This script is intentionally minimal and uses PowerShell 5.1 builtins (Set-Clipboard).
#>
param(
    [switch]$Open
)

$base = Join-Path $PSScriptRoot "..\snippets"
if (-not (Test-Path $base)) {
    Write-Error "snippets folder not found: $base"
    exit 1
}

$files = Get-ChildItem -Path $base -Recurse -File | Where-Object { $_.Extension -in '.md','.yaml','.yml' } | Sort-Object DirectoryName, Name
if ($files.Count -eq 0) {
    Write-Output "No snippet files found under $base"
    exit 0
}

# Present numbered list
for ($i = 0; $i -lt $files.Count; $i++) {
    $n = $i + 1
    $f = $files[$i]
    Write-Output ("[{0}] {1}\{2}" -f $n, (Split-Path $f.DirectoryName -Leaf), $f.Name)
}

$choice = Read-Host "Enter number to copy to clipboard (or blank to cancel)"
if ([string]::IsNullOrWhiteSpace($choice)) { Write-Output 'Canceled'; exit 0 }
if (-not ($choice -as [int])) { Write-Error 'Invalid selection'; exit 2 }
$idx = [int]$choice - 1
if ($idx -lt 0 -or $idx -ge $files.Count) { Write-Error 'Selection out of range'; exit 3 }
$sel = $files[$idx]
$content = Get-Content -Raw -Path $sel.FullName
Set-Clipboard -Value $content
Write-Output "Copied $($sel.Name) to clipboard"
if ($Open) {
    Start-Process notepad.exe -ArgumentList $sel.FullName
}
