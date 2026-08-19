@echo off
setlocal

if "%~1"=="" goto :usage

set "INPUT=%~f1"

if not exist "%INPUT%" (
    echo ERROR: Input file not found:
    echo   %INPUT%
    exit /b 2
)

if /I not "%~x1"==".pdf" (
    echo ERROR: Input file must have a .pdf extension.
    exit /b 2
)

if "%~2"=="" (
    set "OUTPUT=%~dpn1-signed.pdf"
) else (
    set "OUTPUT=%~f2"
    if "%~x2"=="" set "OUTPUT=%~f2.pdf"
)

if /I "%INPUT%"=="%OUTPUT%" (
    echo ERROR: Input and output files must be different.
    exit /b 2
)

if exist "%OUTPUT%" (
    echo ERROR: Output file already exists:
    echo   %OUTPUT%
    exit /b 2
)

where pyhanko >nul 2>nul
if errorlevel 1 (
    echo ERROR: pyhanko was not found in PATH.
    exit /b 3
)

if not exist "C:\Windows\System32\akisp11.dll" (
    echo ERROR: AKIS PKCS#11 module was not found:
    echo   C:\Windows\System32\akisp11.dll
    exit /b 3
)

set "SCRIPT_DIR=%~dp0"
set "CONFIG=%SCRIPT_DIR%pyhanko.yml"

if not exist "%CONFIG%" (
    echo ERROR: pyhanko.yml was not found next to imzala.cmd.
    exit /b 3
)

set "TMP_OUTPUT=%OUTPUT%.imzala-tmp-%RANDOM%-%RANDOM%.pdf"
set "CARD_OUTPUT=%OUTPUT%.imzala-card-probe-%RANDOM%-%RANDOM%.pdf"
set "CARD_LOG=%CARD_OUTPUT%.log"

pushd "%SCRIPT_DIR%" >nul
if errorlevel 1 (
    echo ERROR: Could not enter the script directory.
    exit /b 3
)

pyhanko --config "%CONFIG%" sign addsig ^
  --existing-only ^
  --field __imzala_card_probe__ ^
  pkcs11 ^
  --lib "C:\Windows\System32\akisp11.dll" ^
  --token-label "AKIS_04655182A91F9094" ^
  --cert-label "10391976242NES0" ^
  --skip-user-pin ^
  "%INPUT%" ^
  "%CARD_OUTPUT%" >"%CARD_LOG%" 2>&1

findstr /I /C:"No token matching criteria" "%CARD_LOG%" >nul
if not errorlevel 1 (
    if exist "%CARD_OUTPUT%" del /Q "%CARD_OUTPUT%" >nul 2>nul
    if exist "%CARD_LOG%" del /Q "%CARD_LOG%" >nul 2>nul
    echo ERROR: AKIS card or token was not found; insert the card and check the reader.
    popd
    exit /b 3
)

findstr /I /C:"__imzala_card_probe__" "%CARD_LOG%" | findstr /I /C:"does not exist" >nul
if errorlevel 1 (
    echo ERROR: AKIS card check failed.
    type "%CARD_LOG%"
    if exist "%CARD_OUTPUT%" del /Q "%CARD_OUTPUT%" >nul 2>nul
    if exist "%CARD_LOG%" del /Q "%CARD_LOG%" >nul 2>nul
    popd
    exit /b 3
)

if exist "%CARD_OUTPUT%" del /Q "%CARD_OUTPUT%" >nul 2>nul
if exist "%CARD_LOG%" del /Q "%CARD_LOG%" >nul 2>nul

echo Signing:
echo   %INPUT%
echo Output:
echo   %OUTPUT%
echo.

pyhanko --config "%CONFIG%" sign addsig ^
  --field Sig1 ^
  --use-pades ^
  --timestamp-url http://timestamp.digicert.com ^
  pkcs11 ^
  --p11-setup akis-windows ^
  "%INPUT%" ^
  "%TMP_OUTPUT%"

if errorlevel 1 goto :sign_failed

echo.
echo Validating signed PDF...
echo.

pyhanko --config "%CONFIG%" sign validate ^
  --validation-context kamusm ^
  --pretty-print ^
  "%TMP_OUTPUT%"

if errorlevel 1 goto :validation_failed

move /Y "%TMP_OUTPUT%" "%OUTPUT%" >nul
if errorlevel 1 goto :move_failed

echo.
echo SUCCESS: Signature and timestamp validated.
echo   %OUTPUT%
popd
exit /b 0

:sign_failed
if exist "%TMP_OUTPUT%" del /Q "%TMP_OUTPUT%" >nul 2>nul
echo.
echo ERROR: Signing failed. No output file was created.
popd
exit /b 1

:validation_failed
if exist "%TMP_OUTPUT%" del /Q "%TMP_OUTPUT%" >nul 2>nul
echo.
echo ERROR: Validation failed. The temporary signed file was removed.
popd
exit /b 1

:move_failed
if exist "%TMP_OUTPUT%" del /Q "%TMP_OUTPUT%" >nul 2>nul
echo.
echo ERROR: The validated file could not be moved to:
echo   %OUTPUT%
popd
exit /b 1

:usage
echo Usage:
echo   imzala INPUT.pdf [OUTPUT.pdf]
echo.
echo If OUTPUT.pdf is omitted, INPUT-signed.pdf is created next to INPUT.pdf.
exit /b 2
