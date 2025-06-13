@echo off
setlocal EnableDelayedExpansion
@REM Why? Workspace and other files may want to be ignored, user has to set ignore files themselves
@REM files to be ignored, like workspace, prevents for making a simple symlink for folder
@REM not everything is wanted to be 

rem user settable variables, manipulate these at your will
set config_vault="E:\batch_programming\Test Obsidian\Obsidian_Config\"
rem use ; as separation between files
set "ignorefiles=workspace.json;"

rem arguments from command prompt
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
rem GLOBALS
set /a Allflag=0 & rem keeps count if user answers "All" when prompting existing files, for Hardlinks

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
    rem force override deletes files
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
    if defined project_vault set config_vault=%~1
    if not defined project_vault set project_vault=%~1
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
    echo User may define variables for this script such as "configvault" and "ignorefiles".
    echo .obsidian at the end of the path is not required
    echo Will copy or hardlink all files and create directories recursively that are in .obsidian folder.
    echo If file already exists, default behavior will ask y/n for every existing file
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
rem @todo permissions?
if !HardLinkflag!==1 if !Copyflag!==1 (
    echo Error: Cannot make Hardlink and Copy operations at the same time, use either /C or /L, not both
    exit /b %E_OPERATIONCONFLICT%
)
if !Overrideflag!==1 if !OnlyNewFilesflag!==1 (
    echo Error: Cannot override and also create files that do not exist, use either /N or /F, not both
    exit /b %E_OPERATIONCONFLICT%
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
set sourcefilepath=%~1
set destfilename=%~nx1
set folder=%~p1
set folder=!folder:*.obsidian\=!
set destination=!project_vault!!folder!!destfilename!

if not "!folder!"=="" if not exist "!project_vault!!folder!" mkdir "!project_vault!!folder!"
call :FileIgnore !destfilename! result
if !result!==1 goto :eof

if !Copyflag!==1 ( 
    if !OnlyNewFilesflag!==1 if exist !destination! goto :eof
    !operation! "!sourcefilepath!" "!destination!" 
)
if !HardLinkflag!==1 (
    if !OnlyNewFilesflag!==1 if exist !destination! goto :eof
    if not exist !destination!        !operation! "!destination!" "!sourcefilepath!" & goto :eof

    if !Overrideflag!==1 goto :FileOverride
    if !Allflag!==1 goto :FileOverride

    set bOverride=0
    call :PromptOverride "!destination!" bOverride Allflag
    if !Allflag!==1 goto :FileOverride
    if !bOverride!==1 goto :FileOverride                     
)
goto :eof
:FileOverride
del "!destination!"
!operation! "!destination!" "!sourcefilepath!"
goto :eof

:PromptOverride
set /p answer=Override file %~1 (y/n/a)?
if /I "%answer:~0,1%"=="a" call set /a "%~3=1" & goto :eof
if /I "%answer:~0,1%"=="y" call set /a "%~2=1" & goto :eof
if /I "%answer:~0,1%"=="n" call set /a "%~2=0" & goto :eof
goto :PromptOverride

:FileIgnore
set igs=!ignorefiles!
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
