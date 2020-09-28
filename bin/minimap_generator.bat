@ECHO OFF
set COUNT=0
for %%x in (%*) do set /A COUNT+=1

if %COUNT% NEQ 3 if %COUNT% NEQ 4  echo Usage: minimap_generator.bat ^<hscale^> ^<vscale^> ^<padding^> [file] goto exit

set hscale=%1
set vscale=%2
set padding=%3
set file=%4

:: batch files limited - not trivial to check for nullOrWhitespace like in pwsh/bash

if "%file%" == "" goto nofile
:: else,
goto hasfile


:hasfile

code-minimap -H "%hscale%" -V "%vscale%" --padding "%padding%" "%file%"
goto exit


:nofile

code-minimap -H "%hscale%" -V "%vscale%" --padding "%padding%"
echo nofile
goto exit

:exit