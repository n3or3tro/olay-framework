@echo off
setlocal enabledelayedexpansion

REM Configuration
set "BUILD_DIR=%~dp0"
set "PROJECT_DIR=%BUILD_DIR%.."
set "SOURCE_DIR=src/olay"
set "ODIN_OUTPUT=src/olay/lua_bindings.odin"
set "LUA_OUTPUT=ui/lua_bindings.lua"
set "SHOULD_CLEAN=0"
set "VERBOSE=0"

REM Parse arguments
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-source" (
    set "SOURCE_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-odin-out" (
    set "ODIN_OUTPUT=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-lua-out" (
    set "LUA_OUTPUT=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-clean" (
    set "SHOULD_CLEAN=1"
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
echo.
echo Binding Generator Configuration:
echo   Source Dir: !SOURCE_DIR!
echo   Odin Output: !ODIN_OUTPUT!
echo   Lua Output: !LUA_OUTPUT!
echo.

if !SHOULD_CLEAN! equ 1 (
    echo Cleaning previous bindings...
    if exist "!PROJECT_DIR!\!ODIN_OUTPUT!" del "!PROJECT_DIR!\!ODIN_OUTPUT!"
    if exist "!PROJECT_DIR!\!LUA_OUTPUT!" del "!PROJECT_DIR!\!LUA_OUTPUT!"
)

cd /d "!PROJECT_DIR!"

echo Generating bindings...
odin run util -- !SOURCE_DIR! !LUA_OUTPUT! !ODIN_OUTPUT!
if errorlevel 1 goto gen_failed

echo.
echo Bindings generated successfully!
echo   Odin: !ODIN_OUTPUT!
echo   Lua: !LUA_OUTPUT!
goto end

:gen_failed
echo.
echo Binding generation failed!
exit /b 1

:show_help
echo Usage: generate-bindings.bat [options]
echo.
echo Options:
echo   -source ^<dir^>      Source directory to scan for odin files
echo                       (default: src/olay)
echo   -odin-out ^<file^>   Output path for generated odin file
echo                       (default: src/olay/lua_bindings.odin)
echo   -lua-out ^<file^>    Output path for generated lua LSP file
echo                       (default: ui/lua_bindings.lua)
echo   -clean              Remove old generated files before generating
echo   -verbose            Show verbose generator output
echo   -help               Show this message
echo.
echo Examples:
echo   generate-bindings.bat
echo   generate-bindings.bat -source src/olay -clean
echo   generate-bindings.bat -lua-out ui/bindings.lua
exit /b 0

:end
endlocal
