@echo off
setlocal EnableDelayedExpansion

rem USER SETTABLE VARIABLES, MANIPULATE THESE AT YOUR WILL
rem vault where from user copies their settings. Can be given as second path argument
set "config_vault="
rem these files are not copied or hardlinked.
rem use ; as separation between files
set "ignorefiles=workspace.json;"

rem ARGUMENTS FROM COMMAND PROMPT
set "project_vault="
set /a Copyflag=0
set /a HardLinkflag=0
set /a Overrideflag=0
set /a Helpflag=0
set /a OnlyNewFilesflag=0
rem ERROR CODES
set /a E_OPERATIONCONFLICT=2
set /a E_DRIVEMISSMATCH=3
set /a E_NONEXISTANTFOLDER=4
set /a E_HELPOPERATION=10
rem OTHER GLOBALS
rem keeps count if user answers "All" when prompting existing files, for Hardlinks
set /a Allflag=0 

:main
goto :ParseArgs
:AfterParseArgs
call :ValidateAndProcessArgs
if errorlevel %E_HELPOPERATION% (
    exit /b 0
)
if errorlevel 1 (
    exit /b 1
) 
rem operation variable used in :Filemanipulation 
set "operation="
if !Copyflag!==1 (
    set "operation=copy"
    if !Overrideflag!==1 (
        set "operation=!operation! /Y"
    ) else (
        set "operation=!operation! /-Y"
    )
) 
if !HardLinkflag!==1 ( 
    set "operation=mklink /H"
)

for /r "%config_vault%" %%F in (*) do (
    call :FileManipulation "%%~F"
)
endlocal
exit /b 0

:ParseArgs
if "%~1"=="" goto :AfterParseArgs
set farg=%~1
if "!farg:~0,1!"=="/" (
    call :SetFlag !farg!
) else (
    if not defined project_vault ( set project_vault=%~1) else ( set config_vault=%~1)
)
shift
goto :ParseArgs

:SetFlag
set flag=%~1
if /I "!flag!"=="/C" set /a Copyflag=1
if /I "!flag!"=="/L" set /a HardLinkflag=1
if /I "!flag!"=="/F" set /a Overrideflag=1
if /I "!flag!"=="/N" set /a OnlyNewFilesflag=1
if /I "!flag:~0,2!"=="/H" set /a Helpflag=1
exit /b 0

:ValidateAndProcessArgs
if !Helpflag!==1 (
    echo Copies or creates hardlinks for settings in .obsidian folder in Obsidian projects. 
    echo User may define variables in this script such as "config_vault" and "ignorefiles".
    echo .obsidian at the end of the path is not required
    echo Will copy or hardlink all files and create directories recursively that are in .obsidian folder.
    echo If a file already exists, default behavior will ask y/n for every existing file
    echo.
    echo CopyObsidianSettings.bat [/C] [/L] [/F] projectvault ^(configvault^)
    echo.
    echo   /C             Will copy files 
    echo   /L             Creates hardlinks
    echo   /F             Force override files, if files already exist, without prompting
    echo   /N             Creates files that do not already exist, without prompting
    echo   projectvault   Destination for files to be copied or hardlinked to 
    echo   configvault    Source for the files. ^(Optional if set in this .bat file^)
    exit /b %E_HELPOPERATION%
)

if !HardLinkflag!==1 if !Copyflag!==1 (
    echo Error: Cannot make Hardlink and Copy operations at the same time, use either /C or /L, not both
    exit /b %E_OPERATIONCONFLICT%
)
if !Overrideflag!==1 if !OnlyNewFilesflag!==1 (
    echo Error: Cannot override and also create files that do not exist, use either /N or /F, not both
    exit /b %E_OPERATIONCONFLICT%
)

if not defined project_vault ( 
    echo Error: "project_vault" variable is empty. 
    echo Please give it as first argument that is a path to folder
    exit /b %E_NONEXISTANTFOLDER%
)
if not defined config_vault ( 
    echo Error: "config_vault" variable is empty. 
    echo Please give it as second argument that is a path to folder or set it directly in this .bat script
    exit /b %E_NONEXISTANTFOLDER%
)

