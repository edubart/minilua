@echo off
rem make.bat -- build minilua.exe on Windows using MSVC (cl), MinGW (gcc), Clang, TCC, etc.
rem Usage: make.bat [compiler] [build ^| test ^| clean]
rem   compiler: auto ^(default^), msvc ^| cl, gcc, clang, clang-cl, tcc ^| tinycc, cc,
rem             "CC=^<exe^>" ^| "COMPILER=^<exe^>" ^(quotes required, ^= splits args^),
rem             or any exe in PATH ^(e.g. "zig cc" wrapper, x86_64-w64-mingw32-gcc^)
rem Examples:
rem   make.bat                 :: auto-detect compiler, build
rem   make.bat gcc             :: build with gcc
rem   make.bat clang test      :: build with clang + run smoke test
rem   make.bat test msvc       :: same, args work in either order
rem   make.bat tcc build       :: build with TinyCC
rem   make.bat "CC=gcc" test   :: build with gcc + test ^(quotes required^)
rem   make.bat clean           :: remove outputs
setlocal
cd /d "%~dp0"
set "COMPILER=auto"
set "COMPILER_SET=0"
set "ACTION=build"

if "%~1"=="" goto :dispatch
call :parse_arg "%~1"
if errorlevel 1 exit /b 1
if /i "%ACTION%"=="help" goto :usage
if "%~2"=="" goto :dispatch
call :parse_arg "%~2"
if errorlevel 1 exit /b 1
if /i "%ACTION%"=="help" goto :usage
if not "%~3"=="" (
  echo Too many arguments. Usage: %~nx0 [compiler] [build ^| test ^| clean]
  exit /b 1
)

:dispatch
if /i "%ACTION%"=="help" goto :usage
if /i "%ACTION%"=="clean" goto :clean
if /i "%ACTION%"=="test" goto :build_and_test
if /i "%ACTION%"=="build" goto :build
echo Usage: %~nx0 [compiler] [build ^| test ^| clean]
exit /b 1

:build
call :do_build
exit /b %ERRORLEVEL%

:build_and_test
call :do_build
if errorlevel 1 exit /b 1
echo --- running minilua ---
minilua.exe -e "print 'hello world'"
exit /b %ERRORLEVEL%

