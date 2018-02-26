Param(
    [Parameter(Mandatory=$true)]
    [string]$version,
    [string]$sha,
    [switch]$pre
)
$ErrorActionPreference = "Stop"

$nativeWindowsUrl = "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-windows.zip"
$nativeOsxUrl     = "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-macosx.zip"
$nativeLinuxUrl   = "https://github.com/ariya/phantomjs/releases/download/2.1.3/phantomjs"

$versionSuffix = ""
if ($pre.IsPresent) {
  if ([string]::IsNullOrWhiteSpace($sha)) {
    Write-Error "Pre-Release package requested but no SHA provided"
    $host.SetShouldExit(1)
    exit
  }
  $versionSuffix = "-alpha." + $sha.Substring(0,7)
}

$packageDirectory = Join-Path (Split-Path $PSScriptRoot) "artifacts\package"
$winx86Directory = Join-Path $packageDirectory "runtimes\win7-x86\native"
$winx64Directory = Join-Path $packageDirectory "runtimes\win7-x64\native"
$linuxDirectory = Join-Path $packageDirectory "runtimes\linux-x64\native"
$osxDirectory = Join-Path $packageDirectory "runtimes\osx\native"
$monoDirectory = Join-Path $packageDirectory "mono"

Write-Output "Creating package folders..."
if ( -Not (Test-Path $winx86Directory) ) {
    mkdir -fo $winx86Directory > $null
}

if ( -Not (Test-Path $winx64Directory) ) {
    mkdir -fo $winx64Directory > $null
}

if ( -Not (Test-Path $osxDirectory) ) {
    mkdir -fo $osxDirectory > $null
}

if ( -Not (Test-Path $linuxDirectory) ) {
    mkdir -fo $linuxDirectory > $null
}

if ( -Not (Test-Path $monoDirectory) ) {
    mkdir -fo $monoDirectory > $null
}

try {
  Write-Output "Native binaries downloading..."
  Write-Verbose "Downloading $nativeWindowsUrl..."
  Invoke-WebRequest $nativeWindowsUrl -OutFile (Join-Path $winx86Directory "phantomjs.exe")
  Write-Verbose "Downloading $nativeLinuxUrl..."
  Invoke-WebRequest $nativeLinuxUrl -OutFile (Join-Path $linuxDirectory "phantomjs")
  Write-Verbose "Downloading $nativeOsxUrl..."
  Invoke-WebRequest $nativeOsxUrl -OutFile (Join-Path $osxDirectory "phantomjs" )
  Write-Information "Native binaries downloaded"
} catch {
  Write-Error "Failed to download native binaries: $($_.Exception.Message)"
  $host.SetShouldExit(2)
  exit;
}

Write-Output "Copying items to package..."
Copy-Item (Join-Path $winx86Directory "phantomjs.exe") -Destination $winx64Directory
Copy-Item (Join-Path (Split-Path $PSScriptRoot) src\FutureDigital.PhantomJS.NativeBinaries.dll.config) -Destination $monoDirectory
Copy-Item (Join-Path (Split-Path $PSScriptRoot) src\FutureDigital.PhantomJS.NativeBinaries.nuspec) -Destination $packageDirectory

try {
  Write-Output "Creating package..."
  nuget Pack (Join-Path $packageDirectory "FutureDigital.PhantomJS.NativeBinaries.nuspec") -Version $version$versionSuffix -NoPackageAnalysis
  Move-Item "FutureDigital.PhantomJS.NativeBinaries.$version$versionSuffix.nupkg" (Split-Path $packageDirectory)
} catch {
  Write-Error "Failed to create nuget package $($_.Exception.Message)"
  $host.SetShouldExit(3)
}

Write-Output "Build completed..."