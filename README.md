# Win-PS-Autobackuping README

<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD001 -->
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD025 -->
<!-- markdownlint-disable MD026 -->

## Powershell Autobackuping Script for Windows.

It uses Robocopy as standard, or Powershell, to copy all the files and folders in the script folder to one or more targets. The files can be compressed with 7zip (no robocopy there and no exclusions). Tere are some Settings you can change in the Script.

If you have BackupSettings.json in the same folder as the Script, it will use the settings from there. If you don't have a BackupSettings.json, it will use the default settings from script.

## Function:

- Make backup of all Files in contained folder, except exclusions...
- WindowsCronRegister-backup.ps1 can register the Script as a Windows Task, so it will run every day at the time you set in the Script.

---

## First steps

<br>

### allow powershell scripts execution

1. open powershell as administrator
2. run `Set-ExecutionPolicy RemoteSigned`

> optional: `Get-ExecutionPolicy -list |% {Set-ExecutionPolicy -scope $_.scope remotesigned -force -ErrorAction SilentlyContinue}`
>
> > this script set all scopes to remotesigned, but throws some errors, because not all scopes are available on all systems

<br>

### execute ps scripts on double click

1. clone this repo
2. right click on `backup.ps1` and select `Properties`
3. in the section `open with`, select `change`

- ![Screenshot1](assets/Screenshot_1.jpg)

4. scroll down and choose `More apps`

- ![Screenshot2](assets/Screenshot_2.jpg)

5. scroll down and choose `Look for another app on this PC`

- ![Screenshot3](assets/Screenshot_3.jpg)

6. paste `C:\Windows\System32\WindowsPowerShell\v1.0` in adressfield and press enter

- ![Screenshot4](assets/Screenshot_4.jpg)

7. select `PowerShell.exe` and choose open

---

## Settings

```json
{
    "SourcePaths":  [
                        "./",
                        "T:\\zz_bkp_setings_folder"
                    ],
    "makeNewFolderIfNotExist":  true,
    "TargetPaths":  [
                        "T:\\myAppBackupFolder\\",
                        "T:\\myAppBackupFolder\\settings\\"
                    ],
    "global:debugTransScript":  false,
    "global:debug":  false,
    "UpdateVersion":  142,
    "AdminRightsRequired":  false,
    "AllowUpdate":  1,
    "UpdateFromPath":  "https://raw.githubusercontent.com/vitalyruhl/Win-PS-Autobackuping/master",
    "UpdateFile":  "backup.ps1",
    "UpdateVersionFile":  "VersionSettings.json",
    "Prefix":  "",
    "Sufix":  "",
    "CompressIntoTargetPaths":  false,
    "UseRobocopy":  true,
    "Parameter":  "/J /MIR /R:2 /W:1 /NP /COMPRESS",
    "Excludes":  [
        ".git",
        "node_modules",
        "*RECYCLE.BIN",
        "SystemVolumeInformation",
        "RECYCLER"
    ],
    "FileExcludes":  [
            "*xvba_debug.log",
            "*RECYCLE.BIN",
            "Thumbs.db"
        ]
}
```

you can use a local path to update your script:

```json
"UpdateFromPath":"\\\\myserver\\ps-scripts\\Powerschell\\Backup",

```

all variables, not included in the BackupSettings.json will be set to the default values.

---

## To-Do / Errors:

- 03.08.2021 Exclusion don't work with compressing -> its copy all files
- 18.09.2022 Add format-variables like %date% to the prefix and sufix on uses settings.json
- 18.09.2022 Add a function to delete old backups, helpfull on compresssed backups with suffixes and prefixes
- 18.09.2022 Add possibility to rename script, and backup them also (for use multiple script in same folder)
- 18.09.2022 Register the script as a windows task must be changed for every script you need. It need a Refactoring to the backup.ps1 to run it over settings.json, or command parameter.
- 16.04.2023 Add updatesupport for Script without backupSettings.json and witoout settings overriden in the script
- 16.04.2023 correct parameter. On this time are excludes folder only, add /XF for files
- 16.04.2023 remove old copy, use only robocopy.
- 12.08.2023 BUG: copy from or into a folder with whitespaces and ÜÖÄ will don't work

<br>

---

## What's new

### V1.5.0

- 12.08.2023 - Bugfix: Rename UseCoherentBackup Parameter - its confuse and make some deleteon on target.

  ```json
    "makeNewFolderIfNotExist":  true,
  ```
  
- "makeNewFolderIfNotExist": true --> (default) means, that first sourse will be copied to first target,second source to second target and so on. And a new folder with the last source folder will be created on the Target Path.

- "makeNewFolderIfNotExist": false --> means, that all sources will be copied to all targets. **AND in this Option, all files in the target will be deleted, if they are not in the source. Be careful with this option and make tests!!!.**

### V1.4.2

- 12.08.2023 - Bugfix: Excludes (Files) - Add a new Parameter FileExcludes to prevent double excludes /XD + /XF

  ```json
  "FileExcludes":  [
          "*xvba_debug.log",
          "*RECYCLE.BIN",
          "Thumbs.db"
      ]
  ```

### V1.4.1

- 07.08.2023 - Bugfix: Excludes (Files) don't work

### V1.4.0

- 16.04.2023 - Add multiple source and target support

  New Parameter in BackupSettings.json:

  ```json
  "SourcePaths":  [
                      "./",
                      "C:\\Users\\vivil\\Pictures\\"
                  ],
  "TargetPaths":  [
                      "T:\\zz_bkp_Test1\\",
                      "T:\\zz_bkp_Test2\\"
                  ],
  "makeNewFolderIfNotExist":  false,

  ```

  **Note in this case, all files in the target will be deleted, if they are not in the source. Be careful with this option and make tests!!!.**  

  Example-2:

  - If you want to backup the script folder and a folder with settings, you can use the following example:
  - please note, that Excludes must be used for settings Folder, otherwise it will be deleted on every run, and copied new.

  ```json
  "SourcePaths":  [
                      "./",
                      "T:\\zz_bkp_setings_folder"
                  ],
  "TargetPaths":  [
                      "T:\\myAppBackupFolder\\",
                      "T:\\myAppBackupFolder\\settings\\"
                  ],
  "makeNewFolderIfNotExist":  true,

  ```

  if those parameters are not in the BackupSettings.json, the script will use the old Settings:

  - SourcePaths: "./" (means the script folder)
 
### V1.3.2

- 19.09.2022 - Bugfix script crash on target with whitespaces

### V1.3.1

- 18.09.2022 - Bugfix on no internet connection

### V1.3.0

- 17.09.2022 - Add aditional transscript to togfile and download actual version from GitHub

### V1.2.0

- 13.09.2022 - Add aditional BackupSettings.json

### V1.1.1

- 13.09.2022 - Bugfix on source as drive like s:\

### V1.1.0

- 13.09.2022 - Add robocopy option

### V1.0.0

- 03.08.2021 - initial release

<br>
<br>

---

## Donate

<table align="center" width="100%" border="0" bgcolor:=#3f3f3f>
<tr align="center">
<td align="center">  
if you prefer a one-time donation

[![donate-Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/FamilieRuhl)

</td>

<td align="center">  
Become a patron, by simply clicking on this button (**very appreciated!**):

[![Become a patron](https://c5.patreon.com/external/logo/become_a_patron_button.png)](https://www.patreon.com/join/6555448/checkout?ru=undefined)

</td>
</tr>
</table>

<br>
<br>

---

## Copyright

`2021-2023 (c)Vitaly Ruhl`

License: GNU General Public License v3.0
