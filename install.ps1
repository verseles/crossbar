# Crossbar installer (Windows) - https://github.com/verseles/crossbar
# Usage: irm https://install.cat/verseles/crossbar?format=ps1 | iex

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Repo = "verseles/crossbar"
$InstallDir = Join-Path $env:LOCALAPPDATA "Crossbar"
$BinPath = Join-Path $InstallDir "crossbar.exe"

function Write-Info([string]$Message) {
  Write-Host ":: $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
  Write-Host ":: $Message" -ForegroundColor Green
}

function Get-Arch {
  $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
  switch ($arch) {
    "X64" { return "x64" }
    "Arm64" { return "arm64" }
    default { throw "Unsupported Windows architecture: $arch" }
  }
}

function Add-UserPath([string]$PathEntry) {
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($current) {
    $parts = $current.Split(";") | Where-Object { $_ -and $_.Trim() -ne "" }
  }

  if ($parts -contains $PathEntry) {
    return $false
  }

  $newPath = if ($parts.Count -eq 0) { $PathEntry } else { ($parts + $PathEntry) -join ";" }
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  return $true
}

Write-Info "Crossbar Installer (Windows)"

$arch = Get-Arch
Write-Info "Detected: windows ($arch)"

$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "crossbar-install" }
$version = $release.tag_name
if (-not $version) {
  throw "Could not determine latest version."
}

$assetName = "crossbar-windows-$arch.zip"
$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
if (-not $asset) {
  $available = ($release.assets | Where-Object { $_.name -like "crossbar-*" } | ForEach-Object { $_.name }) -join ", "
  throw "Asset '$assetName' not found in release $version. Available: $available"
}

$tempRoot = Join-Path $env:TEMP ("crossbar-install-" + [Guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $tempRoot $assetName

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  Write-Info "Downloading $assetName..."
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

  if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
  }
  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

  Write-Info "Extracting..."
  Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
  # Remove Zone.Identifier ADS so SmartScreen does not warn on first run.
  Get-ChildItem -Path $InstallDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

  if (-not (Test-Path $BinPath)) {
    throw "Installation failed: '$BinPath' not found after extraction."
  }

  $pathUpdated = Add-UserPath -PathEntry $InstallDir
  if ($pathUpdated) {
    Write-Info "Added '$InstallDir' to user PATH. Restart terminal to apply."
  }

  Write-Ok "Crossbar $version installed successfully."
  Write-Host ""
  Write-Host "Run 'crossbar --help' in a new terminal."
  Write-Host "GUI: execute '$BinPath' or create a shortcut for it."
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}
