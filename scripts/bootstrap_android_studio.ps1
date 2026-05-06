param(
  [string]$AndroidSdkPath,
  [switch]$SkipFvmUse
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AndroidDir = Join-Path $ProjectRoot 'android'
$LocalPropertiesPath = Join-Path $AndroidDir 'local.properties'
$FvmConfigPath = Join-Path $ProjectRoot '.fvmrc'

function Resolve-FvmVersion {
  $config = Get-Content $FvmConfigPath -Raw | ConvertFrom-Json
  if (-not $config.flutter) {
    throw 'No Flutter version found in .fvmrc.'
  }

  return $config.flutter
}

function Resolve-FvmCommand {
  $fvm = Get-Command fvm -ErrorAction SilentlyContinue
  if ($fvm) {
    return $fvm.Source
  }

  $fallback = Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin\fvm.bat'
  if (Test-Path $fallback) {
    return $fallback
  }

  throw 'FVM was not found. Install it or add C:\Users\<user>\AppData\Local\Pub\Cache\bin to PATH.'
}

function Resolve-AndroidSdkPath {
  param([string]$PreferredPath)

  $candidates = @(
    $PreferredPath,
    $env:ANDROID_SDK_ROOT,
    $env:ANDROID_HOME,
    (Join-Path $env:LOCALAPPDATA 'Android\sdk')
  ) | Where-Object { $_ -and $_.Trim() -ne '' }

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return (Resolve-Path $candidate).Path
    }
  }

  throw 'Android SDK not found. Pass -AndroidSdkPath or set ANDROID_SDK_ROOT/ANDROID_HOME.'
}

if (-not (Test-Path $FvmConfigPath)) {
  throw ".fvmrc not found at $FvmConfigPath"
}

$fvmCommand = Resolve-FvmCommand

if (-not $SkipFvmUse) {
  try {
    & $fvmCommand use --force | Out-Host
  } catch {
    Write-Warning 'FVM could not create local symlinks on this machine. Falling back to the FVM cache path.'
  }
}

$flutterSdkPath = Join-Path $ProjectRoot '.fvm\flutter_sdk'
if (-not (Test-Path $flutterSdkPath)) {
  $version = Resolve-FvmVersion
  $fallbackFlutterSdkPath = Join-Path $HOME "fvm\versions\$version"

  if (Test-Path $fallbackFlutterSdkPath) {
    $flutterSdkPath = $fallbackFlutterSdkPath
  } else {
    throw "Flutter SDK not found at $flutterSdkPath or $fallbackFlutterSdkPath. Run 'fvm use' first."
  }
}

$resolvedFlutterSdkPath = (Resolve-Path $flutterSdkPath).Path
$resolvedAndroidSdkPath = Resolve-AndroidSdkPath -PreferredPath $AndroidSdkPath

$localProperties = @(
  "sdk.dir=$($resolvedAndroidSdkPath -replace '\\','\\\\')"
  "flutter.sdk=$($resolvedFlutterSdkPath -replace '\\','\\\\')"
)

Set-Content -Path $LocalPropertiesPath -Value $localProperties -Encoding UTF8

Write-Host ''
Write-Host 'Android Studio bootstrap complete.' -ForegroundColor Green
Write-Host "- local.properties updated: $LocalPropertiesPath"
Write-Host "- Android SDK: $resolvedAndroidSdkPath"
Write-Host "- Flutter SDK: $resolvedFlutterSdkPath"
Write-Host ''
Write-Host 'Shared run configs committed in .run/:' -ForegroundColor Cyan
Write-Host '- Flutter Dev'
Write-Host '- Flutter Staging'
Write-Host '- Flutter Pro'
Write-Host ''
Write-Host 'If PowerShell cannot find fvm, add this to your session:' -ForegroundColor Yellow
Write-Host '$env:Path += '';C:\Users\<user>\AppData\Local\Pub\Cache\bin'''
