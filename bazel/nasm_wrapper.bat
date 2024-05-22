@echo off
setlocal EnableDelayedExpansion

rem --------------------------------------------------------------------------------
rem  Bazel NASM Invocation Wrapper
rem
rem  Purpose:
rem    Compiles assembly source files using NASM with specific flags and include paths.
rem    This script is designed for integration with Bazel build systems.
rem
rem  Arguments:
rem    %1:  Path to the NASM executable (nasm.exe)
rem    %2:  Path to the source assembly file (.asm)
rem    %3:  Path to the output object file (.obj or .o)
rem
rem  Example Usage:
rem    call nasm_wrapper.bat "C:\path\to\nasm.exe" "C:\project\src\mycode.asm" "C:\project\obj\mycode.obj"
rem --------------------------------------------------------------------------------

set "NASM_EXE=%1"
set "SRC=%2"
set "OUT=%3"


rem Extract and store the base directory of the source file
call :getPath "%SRC%" INC_DIR

rem Construct the full paths for NASM include directories
set "incDirMain=%INC_DIR%"
set "incDirNasm=%INC_DIR%\..\nasm"

rem Invoke NASM with defined flags and include paths
%NASM_EXE% -DRGBX_FILLER_0XFF -f win64 -DWIN64 -D__x86_64__ -DARCH_X86_64 ^
     -I %incDirMain% -I %incDirNasm% ^
     %SRC% -o %OUT%

if errorlevel 1 (
    echo Error: NASM compilation failed. Check the source file and paths.
    exit /b 1
)

goto :eof

rem --------------------------------------------------------------------------------
rem  :getPath  -  Subroutine to extract the directory from a file path
rem
rem  Arguments:
rem    %1:  File path (e.g., C:\path\to\file.asm)
rem    %2:  Variable name to store the extracted directory
rem
rem  Returns:
rem    Sets the variable specified in %2 to the extracted directory.
rem --------------------------------------------------------------------------------
:getPath
set "%2=%~dp1"
exit /b
