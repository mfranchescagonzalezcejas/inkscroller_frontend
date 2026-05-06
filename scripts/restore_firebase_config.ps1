param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "staging", "pro", "all")]
    [string]$Flavor,

    [switch]$AndroidOnly,
    [switch]$IosOnly
)

$ErrorActionPreference = "Stop"

if ($AndroidOnly -and $IosOnly) {
    throw "Use either -AndroidOnly or -IosOnly, not both."
}

$flavorToken = $Flavor.ToUpperInvariant()
$restoreAndroid = -not $IosOnly
$restoreIos = -not $AndroidOnly
$flavors = if ($Flavor -eq "all") { @("dev", "staging", "pro") } else { @($Flavor) }

function Restore-Base64File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentVariable,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $value = [Environment]::GetEnvironmentVariable($EnvironmentVariable)

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Missing required environment variable: $EnvironmentVariable"
    }

    $parent = Split-Path -Parent $OutputPath

    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }

    [IO.File]::WriteAllBytes($OutputPath, [Convert]::FromBase64String($value))
    "Restored $OutputPath from $EnvironmentVariable"
}

foreach ($currentFlavor in $flavors) {
    $flavorToken = $currentFlavor.ToUpperInvariant()

    if ($restoreAndroid) {
        Restore-Base64File `
            -EnvironmentVariable "GOOGLE_SERVICES_${flavorToken}_BASE64" `
            -OutputPath "android/app/src/$currentFlavor/google-services.json"
    }

    if ($restoreIos) {
        Restore-Base64File `
            -EnvironmentVariable "GOOGLE_SERVICE_INFO_IOS_${flavorToken}_BASE64" `
            -OutputPath "ios/config/$currentFlavor/GoogleService-Info.plist"
    }
}
