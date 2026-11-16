# check.ps1: build, test and run the cases that run natively on Windows, and record what
# happened. The Windows counterpart of check.sh.
#
# Run from a "Developer PowerShell for Visual Studio" (so cl, nmake and dumpbin are on the
# PATH), with Swift 6.2 or later installed, in this folder:
#     .\check.ps1
# Or name the cases you want:  .\check.ps1 5.6 5.10
# Results go to check\<case>.txt, with a summary in check\SUMMARY.txt.
#
# 5.4 and 5.11 use POSIX networking and processes (select, fork, pipes), so they run in WSL
# instead: from a WSL shell in this folder, ./check.sh 5.4 5.11

param([string[]]$Cases = @("5.2","5.3","5.5","5.6","5.7","5.8","5.9","5.10"))

# Keep going after a step's error: failures are part of the cases, and GitHub Actions starts
# PowerShell with "stop".
$ErrorActionPreference = "Continue"

$Root = $PSScriptRoot
$Out = Join-Path $Root "check"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$Summary = Join-Path $Out "SUMMARY.txt"
$Scratch = ".build-windows"   # keeps Windows build output apart from the Mac's and Linux's

# Step LABEL SECONDS COMMAND: runs one cmd.exe command line with a time limit, and records its
# output and exit status. "stopped" means it ran past the limit. On Windows a crash shows up
# as an exit status such as -1073741819 (0xC0000005, an access violation).
function Step([string]$Label, [int]$Seconds, [string]$Command) {
    Add-Content $Log "`n---- $Label`n> $Command"
    $so = [IO.Path]::GetTempFileName(); $se = [IO.Path]::GetTempFileName()
    # cmd /s /c "..." strips just the outer quotes, so quotes inside the command survive.
    $p = Start-Process -FilePath cmd.exe -ArgumentList "/d /s /c `"$Command`"" -NoNewWindow -PassThru `
         -RedirectStandardOutput $so -RedirectStandardError $se
    $null = $p.Handle   # read now, or ExitCode can come back empty once the process ends
    if ($p.WaitForExit($Seconds * 1000)) { $status = $p.ExitCode }
    else { & taskkill /T /F /PID $p.Id 2>&1 | Out-Null; $p.WaitForExit(); $status = "stopped" }
    Get-Content $so, $se | Add-Content $Log
    # A helper the program started (a crash reporter, say) can hold the files open a little
    # longer; give it a few seconds, then leave the temporary files for Windows to clean up.
    foreach ($f in $so, $se) {
        for ($i = 0; $i -lt 10 -and (Test-Path $f); $i++) {
            Remove-Item $f -ErrorAction SilentlyContinue
            if (Test-Path $f) { Start-Sleep -Milliseconds 500 }
        }
    }
    Add-Content $Log "exit: $status"
    $line = "  {0,-58} exit {1}" -f $Label, $status
    Write-Host $line; Add-Content $Summary $line
}
function SB([string]$Extra = "")  { "swift build --scratch-path $Scratch $Extra" }
function SR([string]$Product)     { "swift run --scratch-path $Scratch --skip-build $Product" }
function ST([string]$Filter = "") { if ($Filter) { "swift test --scratch-path $Scratch --filter $Filter" } else { "swift test --scratch-path $Scratch" } }

Set-Content $Summary "check.ps1 $(Get-Date)"
Add-Content $Summary ((& swift --version 2>&1 | Select-Object -First 1) -join "")
Add-Content $Summary ((& cl 2>&1 | Select-Object -First 1) -join "")

