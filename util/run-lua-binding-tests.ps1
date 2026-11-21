$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

& (Join-Path $repoRoot "util/regenerate-lua-fixture-bindings.ps1")
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

Push-Location $repoRoot
try {
	& odin run "src/olay/tests/lua_bindings" -ignore-warnings -ignore-unknown-attributes -out:"build/lua_binding_tests_runner.exe" -- @args
	exit $LASTEXITCODE
} finally {
	Pop-Location
}
