@echo off

call config

echo Copy includes to compiler...
if exist "%INCLUDES_PATH%" (
    call :copy %INCLUDES_PATH%\*, %AMXX_COMPILER_INCLUDES_PATH%
)

echo Cleanup old compiled plugins...
call :deldir %COMPILER_OUTPUT_PATH%
call :deldir %AMXMODX_PATH%\plugins

if not "%PACKAGE_COMPILED_PLUGINS_USE%" == "1" goto after-compile

echo Prepare for compiling plugins...

call :del %PLUGINS_LIST%
if "%PACKAGE_PLUINGS_LIST_USE%" == "1" (
    call :makedir %PLUGINS_LIST_PATH%
    echo. 2>%PLUGINS_LIST%
)

echo Compile plugins...

call :makedir %COMPILER_OUTPUT_PATH%
cd %COMPILER_OUTPUT_PATH%
for /R %AMXMODX_PATH%\scripting %%F in (*.sma) do (
    echo.
    echo Compile %%~nF:
    
    if "%PACKAGE_DEBUG%" == "1" (
       %AMXX_COMPILER_EXECUTABLE_PATH% DEBUG=1 %%F
    ) else (
       %AMXX_COMPILER_EXECUTABLE_PATH% %%F
    )

    if errorlevel 1 (
        echo.
        echo Plugin %%~nF compiled with error.
        set /p q=
        exit /b %errorlevel%
    )

    if "%PACKAGE_PLUINGS_LIST_USE%" == "1" (
       echo %%~nF.amxx>>%PLUGINS_LIST%
    )
)
cd %ROOT_PATH%
:after-compile

echo Prepare files...
call :makedir %BUILD_AMXMODX_PATH%
call :copy "%AMXMODX_PATH%\*", "%BUILD_AMXMODX_PATH%"

if "%PACKAGE_README_USE%" == "1" (
    call :copy "%README_FILE%", "%BUILD_ROOT_PATH%"
)

if "%PACKAGE_ASSETS_USE%" == "1" (
    call :makedir %BUILD_ASSETS_PATH%
    call :copy %ASSETS_PATH%\* %BUILD_ASSETS_PATH%
)

echo Compress files to ZIP archive...
call :del %ZIP_FILE%
call :zip %BUILD_ROOT_PATH%/*, %ZIP_FILE%

echo Cleanup temp files...
call :deldir %BUILD_ROOT_PATH%

echo Build finished.

exit 0

:makedir
    if not exist %~1 mkdir %~1
exit /b

:deldir
    if exist %~1 rd /S /q %~1
exit /b

:del
    if exist %~1 del %~1
exit /b

:copy
    powershell Copy-Item -Path %~1 -Destination %~2 -Recurse -Force
exit /b

:zip
    powershell Compress-Archive %~1 %~2 -Force
exit /b