$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $repoRoot
try {
	& odin run "src/olay/tests/generator_unit" -ignore-warnings -ignore-unknown-attributes -out:"build/generator_unit_tests_runner.exe" -- @args
	exit $LASTEXITCODE
} finally {
	Pop-Location
}