:parse_arg
set "ARG=%~1"
if /i "%ARG%"=="build" (
  set "ACTION=build"
  exit /b 0
)
if /i "%ARG%"=="test" (
  set "ACTION=test"
  exit /b 0
)
if /i "%ARG%"=="clean" (
  set "ACTION=clean"
  exit /b 0
)
if /i "%ARG%"=="help" (
  set "ACTION=help"
  exit /b 0
)
if "%ARG%"=="-h" (
  set "ACTION=help"
  exit /b 0
)
if "%ARG%"=="--help" (
  set "ACTION=help"
  exit /b 0
)
if "%ARG%"=="/?" (
  set "ACTION=help"
  exit /b 0
)
if /i "%ARG%"=="auto" (
  set "COMPILER=auto"
  set "COMPILER_SET=0"
  exit /b 0
)
if /i "%ARG%"=="msvc" (
  call :set_compiler msvc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="cl" (
  call :set_compiler msvc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="vs" (
  call :set_compiler msvc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="gcc" (
  call :set_compiler gcc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="mingw" (
  call :set_compiler gcc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="mingw64" (
  call :set_compiler gcc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="clang" (
  call :set_compiler clang
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="clang-cl" (
  call :set_compiler clang-cl
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="tcc" (
  call :set_compiler tcc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="tinycc" (
  call :set_compiler tcc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="tiny-c" (
  call :set_compiler tcc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG%"=="cc" (
  call :set_compiler cc
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /i "%ARG:~0,3%"=="CC=" goto :parse_cc_eq
if /i "%ARG:~0,9%"=="COMPILER=" goto :parse_compiler_eq
echo "%ARG%" | find "=" >nul
if not errorlevel 1 (
  echo Unknown option "%~1". Usage: %~nx0 [compiler] [build ^| test ^| clean]
  exit /b 1
)
rem Anything else is treated as a custom compiler exe / wrapper (e.g. x86_64-w64-mingw32-gcc, "zig cc").
call :set_compiler "%ARG%"
exit /b %ERRORLEVEL%

:parse_cc_eq
set "NEWCOMP=%ARG:~3%"
if "%NEWCOMP%"=="" (
  echo Empty compiler in "%~1". Usage: %~nx0 [compiler] [build ^| test ^| clean]
  exit /b 1
)
call :set_compiler "%NEWCOMP%"
exit /b %ERRORLEVEL%

:parse_compiler_eq
set "NEWCOMP=%ARG:~9%"
if "%NEWCOMP%"=="" (
  echo Empty compiler in "%~1". Usage: %~nx0 [compiler] [build ^| test ^| clean]
  exit /b 1
)
call :set_compiler "%NEWCOMP%"
exit /b %ERRORLEVEL%

:set_compiler
rem %1 = compiler value to set. Only one explicit compiler allowed (auto resets).
if /i "%~1"=="auto" (
  set "COMPILER=auto"
  set "COMPILER_SET=0"
  exit /b 0
)
if "%COMPILER_SET%"=="1" (
  echo Only one compiler may be specified. Got "%~1" after "%COMPILER%".
  echo Hint: quote NAME=value forms, e.g. "CC=gcc".
  exit /b 1
)
set "COMPILER=%~1"
set "COMPILER_SET=1"
exit /b 0

:usage
echo Usage: %~nx0 [compiler] [build ^| test ^| clean]
echo   compiler: auto, msvc, gcc, clang, clang-cl, tcc, cc, "CC=<exe>", or custom exe
echo   action:   build ^(default^), test, clean
echo   Note: quote NAME=value forms, e.g. "CC=gcc", because = splits CMD args.
exit /b 0

:do_build
if /i "%COMPILER%"=="auto" goto :do_build_auto
if /i "%COMPILER%"=="msvc" goto :do_build_msvc
if /i "%COMPILER%"=="gcc" goto :do_build_gcc
if /i "%COMPILER%"=="clang" goto :do_build_clang
if /i "%COMPILER%"=="clang-cl" goto :do_build_clang_cl
if /i "%COMPILER%"=="tcc" goto :do_build_tcc
if /i "%COMPILER%"=="cc" goto :do_build_cc
goto :do_build_custom

:do_build_auto
rem Backward compat: explicit CC env var wins when auto.
if defined CC (
  set "COMPILER=%CC%"
  goto :do_build_custom
)
where cl >nul 2>nul
if not errorlevel 1 (
  set "COMPILER=msvc"
  goto :do_build_msvc
)
where gcc >nul 2>nul
if not errorlevel 1 (
  set "COMPILER=gcc"
  goto :do_build_gcc
)
where clang >nul 2>nul
if not errorlevel 1 (
  set "COMPILER=clang"
  goto :do_build_clang
)
where tcc >nul 2>nul
if not errorlevel 1 (
  set "COMPILER=tcc"
  goto :do_build_tcc
)
where cc >nul 2>nul
if not errorlevel 1 (
  set "COMPILER=cc"
  goto :do_build_cc
)
echo No C compiler found. Install MSVC, MinGW (gcc), Clang, or TCC and ensure it is in PATH.
echo Or pass one explicitly: %~nx0 [msvc ^| gcc ^| clang ^| clang-cl ^| tcc ^| cc] [build ^| test ^| clean]
exit /b 1

:do_build_msvc
where cl >nul 2>nul
if errorlevel 1 (
  echo Compiler "cl" ^(MSVC^) not found in PATH. Open a Developer Prompt or install VS Build Tools.
  exit /b 1
)
call :compile_msvc cl
exit /b %ERRORLEVEL%

:do_build_gcc
where gcc >nul 2>nul
if errorlevel 1 (
  echo Compiler "gcc" not found in PATH. Install MinGW/MSYS2 gcc.
  exit /b 1
)
echo Using gcc ...
gcc -O2 -o minilua.exe tests\lua.c
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
echo Built minilua.exe with gcc.
exit /b 0

:do_build_clang
where clang >nul 2>nul
if errorlevel 1 (
  echo Compiler "clang" not found in PATH. Install LLVM Clang.
  exit /b 1
)
echo Using clang ...
clang -O2 -o minilua.exe tests\lua.c
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
echo Built minilua.exe with clang.
exit /b 0

:do_build_clang_cl
where clang-cl >nul 2>nul
if errorlevel 1 (
  echo Compiler "clang-cl" not found in PATH. Install LLVM Clang.
  exit /b 1
)
call :compile_msvc clang-cl
exit /b %ERRORLEVEL%

:do_build_tcc
where tcc >nul 2>nul
if errorlevel 1 (
  echo Compiler "tcc" ^(TinyCC^) not found in PATH. Install TinyCC.
  exit /b 1
)
echo Using tcc ...
tcc -O2 -o minilua.exe tests\lua.c
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
echo Built minilua.exe with tcc.
exit /b 0

:do_build_cc
where cc >nul 2>nul
if errorlevel 1 (
  echo Compiler "cc" not found in PATH.
  exit /b 1
)
echo Using cc ...
cc -O2 -o minilua.exe tests\lua.c
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
echo Built minilua.exe with cc.
exit /b 0

:do_build_custom
echo Using custom compiler: %COMPILER% ...
if exist "%COMPILER%" (
  "%COMPILER%" -O2 -o minilua.exe tests\lua.c
) else (
  %COMPILER% -O2 -o minilua.exe tests\lua.c
)
if errorlevel 1 (
  echo Build failed with "%COMPILER%".
  exit /b 1
)
echo Built minilua.exe with %COMPILER%.
exit /b 0

:compile_msvc
rem %1 = cl-compatible compiler exe (cl or clang-cl)
echo Using %1 ...
%1 /nologo /O2 /Feminilua.exe tests\lua.c
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
if exist lua.obj del lua.obj
if exist minilua.obj del minilua.obj
if exist tests\lua.obj del tests\lua.obj
echo Built minilua.exe with %1.
exit /b 0

:clean
del /f /q minilua.exe *.obj tests\*.obj 2>nul
echo Cleaned.
exit /b 0
