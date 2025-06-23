# ObsidianSettingsImporter
Copy or hardlink Obsidian settings from .obsidian folder to other

## Problem it solves
In Obsidian one cannot specify a template that every Obsidian project uses.
This means all settings in .obsidian need to be always copied manually to a new project.
However, usually most of the projects use same shortcuts and css libraries, so it 
would be nice to just have just one template which is changed and all the changes
are reflected in all of the projects that use such a template. 

This batch script solves part of the problem by providing a batch script that creates
[hardlinks](https://learn.microsoft.com/en-us/windows/win32/fileio/hard-links-and-junctions) between vaults - Obsidian projects. This means changes between any of these vaults
are reflected in all that have the same hardlink. 

Sometimes we just want to copy some settings and modify them, so a copy operation is also provided.

## Simple how to
Copy ObsidianSettingsImporter.bat or git clone this project. Open command prompt<br>
Example for creating hardlinks
```
cmd> "path\to\ObsidianSettingsImporter.bat" "path\to\project_vault" "path\to\config_vault" -l
```
**path\to\ObsidianSettingsImporter.bat** = where ObsidianSettingsImporter.bat is saved<br> 
**path\to\project_vault** = into where setting are copied or hardlinked to<br>
**path\to\config_vault** = from where settings are copied or hardlinked - config/template<br>

## Other


### Errors
Hardlinks between projects need to be in same drive/partition in the computer. Batch file will create an error if this happens.
