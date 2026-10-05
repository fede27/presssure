<#
.SYNOPSIS
  Runs the OCR benchmark on the connected phone. See README.md next to it.

.DESCRIPTION
  1. Builds and installs "PressSure dev" (com.fscarel.presssure.debug), a
     separate app: the real one is never installed, uninstalled or touched.
  2. Brings the photos collected by "PressSure dev" into the local corpus.
  3. Copies the whole local corpus into "PressSure dev".
  4. Runs integration_test/ocr_benchmark_test.dart there, without the
     uninstall that `flutter test` does by default.
  5. Brings back ocr_results/ (report per engine) and copies the recordings
     to test/ocr/recordings/, replayed by `flutter test` on the computer.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\ocr_bench\run.ps1
#>
param(
    # Local corpus: photos with a .json label each, in any subfolder.
    [string]$Corpus = "ocr_corpus",
    # adb serial of the phone; the first one connected if empty.
    [string]$Device = ""
)

Set-Location (Resolve-Path "$PSScriptRoot\..\..")

$package = "com.fscarel.presssure.debug"
$remote = "/sdcard/Android/data/$package/files"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) {
    $flutter = Join-Path $env:USERPROFILE "develop\flutter\bin\flutter.bat"
}

if (-not $Device) {
    $line = & $adb devices | Select-String "`tdevice$" | Select-Object -First 1
    if (-not $line) {
        Write-Error "No phone connected (or debugging not authorized)."
        exit 1
    }
    $Device = $line.ToString().Split("`t")[0]
}
Write-Host "Phone: $Device"

# 1. The development app, built now: never a stale build of another app id.
& $flutter build apk --debug
if ($LASTEXITCODE -ne 0) { Write-Error "Build failed."; exit 1 }
# Kept aside: `flutter test` overwrites app-debug.apk with the test build.
$devApk = "build\presssure-dev.apk"
Copy-Item build\app\outputs\flutter-apk\app-debug.apk $devApk -Force
& $adb -s $Device install -r $devApk | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Could not install PressSure dev."; exit 1 }

# 2. Photos labelled in the app on the phone join the local corpus.
New-Item -ItemType Directory -Force $Corpus | Out-Null
$hasApp = & $adb -s $Device shell "[ -d $remote/ocr_corpus/app ] && echo yes"
if ($hasApp -eq "yes") {
    & $adb -s $Device pull "$remote/ocr_corpus/app" $Corpus | Out-Null
    Write-Host "Photos from the app copied to $Corpus\app"
}

# 3. The local corpus replaces the one in the app's private files: files
#    pushed by adb are not readable by the app, run-as copies them as the app.
$tmp = "/data/local/tmp/presssure_corpus"
& $adb -s $Device shell "rm -rf $tmp" | Out-Null
& $adb -s $Device push $Corpus $tmp | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Could not copy the corpus."; exit 1 }
& $adb -s $Device shell "run-as $package sh -c 'mkdir -p files && rm -rf files/ocr_corpus && cp -r $tmp files/ocr_corpus'"
if ($LASTEXITCODE -ne 0) { Write-Error "Could not copy the corpus into the app."; exit 1 }
& $adb -s $Device shell "rm -rf $tmp $remote/ocr_results" | Out-Null
$count = (Get-ChildItem $Corpus -Recurse -Filter *.json).Count
Write-Host "Corpus in the app: $count labelled photos"

# 4. The benchmark, in the development app. --no-uninstall: by default
#    flutter uninstalls the app after integration tests, which would also
#    delete the photos collected in it.
& $flutter test integration_test/ocr_benchmark_test.dart -d $Device --no-uninstall
$testExit = $LASTEXITCODE

# The test build only runs the benchmark (from the launcher it waits on the
# Flutter logo): the app goes back in its place, data kept.
& $adb -s $Device install -r $devApk | Out-Null

# 5. Reports and recordings back on the computer.
if (Test-Path ocr_results) { Remove-Item ocr_results -Recurse -Force }
& $adb -s $Device pull "$remote/ocr_results" . | Out-Null
if (-not (Test-Path ocr_results)) { Write-Error "No results on the phone."; exit 1 }
foreach ($engine in Get-ChildItem ocr_results -Directory) {
    # Kept apart from the computer runs (tool\ocr_train\replay.dart).
    $target = "test\ocr\recordings\$($engine.Name)_phone"
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
    Copy-Item "$($engine.FullName)\recordings" $target -Recurse
    Write-Host "Report: ocr_results\$($engine.Name)\report.md"
}
Write-Host "Recordings copied to test\ocr\recordings: 'flutter test' replays them."
exit $testExit