foreach ($c in $Cases) {
    $dir = Get-ChildItem -Path $Root -Directory -Filter "$c *" | Select-Object -First 1
    if (-not $dir) { Add-Content $Summary "${c}: folder not found"; continue }
    $Log = Join-Path $Out "$c.txt"; Set-Content $Log ""
    $header = "== $($dir.Name)"; Write-Host $header; Add-Content $Summary $header
    Push-Location $dir.FullName
    switch ($c) {
      "5.2" {
        Step "build" 900 (SB)
        Step "run FixedSizeCache" 60 (SR "FixedSizeCache")
        Step "run FixedSizeCacheFixed" 60 (SR "FixedSizeCacheFixed")
        Step "test FixedSizeCacheTests (2 failures expected)" 600 (ST "FixedSizeCacheTests")
        Step "test FixedSizeCacheFixedTests" 600 (ST "FixedSizeCacheFixedTests")
      }
      "5.3" {
        # No Thread Sanitizer on Windows.
        Step "build" 900 (SB)
        1..3 | ForEach-Object { Step "run SessionRegistry #$_ (crash expected)" 60 (SR "SessionRegistry") }
        Step "run SessionRegistryWithLock, delays on" 60 ("set SESSIONREGISTRY_ADD_DELAY=1&& " + (SR "SessionRegistryWithLock"))
        Step "run SessionRegistryWithActor, delays on" 60 ("set SESSIONREGISTRY_ADD_DELAY=1&& " + (SR "SessionRegistryWithActor"))
        foreach ($t in "SessionRegistryTests","SessionRegistryWithNaiveFix2Tests","SessionRegistryWithLockTests","SessionRegistryWithActorTests") {
            Step "test $t" 600 (ST $t)
        }
        Step "test SessionRegistryWithRaceWideningTests, delays on" 600 ("set SESSIONREGISTRY_ADD_DELAY=1&& " + (ST "SessionRegistryWithRaceWideningTests"))
        Step "Swift 6 build of the original (refusal expected)" 900 "swift build --scratch-path $Scratch-swift6 --product SessionRegistry -Xswiftc -swift-version -Xswiftc 6"
      }
      "5.5" {
        Step "build" 900 (SB)
        foreach ($t in "Baseline","BuggyRefactor","Change1","Change2","Change3","Change4") { Step "run $t" 60 (SR $t) }
        Step "test (BuggyRefactorTests and DiagnosticTests failures expected)" 900 (ST)
      }
      "5.6" {
        $InputFile = Join-Path $Out "5.6-input.txt"
        Set-Content $InputFile "60`n55`n7`n8`n3`n2"
        foreach ($d in "Baseline","LinkerErrorFixed","RuntimeCrashSilent","RuntimeCrashLoud","RuntimeCrashFixed") {
            Step "nmake $d" 180 "cd $d && nmake /nologo /f Makefile.win clean all"
            Step "run $d" 30 "type `"$InputFile`" | $d\build\ReadinessScore.exe"
        }
        $stale = Join-Path $Out "5.6-stale"
        if (Test-Path $stale) { Remove-Item -Recurse -Force $stale }
        New-Item -ItemType Directory -Path $stale | Out-Null
        Copy-Item LinkerError\Makefile.win, LinkerError\*.cpp, LinkerError\*.hpp $stale
        Step "nmake stale, then nmake (LNK2019 expected)" 180 "cd /d `"$stale`" && nmake /nologo /f Makefile.win stale && dumpbin /nologo /symbols readiness.obj | findstr compute_readiness && nmake /nologo /f Makefile.win"
        foreach ($d in "Baseline","LinkerErrorFixed","RuntimeCrashSilent","RuntimeCrashLoud","RuntimeCrashFixed") {
            Push-Location $d; & nmake /nologo /f Makefile.win clean 2>&1 | Out-Null; Pop-Location
        }
      }
      "5.7" {
        # The NSHashTable candidates need the Objective-C runtime; the package leaves them out here.
        Step "build" 900 (SB)
        foreach ($t in "Baseline","Instrumentation","SubscriberFixed") { Step "run $t" 60 (SR $t) }
        Step "test DiagnosticTests.DiagnosticTests (failure expected)" 600 (ST "DiagnosticTests\.DiagnosticTests")
        foreach ($t in "BasicTests","SubscriberFixedTests") { Step "test $t" 600 (ST $t) }
      }
      "5.8" {
        # No snapshot signal on Windows; the programs say so and run without snapshots.
        Step "build" 900 (SB)
        Step "run DedupeFixed" 180 (SR "DedupeFixed")
        Step "run Baseline (50,000 records; slow is expected)" 600 (SR "Baseline")
      }
      "5.9" {
        Step "build" 900 (SB)
        foreach ($t in "ClientPrevious","ClientMock","ClientCurrent","IntegrityCheck","ClientFixed") { Step "run $t" 60 (SR $t) }
        Step "test (DiagnosticTests known issues expected)" 900 (ST)
        & git checkout -q -- Evidence Fixtures 2>&1 | Out-Null
      }
      "5.10" {
        Step "nmake Baseline" 180 "cd Baseline && nmake /nologo /f Makefile.win clean all"
        Step "run Baseline" 30 "Baseline\build\AudioFilters.exe"
        foreach ($o in "safe","unsafe") {
            Step "nmake WithChorus ORDER=$o" 180 "cd WithChorus && nmake /nologo /f Makefile.win clean all ORDER=$o"
            Step "run WithChorus $o (unsafe crash expected)" 30 "WithChorus\build\$o\AudioFilters.exe"
            Step "nmake WithChorusFixed ORDER=$o" 180 "cd WithChorusFixed && nmake /nologo /f Makefile.win clean all ORDER=$o"
            Step "run WithChorusFixed $o" 30 "WithChorusFixed\build\$o\AudioFilters.exe"
        }
        Step "nmake WithChorus ORDER=unsafe with AddressSanitizer" 180 "cd WithChorus && nmake /nologo /f Makefile.win clean all ORDER=unsafe `"CXXFLAGS=/nologo /std:c++20 /EHsc /Zi /Od /fsanitize=address`" LINKFLAGS=/fsanitize=address"
        Step "run with check_initialization_order=1" 60 "set ASAN_OPTIONS=check_initialization_order=1&& WithChorus\build\unsafe\AudioFilters.exe"
        foreach ($d in "Baseline","WithChorus","WithChorusFixed") {
            Push-Location $d; & nmake /nologo /f Makefile.win clean 2>&1 | Out-Null; Pop-Location
        }
      }
      default { Add-Content $Summary "  (no native Windows steps for $c; see the note at the top)" }
    }
    Pop-Location
}
Write-Host "`nDetails are in $Out."
