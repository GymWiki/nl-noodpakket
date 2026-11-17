<#
.SYNOPSIS
  Maakt de ruwe Android-screenshots voor de Play Store (Windows, PowerShell 5.1 of nieuwer).

.DESCRIPTION
  1. Zoekt adb, emulator en avdmanager (ook als adb niet in de PATH staat).
  2. Maakt een AVD van 1080x1920 (Pixel 2-profiel) als die er nog niet is, of controleert hem.
  3. Start de emulator, wacht tot hij klaar is, controleert de schermgrootte.
  4. Zet de demo-modus aan (klok 12:00, batterij 100, wifi vol, geen meldingen) en animaties uit.
  5. Draait de integratietests (flutter drive); de ruwe PNG's komen in store/raw/android/.
  6. Zet de demo-modus en animaties altijd weer terug, ook bij een fout.

  Gebruik (vanuit de projectmap):
    powershell -ExecutionPolicy Bypass -File tool/screenshots/android.ps1
    powershell -ExecutionPolicy Bypass -File tool/screenshots/android.ps1 -AvdName MijnAvd -NoStartEmulator

  Staat adb niet in de PATH? Zet ANDROID_HOME (of ANDROID_SDK_ROOT) op de SDK-map, bijvoorbeeld
    $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
  Het script zoekt ook zelf in %LOCALAPPDATA%\Android\Sdk.
#>
param(
  [string]$AvdName = 'NL_Store_1080x1920',
  [string]$OutDir = 'store/raw/android',
  [switch]$NoStartEmulator,
  [switch]$KeepEmulatorRunning
)

$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..\..'))

function Find-Sdk {
  foreach ($v in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk'))) {
    if ($v -and (Test-Path (Join-Path $v 'platform-tools'))) { return $v }
  }
  return $null
}

