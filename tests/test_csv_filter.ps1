$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$testDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("csv-filter-tests-" + [guid]::NewGuid().ToString("N"))
$executablePath = Join-Path $testDirectory "CSV_FIlter.exe"
$sourcePath = Join-Path $repoRoot "src\CSV_FIlter.c"

New-Item -ItemType Directory -Path $testDirectory | Out-Null

try {
    $compilerArguments = @(
        "-std=gnu23",
        "-g",
        "-Wall",
        "-Wextra",
        $sourcePath,
        "-lm",
        "-o",
        $executablePath
    )

    & clang @compilerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Clang failed to build CSV_FIlter.c."
    }

    function Invoke-FilterTest {
        param (
            [string] $Name,
            [string] $InputText,
            [string] $MinimumAge,
            [string[]] $ExpectedText = @(),
            [string[]] $UnexpectedText = @()
        )

        $inputPath = Join-Path $testDirectory ($Name + ".csv")
        [System.IO.File]::WriteAllText($inputPath, $InputText, [System.Text.UTF8Encoding]::new($false))

        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $capturedLines = @(& $executablePath $MinimumAge $inputPath 2>&1 | ForEach-Object { $_.ToString() })
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        $capturedText = $capturedLines -join "`n"

        if ($exitCode -ne 0) {
            throw "$Name failed: expected exit code 0, got $exitCode. Output: $capturedText"
        }

        foreach ($expected in $ExpectedText) {
            if (-not $capturedText.Contains($expected)) {
                throw "$Name failed: expected output to contain '$expected'. Actual output: $capturedText"
            }
        }

        foreach ($unexpected in $UnexpectedText) {
            if ($capturedText.Contains($unexpected)) {
                throw "$Name failed: output should not contain '$unexpected'. Actual output: $capturedText"
            }
        }

        Write-Output "PASS: $Name"
    }

    Invoke-FilterTest -Name "one-character-no-newline" -InputText "A" -MinimumAge "0" -ExpectedText @("Line 1: Age missing.")
    Invoke-FilterTest -Name "missing-age-continues" -InputText "Dana`nBob,18`n" -MinimumAge "18" -ExpectedText @("Line 1: Age missing.", "Bob, 18") -UnexpectedText @("Age value is not a number.")
    Invoke-FilterTest -Name "nonnumeric-age" -InputText "Dana,abc`n" -MinimumAge "18" -ExpectedText @("Line 1: Age value is not a number.")
    Invoke-FilterTest -Name "blank-line" -InputText "`nBob,18`n" -MinimumAge "18" -ExpectedText @("Line 1: Whole line missing.", "Bob, 18")
    Invoke-FilterTest -Name "minimum-age-filter" -InputText "Alice,17`nBob,18`nCarol,25`n" -MinimumAge "18" -ExpectedText @("Bob, 18", "Carol, 25") -UnexpectedText @("Alice, 17")

    Write-Output "All CSV filter regression tests passed."
}
finally {
    Remove-Item -Recurse -Force $testDirectory -ErrorAction SilentlyContinue
}
