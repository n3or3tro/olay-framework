@echo off
setlocal enabledelayedexpansion

REM Configuration
set "BUILD_DIR=%~dp0"
set "PROJECT_DIR=%BUILD_DIR%.."
set "CONFIG=debug"
set "BUILD_MODE=full"
set "SHOULD_CLEAN=0"
set "SHOULD_RUN=0"
set "VERBOSE=0"

REM Parse arguments
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-debug" (
    set "CONFIG=debug"
    shift
    goto parse_args
)
if /i "%~1"=="-release" (
    set "CONFIG=release"
    shift
    goto parse_args
)
if /i "%~1"=="-dll-only" (
    set "BUILD_MODE=dll"
    shift
    goto parse_args
)
if /i "%~1"=="-full" (
    set "BUILD_MODE=full"
    shift
    goto parse_args
)
if /i "%~1"=="-clean" (
    set "SHOULD_CLEAN=1"
    shift
    goto parse_args
)
if /i "%~1"=="-run" (
    set "SHOULD_RUN=1"
    shift
    goto parse_args
)
if /i "%~1"=="-verbose" (
    set "VERBOSE=1"
    shift
    goto parse_args
)
if /i "%~1"=="-help" (
    goto show_help
)
echo Unknown option: %~1
goto show_help

:args_done
if !SHOULD_CLEAN! equ 1 (
    echo Cleaning build directory...
    if exist "!BUILD_DIR!app.exe" del "!BUILD_DIR!app.exe"
    if exist "!BUILD_DIR!app.dll" del "!BUILD_DIR!app.dll"
)

echo.
echo Build Configuration:
echo   Config: !CONFIG!
echo   Mode: !BUILD_MODE!
echo.

cd /d "!PROJECT_DIR!"

set "ODIN_FLAGS=-ignore-warnings"
set "ODIN_FLAGS=!ODIN_FLAGS! -custom-attribute:lua_data"
set "ODIN_FLAGS=!ODIN_FLAGS! -custom-attribute:lua_global"
set "ODIN_FLAGS=!ODIN_FLAGS! -custom-attribute:lua_proc"
set "ODIN_FLAGS=!ODIN_FLAGS! -custom-attribute:lua_struct"

if "!CONFIG!"=="release" (
    set "ODIN_FLAGS=!ODIN_FLAGS! -o:speed"
) else (
    set "ODIN_FLAGS=!ODIN_FLAGS! -debug"
)

if !VERBOSE! equ 1 (
    set "ODIN_FLAGS=!ODIN_FLAGS! -verbose"
)

if "!BUILD_MODE!"=="full" (
    echo Building app.exe...
    odin build src -out:!BUILD_DIR!app.exe !ODIN_FLAGS!
    if errorlevel 1 goto build_failed
)

echo Building app.dll...
odin build src/olay -build-mode:dll -out:!BUILD_DIR!app.dll !ODIN_FLAGS!
if errorlevel 1 goto build_failed

echo.
echo Build successful!
if !SHOULD_RUN! equ 1 (
    echo.
    echo Running app.exe...
    "!BUILD_DIR!app.exe"
)
goto end

:build_failed
echo.
echo Build failed!
exit /b 1

:show_help
echo Usage: build.bat [options]
echo.
echo Options:
echo   -debug           Build with debug info (default)
echo   -release         Build optimized for release
echo   -dll-only        Build only app.dll (faster iteration)
echo   -full            Build app.exe and app.dll (default)
echo   -clean           Clean build output before building
echo   -run             Run app.exe after successful build
echo   -verbose         Show verbose build output
echo   -help            Show this message
echo.
echo Examples:
echo   build.bat -debug -dll-only
echo   build.bat -release -full -run
echo   build.bat -clean
exit /b 0

:end
endlocal
