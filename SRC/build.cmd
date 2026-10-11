@echo off
rem Build Object Professional (FPC 3.2.2, Windows). Run from the SRC directory.
rem Usage: build.cmd [outdir]     (default: out\win64 for units, out\win64\bin for demos)
rem Default target is 64-bit (x86_64-win64). For 32-bit:  set CPU=i386 & build.cmd
setlocal enabledelayedexpansion
cd /d "%~dp0"
if "%FPC%"=="" set FPC=fpc
if "%CPU%"=="" set CPU=x86_64
if /i "%CPU%"=="i386" (set TARGETOS=win32& set TAG=win32) else (set TARGETOS=win64& set TAG=win64)
set TGT=-P%CPU% -T%TARGETOS%
if "%~1"=="" (set OUT=out\%TAG%) else (set OUT=%~1)
set UNITS=%OUT%\units
set BIN=%OUT%\bin
if not exist "%UNITS%" mkdir "%UNITS%"
if not exist "%BIN%" mkdir "%BIN%"
set OPTS=%TGT% -Mtp -Sg -FU"%UNITS%" -Fu. -Fi. -Fi.\OPRODEMO
set FAILED=0

echo === Library units (%CPU%-%TARGETOS%) ===
for %%F in (*.pas) do (
  %FPC% %OPTS% -FE"%UNITS%" %%F >nul
  if errorlevel 1 (echo FAILED: %%F & set /a FAILED+=1)
)

echo === Demos ===
pushd OPRODEMO
for %%F in (*.pas) do (
  %FPC% %TGT% -Mtp -Sg -FU"..\%UNITS%" -FE"..\%BIN%" -Fu.. -Fi.. -Fi. %%F >nul
  if errorlevel 1 (echo FAILED: OPRODEMO\%%F & set /a FAILED+=1)
)
popd

echo Done. Failures: %FAILED%
exit /b %FAILED%