call :ProcessPath config_vault
echo Config Vault: %config_vault%
if not exist "%config_vault%" echo Error: Config vault location: %config_vault% does not exist & exit /b %E_NONEXISTANTFOLDER%

call :ProcessPath project_vault
echo Project Vault: %project_vault%
if not exist "%project_vault%" echo Error: Project vault location: %project_vault% does not exist & exit /b %E_NONEXISTANTFOLDER%

if not %config_vault:~0,2%==%project_vault:~0,2% (
    if !HardLinkflag!==1 (
        echo Error: Hardlink requires the vaults to be at the same drive, same partition,
        echo Drive for config vault: %config_vault:~0,2%
        echo Drive for project vault: %project_vault:~0,2%
        exit /b %E_DRIVEMISSMATCH%
    ) 
)
exit /b 0

:ProcessPath
call set vault_loc=%%%~1:"=%%
if "!vault_loc:~-1!"=="\" set "vault_loc=!vault_loc:~0,-1!"
echo !vault_loc! | find ".obsidian" >nul
if errorlevel 1 set vault_loc=!vault_loc!\.obsidian
call set "%~1=!vault_loc!\"
goto :eof

:FileManipulation
rem setlocal
set sourcefilepath=%~1
set destfilename=%~nx1
set folder=%~p1
set folder=!folder:*.obsidian\=!
set "destination=!project_vault!!folder!!destfilename!"

if not "!folder!"=="" if not exist "!project_vault!!folder!" mkdir "!project_vault!!folder!"
call :FileIgnore !destfilename! result
if !result!==1 goto :eof

set bOverride=0
if !Copyflag!==1 (
    set fulloperation=!operation! "!sourcefilepath!" "!destination!"

    if not exist "!destination!" ( !fulloperation! & goto :eof )
    if !OnlyNewFilesflag!==1  goto :eof

    if !OverrideFlag!==1 (
        !fulloperation!
    ) else (
        if !Allflag!==1 set "answerletter=Y"
        if !Allflag!==0 (
            call :PromptOverride "!destination!" bOverride Allflag
            set "answerletter=N"
            if !bOverride!==1 set "answerletter=Y"
        )
        echo !answerletter! | copy "!sourcefilepath!" "!destination!" >nul 2>&1
    )
    rem failed, check if both are hardlinks to same data, copy operation fails in this case
    if errorlevel 1 (
        if !OverrideFlag!==1 goto :FileCopyErrorHandling
        if /I "!answerletter!"=="Y" goto :FileCopyErrorHandling
    )
    goto :eof
)
if !HardLinkflag!==1 (
    set fulloperation=!operation! "!destination!" "!sourcefilepath!"
    if !OnlyNewFilesflag!==1 if exist "!destination!" goto :eof
    if not exist "!destination!" ( !fulloperation! & goto :eof )

    if !Overrideflag!==1 goto :FileOverride
    if !Allflag!==1 goto :FileOverride
    call :PromptOverride "!destination!" bOverride Allflag
    if !Allflag!==1 goto :FileOverride
    if !bOverride!==1 goto :FileOverride                     
)
goto :eof

:FileOverride
del "!destination!"
!fulloperation!
exit /b 0

:FileCopyErrorHandling
set /a hardlinkcount=0
for /f "delims=" %%H in ('fsutil hardlink list "!destination!"') do (
    echo %%~H
    set /a hardlinkcount+=1
)
rem do first delete then copy
if !hardlinkcount! GEQ 2 (
    goto :FileOverride
)
goto :eof

:PromptOverride
set /p answer=Override file %~1 (y/n/a)?
if /I "%answer:~0,1%"=="a" call set /a "%~3=1" & call set /a "%~2=1" & goto :eof
if /I "%answer:~0,1%"=="y" call set /a "%~2=1" & goto :eof
if /I "%answer:~0,1%"=="n" call set /a "%~2=0" & goto :eof
goto :PromptOverride

:FileIgnore
set "igs=!ignorefiles!"
set /a %2=0
:NextFileIgnore
for /f "delims=; tokens=1,*" %%A in ("!igs!") do (
    if "%%~A"=="!destfilename!" (
        set /a %2=1
        goto :eof
    )
    set "igs=%%B"
    if defined igs goto :NextFileIgnore
)
goto :eof
