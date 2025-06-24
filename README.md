# ObsidianSettingsImporter
Copy or hard link Obsidian settings from .obsidian folder to other

## Problem it solves
In [Obsidian](https://obsidian.md) notetaking tool one cannot specify a template that every Obsidian project uses.
This means all settings in .obsidian need to be always copied manually to a new project.
However, usually most of the projects use same shortcuts, css libraries, etc, so it 
would be nice to have just one template which, if changed, all of the changes
are reflected in all of the projects that use such template. 

This batch script solves part of the problem by providing a script that creates
[hard links](https://learn.microsoft.com/en-us/windows/win32/fileio/hard-links-and-junctions) between vaults - Obsidian projects. This means changes between any of these vaults
are reflected in all that have the same hard link. This script will copy or hard link all files that exist in *.obsidian* folder. 

Sometimes we just want to copy some settings, so a copy operation is also provided.

## Simple how to
Copy ObsidianSettingsImporter.bat or git clone this project. Open command prompt.<br>

### Example for creating hard links
```
cmd> "path\to\ObsidianSettingsImporter.bat" "path\to\project_vault" "path\to\config_vault" /l
```
***"path\to\ObsidianSettingsImporter.bat"*** = where ObsidianSettingsImporter.bat is saved<br> 
***"path\to\project_vault"*** = into where setting are copied or hard linked to<br>
***"path\to\config_vault"*** = from where settings are copied or hard linked - config/template<br>
***/l*** = flag that tells to create hard links of the config vault<br><br>
If files exists already, user will be prompted with y/n/a question about every file.<br><br>
Alternatively user can give **/f** flag to override existing files without prompting.
```
cmd> "path\to\ObsidianSettingsImporter.bat" "path\to\project_vault" "path\to\config_vault" /l /f
```
## Additional information
### Help
Give **/h** flag to see all the other options
```
cmd> "path\to\ObsidianSettingsImporter.bat" /h
```
### Setting up default config vault
User can set default location from where the settings are copied or hard linked.<br>
Set ***config_vault*** -variable in the script file to the path which settings you want to copy or hard link. 

### ignorefiles
Files that are not copied or hard linked. Files are separated with **;** -symbol. User can manipulate these at will.<br>
By default workspace.json is ignored, it holds what project specific information, like what tabs are open and so on...
```
set "ignorefiles=workspace.json;"
```  

### Order of arguments
Order doesn't matter with flags, but both path arguments need to be in order **first** *path\to\project_vault*, **second** *path\to\config_vault*. 

## Errors
- Use **"** -symbols to cover the *"path\to\anypath"* if there are white spaces in the path. Batch interprets whitespace as end of an argument.
- Some flags might conflict with each other, script notify with an error.
- hard links between projects need to be in same drive/partition in the computer. Script notify with an error.

## What is Obsidian
For context [Obsidian](https://obsidian.md) is a note taking tool that users can tailor for their note-taking-needs. It is designed to be portable. A simple
copy of some projects files to a new folder and you are good to go. This has limitations like all design choices, this script tries to relieve some pains caused by this - explained in above. 