$sdk = Find-Sdk
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb -and $sdk) { $adb = Join-Path $sdk 'platform-tools\adb.exe' }
if (-not $adb -or -not (Test-Path $adb)) {
  throw "adb niet gevonden. Zet ANDROID_HOME op je Android SDK-map (meestal $env:LOCALAPPDATA\Android\Sdk) of voeg platform-tools toe aan de PATH."
}
$emulator = if ($sdk) { Join-Path $sdk 'emulator\emulator.exe' } else { (Get-Command emulator -ErrorAction SilentlyContinue).Source }
if (-not $emulator -or -not (Test-Path $emulator)) { throw 'emulator.exe niet gevonden in de Android SDK (installeer "Android Emulator" via de SDK Manager).' }
$avdmanager = if ($sdk) { Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat' } else { $null }

Write-Host "adb: $adb"
Write-Host "emulator: $emulator"

function Adb { & $adb @args }

# --- 1. AVD controleren of maken ---------------------------------------------------------------
$avds = & $emulator -list-avds
if ($avds -notcontains $AvdName) {
  if (-not $avdmanager -or -not (Test-Path $avdmanager)) {
    throw "AVD '$AvdName' bestaat niet en avdmanager ontbreekt. Installeer 'Android SDK Command-line Tools' via de SDK Manager, of maak in Android Studio een AVD met een 1080x1920-scherm (Pixel 2) en geef de naam mee met -AvdName."
  }
  $images = Get-ChildItem (Join-Path $sdk 'system-images') -Directory | ForEach-Object {
    Get-ChildItem $_.FullName -Directory | ForEach-Object {
      Get-ChildItem $_.FullName -Directory | Where-Object { $_.Name -eq 'x86_64' } | ForEach-Object { $_.FullName }
    }
  }
  if (-not $images) { throw "Geen x86_64-systeemimage gevonden. Installeer er een via de SDK Manager (bijv. 'Google Play Intel x86_64 Atom System Image')." }
  $img = ($images | Where-Object { $_ -match 'google_apis' } | Select-Object -First 1)
  if (-not $img) { $img = $images | Select-Object -First 1 }
  $parts = $img.Substring((Join-Path $sdk 'system-images').Length + 1).Split('\')
  $package = "system-images;$($parts[0]);$($parts[1]);$($parts[2])"
  Write-Host "AVD '$AvdName' maken met $package (Pixel 2, 1080x1920)"
  'no' | & $avdmanager create avd -n $AvdName -k $package -d pixel_2 --force
  if ($LASTEXITCODE -ne 0) { throw 'avdmanager create avd is mislukt.' }
  # Een nieuwe AVD heeft standaard geen GPU en 2 GB geheugen; Android 16 start dan extreem traag of blijft 'offline'.
  $newCfg = Join-Path $env:USERPROFILE ('.android' + [IO.Path]::DirectorySeparatorChar + 'avd' + [IO.Path]::DirectorySeparatorChar + $AvdName + '.avd' + [IO.Path]::DirectorySeparatorChar + 'config.ini')
  if (Test-Path $newCfg) {
    (Get-Content $newCfg) -replace '^hw\.gpu\.enabled\s*=.*', 'hw.gpu.enabled = yes' -replace '^hw\.ramSize\s*=.*', 'hw.ramSize = 3072' | Set-Content $newCfg
  }
}
$avdConfig = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd\config.ini"
if (Test-Path $avdConfig) {
  $cfg = Get-Content $avdConfig -Raw
  if ($cfg -notmatch 'hw\.lcd\.width\s*=\s*1080' -or $cfg -notmatch 'hw\.lcd\.height\s*=\s*1920') {
    throw "AVD '$AvdName' is niet 1080x1920 (zie $avdConfig). Verwijder hem of kies een andere -AvdName."
  }
}

# --- 2. Emulator starten ------------------------------------------------------------------------
$started = $false
function Get-Serial {
  $line = (Adb devices) | Select-String -Pattern '^(emulator-\d+)\s+device' | Select-Object -First 1
  if ($line) { return $line.Matches[0].Groups[1].Value }
  return $null
}
$serial = Get-Serial
if (-not $serial -and -not $NoStartEmulator) {
  Write-Host "Emulator '$AvdName' starten..."
  Start-Process -FilePath $emulator -ArgumentList @('-avd', $AvdName, '-no-snapshot-save', '-no-audio', '-gpu', 'auto') | Out-Null
  $started = $true
  # De eerste start van een nieuwe AVD kan lang duren (de status blijft dan een tijd 'offline'): maximaal 20 minuten.
  $deadline = (Get-Date).AddMinutes(20)
  while (-not $serial -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    $serial = Get-Serial
    if (-not $serial -and ((Adb devices) -match 'emulator-\d+\s+offline')) { Write-Host '  emulator start nog op (offline)...' }
  }
  if (-not $serial) { throw 'De emulator kwam niet online (na 20 minuten). Start hem handmatig in Android Studio (Device Manager) en draai dit script opnieuw met -NoStartEmulator.' }
  while ((Get-Date) -lt $deadline) {
    if ((Adb -s $serial shell getprop sys.boot_completed 2>$null).Trim() -eq '1') { break }
    Start-Sleep -Seconds 3
  }
}
if (-not $serial) { throw 'Geen emulator verbonden. Start er een, of laat dit script hem starten (zonder -NoStartEmulator).' }
Write-Host "Apparaat: $serial"

$size = (Adb -s $serial shell wm size) -join ' '
if ($size -notmatch '1080x1920') {
  Write-Warning "Schermgrootte is '$size', niet 1080x1920. De Play-set vraagt 1080x1920; ik zet de grootte tijdelijk met 'wm size'."
  Adb -s $serial shell wm size 1080x1920 | Out-Null
  $resetSize = $true
}

# --- 3. Demo-modus aan --------------------------------------------------------------------------
function Demo($cmd, $extra) {
  Adb -s $serial shell am broadcast -a com.android.systemui.demo -e command $cmd @extra | Out-Null
}
$animBackup = @{}
try {
  foreach ($k in 'window_animation_scale', 'transition_animation_scale', 'animator_duration_scale') {
    $animBackup[$k] = (Adb -s $serial shell settings get global $k).Trim()
    Adb -s $serial shell settings put global $k 0 | Out-Null
  }
  Adb -s $serial shell settings put system font_scale 1.0 | Out-Null
  Adb -s $serial shell cmd uimode night no | Out-Null
  Adb -s $serial shell settings put global sysui_demo_allowed 1 | Out-Null
  Demo 'enter' @()
  Demo 'clock' @('-e', 'hhmm', '1200')
  Demo 'battery' @('-e', 'level', '100', '-e', 'plugged', 'false')
  Demo 'network' @('-e', 'wifi', 'show', '-e', 'level', '4')
  Demo 'network' @('-e', 'mobile', 'hide')
  Demo 'notifications' @('-e', 'visible', 'false')

  # --- 4. Tests draaien -------------------------------------------------------------------------
  New-Item -ItemType Directory -Force $OutDir | Out-Null
  Get-ChildItem $OutDir -Filter '*.png' -ErrorAction SilentlyContinue | Remove-Item -Force
  $env:STORE_RAW_DIR = $OutDir
  flutter drive --driver=test_driver/integration_test.dart --target=integration_test/store_screenshots_test.dart -d $serial
  if ($LASTEXITCODE -ne 0) { throw 'flutter drive is mislukt (zie de uitvoer hierboven).' }
}
finally {
  # --- 5. Altijd terugzetten ----------------------------------------------------------------------
  try {
    Demo 'exit' @()
    Adb -s $serial shell settings put global sysui_demo_allowed 0 | Out-Null
    foreach ($k in $animBackup.Keys) {
      $v = $animBackup[$k]; if (-not $v -or $v -eq 'null') { $v = '1' }
      Adb -s $serial shell settings put global $k $v | Out-Null
    }
    if ($resetSize) { Adb -s $serial shell wm size reset | Out-Null }
  } catch { Write-Warning "Terugzetten van de demo-modus is niet gelukt: $_" }
  if ($started -and -not $KeepEmulatorRunning) { Adb -s $serial emu kill | Out-Null }
}

Write-Host ''
Write-Host "Ruwe screenshots in $OutDir :"
Get-ChildItem $OutDir -Filter '*.png' | ForEach-Object { Write-Host ("  {0}  {1:N0} bytes" -f $_.Name, $_.Length) }
