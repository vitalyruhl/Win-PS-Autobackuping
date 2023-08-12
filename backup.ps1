
<#______________________________________________________________________________________________________________________

	(c) Vitaly Ruhl 2021-2022
    Homepage: Vitaly-Ruhl.de
    Github:https://github.com/vitalyruhl/Win-PS-Autobackuping
    License: GNU General Public License v3.0
______________________________________________________________________________________________________________________#>

$Funktion = 'backup.ps1'

  
<#______________________________________________________________________________________________________________________    
    		Version  	Datum           Author        Beschreibung
    		-------  	----------      -----------   -----------                                                       #>

$Version = 100 #	03.08.2021		Vitaly Ruhl		init
$Version = 110 #	13.09.2022		Vitaly Ruhl		Add Robocopy Option
$Version = 111 #	13.09.2022		Vitaly Ruhl		Bugfix on source as drive like s:\
$Version = 120 #	13.09.2022		Vitaly Ruhl		Add aditional BackupSettings.json 
$Version = 130 #	17.09.2022		Vitaly Ruhl		Add aditional Transscript to Logfile and download actual Version from Github 
$Version = 131 #	17.09.2022		Vitaly Ruhl		Bugfix on no Internet Connection 
$Version = 132 #	19.09.2022		Vitaly Ruhl		Bugfix script crash on target with whitespaces  
$Version = 140 #	16.04.2023		Vitaly Ruhl		Add multiple source and target support  
$Version = 141 #	07.08.2023		Vitaly Ruhl		Bugfix exclude files to  
$Version = 142 #	12.08.2023		Vitaly Ruhl		Own Parameterset for File-Exclusion 
$Version = 150 #	12.08.2023		Vitaly Ruhl		Rename UseCoherentBackup Parameter - its confuse and make some deleteon on target 


<#______________________________________________________________________________________________________________________
    Function:
    Make backup of all Files in contained folder, except exclusions...
______________________________________________________________________________________________________________________#>


<#______________________________________________________________________________________________________________________
    To-Do / Errors:
        03.08.2021 Exclusion don't work with compressing -> its copy all files (not implemented yet)
______________________________________________________________________________________________________________________#>


#**********************************************************************************************************************
# Settings
[bool]$AdminRightsRequired = $false #set $true, if Admin-Rights are for the Script reqired
$Prefix = '' #'zzz_' #Prefix of Backup-Folder

#$AD = Get-Date -Format yyyy.MM.dd_HH-mm
$Sufix = '' #"_Bakup_$AD"  #Sufix of Backup-Folder
    
# Result: zzz_ContainedFolder_Bakup_2021.08.03_22-18

[bool]$CompressIntoTargetPaths = $false # Save compressed file instead of uncompressed Folder !! Not with Option UseRobocopy !!

# 13.09.2022 Robocopy Region
[bool]$UseRobocopy = $true 
$Parameter = "/J /MIR /R:2 /W:1 /NP" 
$excludeParameter = '' # '/XD D:\`$RECYCLE.BIN "System Volume Information" "RECYCLER"' #/XD exclude-fold* | /XF "C:\source\folder\path\to\folder\filename.extension"
# end Robocopy Region


#**********************************************************************************************************************


#region Debugging Functions

#**********************************************************************************************************************
# Debug Settings
[bool]$global:debug = $false # $true $false
[bool]$global:debugTransScript = $false # $true $false
$global:DebugPrefix = $Funktion + ' ' + $Version + ' -> ' #Variable für Debug-log vorbelegen
$global:TransScriptPrefix = "Log_" + $Funktion + '_' + $Version
$global:Modul = 'Main' #Variable für Debug-log vorbelegen
$ErrorActionPreference = "Continue" #(Ignore,SilentlyContinue,Continue,Stop,Inquire) 
$global:DebugPreference = if ($global:debug) { "Continue" } else { "SilentlyContinue" } #Powershell-Own Debug settings
#**********************************************************************************************************************

function SetDebugState ($b) {
    $global:DebugPreference = if ($b) { "Continue" } else { "SilentlyContinue" } #Powershell-Own Debug settings
}

function section ($text) {
    Write-Host "`r`n-----------------------------------------------------------------------------------------------"
    Write-Host " $text"
    Write-Host "`r`n"
}
	
function sectionY ($text) {
    Write-Host "`r`n-----------------------------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host " $text" -ForegroundColor Yellow
    Write-Host "`r`n"
}
	
function log ($text) {
    if ($global:debug) {
        Write-Host "$global:DebugPrefix $global:Modul -> $text" -ForegroundColor DarkGray	
    }
}

function debug ($text) {
    if ($global:debug) {
        Write-debug "$global:DebugPrefix $global:Modul -> $text"# -ForegroundColor DarkGray
    }	
}

#endregion


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#region Some Functions

function compress($Source, $Target) {
    Write-Host 'Compressing...'
    #Add-Type -AssemblyName System.IO.Compression.FileSystem
    #$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    #[System.IO.Compression.ZipFile]::CreateFromDirectory($Source, $Target, $compressionLevel, $True)    

    if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) { throw "$env:ProgramFiles\7-Zip\7z.exe needed" } 
    set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  
    sz a -mx=9 "$Target" "$Source"
}


function start-countdown ($sleepintervalsec) {
    <#
			Use: start-countdown 60
		#>
    $ec = 0
    foreach ($step in (1..$sleepintervalsec)) {
        try {
            if ([console]::KeyAvailable) {
                $key = [system.console]::readkey($true)
                if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C")) {
                    Write-Warning "CTRL-C pressed" 
                    return
                }
                else {
                    Write-Host "Key Pressed [$($key.keychar)]"
                    pause
                    return
                }
            }
        }
        catch {
            if ($ec -eq 0) {
                Write-Warning "Start in Powershell ISE - console functions are not avaible"
                $ec++
            }
        }
        finally {
            $rest = $sleepintervalsec - $step
            write-progress -Activity "Please wait" -Status " $rest Sek..." -SecondsRemaining ($rest) -PercentComplete  ($step / $sleepintervalsec * 100)
            start-sleep -seconds 1
        }
    }
}

function Add-Path($MyPath) {
    #Checks path exists, otherwise creates a new one .....
    <#
               example: 
               $Pfad="$env:TEMP\PS_Skript"
               Add-Path($Pfad)
       #>
    $tempModul = $global:Modul # Save pre-text temporarily 
    $global:Modul = 'Add-Path'
   
    try {
           
        if (!(Test-Path -path $MyPath -ErrorAction SilentlyContinue )) {
            # Create Path if not exist
            if (!(Test-Path -Path $MyPath)) {
                New-Item -Path $MyPath -ItemType Directory -ErrorAction SilentlyContinue # | Out-Null
            }      
        }
   
    }
    catch { 
        Write-Warning "$global:Modul -  Something went wrong" 
    }	
    $global:Modul = $tempModul #restore old module text	
}	
function Get-ScriptDirectory() {
    $tempModul = $global:Modul # Save pre-text temporarily 
    $global:Modul = 'Get-ScriptDirectory'
    try {
        $Invocation = (Get-Variable MyInvocation -Scope 1).Value
        Split-Path $Invocation.MyCommand.Path
    }
    catch { 
        Write-Warning "$global:Modul -  Something went wrong" 
    }	
    $global:Modul = $tempModul #restore old module text	
}
	
if ($AdminRightsRequired) {
    log "get Adminrights... $AdminRightsRequired"
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ##https://www.heise.de/ct/hotline/PowerShell-Skript-mit-Admin-Rechten-1045393.html
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $princ = New-Object System.Security.Principal.WindowsPrincipal($identity)
    if (!$princ.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $powershell = [System.Diagnostics.Process]::GetCurrentProcess()
        $psi = New-Object System.Diagnostics.ProcessStartInfo $powerShell.Path
        $script = $MyInvocation.MyCommand.Path
        $prm = $script
        foreach ($a in $args) {
            $prm += ' ' + $a
        }
        $psi.Arguments = $prm
        $psi.Verb = 'runas'
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        return;
    }
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

}
#endregion




################################################################################################################################
#### MAIN PROGRAMM ###########
$global:Modul = 'Variable Settings'

#Region predefined Variable --> comes from BackupSettings.json, if included in the same folder

$TargetPaths = @(# An Array of Targets - Save all in more then 1 Backup
    'T:\myAppBackupFolder\'
)
    
$Excludes = @(# Working with LIKE operator -> can contains *,% etc...
    '*`$RECYCLE.BIN',
    "System Volume Information", 
    "RECYCLER"
)

$FileExcludes = @(# Working with LIKE operator -> can contains *,% etc...
    "*xvba_debug.log", # !!!!!#xvba_debug.log must be exclude from Backup. Otherwise crashes on own debug-files
    '*`$RECYCLE.BIN',
    "Thumbs.db"
)

$UpdateVersion = 0
[bool]$AllowUpdate = $false
$UpdateFromPath = "https://raw.githubusercontent.com/vitalyruhl/Win-PS-Autobackuping/master"
$UpdateFile = "backup.ps1"
$UpdateVersionFile = "VersionSettings.json"
$ScriptInPath = Get-ScriptDirectory #path where the script stored
$ProjectName = (get-item $ScriptInPath ).Name #only the Name of the Path
$SettingsFile = "$ScriptInPath\BackupSettings.json"
$currentDateTime = Get-Date -Format yyyy.MM.dd_HHmm

#16.04.2023 - new Variable 
$SourcePaths = @(# An Array of Sources - Backup all in more then 1 Source
    './'#current Path
)


# BUG: 12.08.2023 - Rename UseCoherentBackup Parameter - its confuse and make some deleteon on target
# $UseCoherentBackup = $false #if false, all SourcePaths will be backuped in one TargetPath
#                            # Note - only for UseRobocopy and TargetPath Must be diffrent!
$makeNewFolderIfNotExist = $true #if false, all SourcePaths will be backuped TargetPath + Foldername of SourcePath
                            # Note - if False, all files will be deleted in target, that not contained in source!

#endregion

   
function performSelfUpdate() {
    $global:Modul = 'update'
    log "Entry performSelfUpdate"
    $isUri = $false
    if ($UpdateFromPath -match "http") {
        #check if $UpdateFromPath contains a Uri
        $isUri = $true
    }
   
    #check version
    if ($isUri) {
        log "Update from Uri"
        try {$VersionJson = (Invoke-WebRequest -Uri "$UpdateFromPath/$UpdateVersionFile" -UseBasicParsing).Content | ConvertFrom-Json
            
        }
        catch {
            Write-Warning "Error in Update-Check - Check your Internet-Connection"
            return 
        }
           
    }
    # else {
    #     log "Update from Path"
    #     if ((Test-Path('"' + $UpdateFromPath + "\" + $UpdateFile + '"')) -And (Test-Path('"' + $UpdateFromPath + "\" + $UpdateVersionFile + '"'))) {
    #         $VersionJson = (Get-Content "`"$UpdateFromPath\$UpdateVersionFile`"" -Raw) | ConvertFrom-Json
    #     }
    # }

    $NewestVersion = $VersionJson.psobject.properties.Where({ $_.name -eq "CurrentVersion" }).value
    log "NewestVersion: $NewestVersion, UpdateVersion:  $NewestVersion"

    if ($UpdateVersion -lt $NewestVersion) {
                  
        try {
        log "Update from $UpdateVersion to $NewestVersion"
        if ($isUri) {
            log "Get files from Uri"
            #https://www.thomasmaurer.ch/2021/07/powershell-download-script-or-file-from-github/
            #Invoke-WebRequest -Uri https://raw.githubusercontent.com/thomasmaurer/demo-cloudshell/master/helloworld.ps1 -OutFile .\helloworld.ps1
            Invoke-WebRequest -Uri "$UpdateFromPath/$UpdateFile" -OutFile "$ScriptInPath\$UpdateFile"
        }
        else {
            log "Copy files from Path"
            copy-item "`"$UpdateFromPath\$UpdateFile`"" "`"$ScriptInPath\$UpdateFile`"" -force #-WhatIf
        }

        Log "Set New Version in actual Settings-Json"
        $json.UpdateVersion = $NewestVersion
        $json | ConvertTo-Json -depth 32 | set-content $SettingsFile
    
        sectionY "Update"
        Write-Warning "This script is updated now! Plese restart it again to perform your Backup"
        pause
        if ($global:debugTransScript) { Stop-Transcript }
        exit #exit this script
        }
        catch {
            Write-Warning "Error in Update-Check - Check your Settings or internet-Connection"
            if ($global:debugTransScript) { Stop-Transcript }
            return #exit this script
        }
    }
    return
}
      

$global:Modul = 'ENV'
#Check for BackupSettings.json and if it there fill the Variables
if (Test-Path($SettingsFile)) {
    $json = (Get-Content $SettingsFile -Raw) | ConvertFrom-Json
    #$json = ConvertFrom-Json (Get-Content $SettingsFile -Raw) -AsArray
    foreach ($var in $json.psobject.properties) {
        $valueInfo = $json.psobject.properties.Where({ $_.name -eq $var.name })
        $value = $json.psobject.properties.Where({ $_.name -eq $var.name }).value
        if ($valueInfo.TypeNameOfValue -eq "System.Boolean") {
            #16.04.2023 bugfix on bools
            #convert to bool
            $value = [bool]$value
        }
        if ($valueInfo.TypeNameOfValue -eq "System.Object[]") {
            #16.04.2023 bugfix on arrays with one element
            #convert to bool
            $value = @($value)
        }
        Set-Variable -Name $var.name -Value $value
        $logText = "Set-Variable " + $var.name + "-->[$value]"
        log $logText
    }
}

# Debugging session
if ($global:debug) {
   
    if ($global:debugTransScript) {
        start-transcript "`"$ScriptInPath\log\$TransScriptPrefix$(get-date -format yyyy-MM).txt`""
    }

    log "entry"
    log "module imported"
    $global:Modul = 'ENV'
    sectiony "ENV-Test"
    $PC = $env:computername

    
    #$DateTimeBeforeMonth = (get-date).AddDays(-30).ToString("yyy.MM.dd") 
    
    $ParentPath = (get-item $ScriptInPath ).parent.FullName #Path to this script one level up
    $Projekt = (get-item $ScriptInPath ).Name #Pathname only
    

    write-host "`r`n"
    $FM = @(	
        @{Name = "Hostname:"; Value = "[$PC]" }
        , @{Name = "Date/Time:"; Value = "[$currentDateTime]" }
        #, @{Name = "Date -30 days:";	    Value = "[$DateTimeBeforeMonth]" }
        , @{Name = "Script Pathfragment:"; Value = "[$Projekt]" }
        , @{Name = "Complete Path:"; Value = "[$ScriptInPath]" }
        , @{Name = "Parent Path:"; Value = "[$ParentPath]" }
    )
    $FM | ForEach-Object { [PSCustomObject]$_ } | Format-Table -Property Name, Value -AutoSize

    
    #start-countdown 10
}

#Clear-Host

SetDebugState($false)

log "`r`n`r`n"
log "AllowUpdate: $AllowUpdate"

if ($AllowUpdate) { performSelfUpdate } #only if the Settings-File is there and Update is allowed

$global:Modul = 'Main'

# 13.09.2022 Robocopy Region
$excludeParameter = "/XD " #Folders
$Excludes | ForEach-Object {
    $excludeParameter += '"' + $_ + '" '
}

$excludeParameter += " /XF " #Files 2023.08.07 Bugfix

$FileExcludes | ForEach-Object {
    $excludeParameter += '"' + $_ + '" '
}

$Excludes | ForEach-Object { log "Excludes: $_" }

# end Robocopy Region

if ($TargetPaths -eq 0) {
    $TargetPaths[0] = $ScriptInPath + $Prefix + '_' + $AktualDate + $Sufix #if target not Set -> save in Prevous Path
}

# 2022.09.14 viru Bugfix if there a : or \ taget path dosent accept this charakter
$ProjectName = $ProjectName -replace "[^a-zA-Z0-9_\-\.]", "" #clean $ProjectName from characters that are not allowed in a path

if ($SourcePaths[0] -eq './'){
    $SourcePaths[0] = $ScriptInPath
}
     
if ($UseRobocopy) {
    sectionY "use Robocopy..."
    Write-Host "Exclude This:[$excludeParameter]"

    if (!$makeNewFolderIfNotExist){
        debug "Use CoherentBackup"
        # This willdeleta all other files not contailned in source!!!
        if ($TargetPaths.Length -eq $SourcePaths.Length) {
            log "TargetPaths and SourcePaths are of same length"

            foreach ($i in 0..($SourcePaths.Length - 1)) {
                #log "[$($i+1)] in SourcePaths is $($SourcePaths[$i]) to Target:  is $($TargetPaths[$i])"
                $TP = $($TargetPaths[$i]) + "\" 
                $act = "robocopy `"$($SourcePaths[$i])`" `"$TP`" $Parameter $excludeParameter"
                log $act
                Invoke-Expression $act
    
            }
  
        }
        else {
            log "TargetPaths and SourcePaths are not of same length"
            Write-Error "------------------------------------------------------`r`n"
            Write-Error "When using Coherent Backup, you must have the same number of source and target paths!`r`n"
            Write-Error "Sources: $SourcePaths"
            Write-Error "Targets: $TargetPaths"
            Write-Error "------------------------------------------------------`r`n"
        }

    }
    else {
        debug "No Use CoherentBackup" # make a new folder if not exist and copy data there!
        foreach ( $TargetPath in $TargetPaths ) {
            foreach ( $SourcePath in $SourcePaths ) {
                $TP = $TargetPath + "\" + $Prefix + $ProjectName + $Sufix + "\"
                $act = "robocopy `"$SourcePath`" `"$TP`" $Parameter $excludeParameter"
                log $act
                Invoke-Expression $act
            }
        }    
    }
}

else {
    sectionY "use Powershell"
    sectionY "collecting, please wait..."
    Write-Host "Exclude This Files / Folder:" + $Excludes
    Write-Host "Save there: $TargetPaths[0]"
        
    if ($CompressIntoTargetPaths) {
        
        $TargetPaths | ForEach-Object { 
            Write-Host "Copying:" $_
            $zd = $_ + '\' + $Prefix + $ProjectName + $Sufix + '.7z'
            write-host "Save there: $zd"
            compress "`"$ScriptInPath`"" "`"$zd`""
        }  
    }
    else {
        # path-Exclusion found on: https://stackoverflow.com/questions/20412043/powershell-where-statement-notcontains
        $TP = ''
        Get-ChildItem -Path $ScriptInPath -Recurse -Force |
        where-Object { $path = $_.fullname; -not @($Excludes | 
                Where-Object { $path -like $_ -or $path -like "$_\*" }) } | 
        ForEach-Object {
                        
            foreach ( $TargetPath in $TargetPaths ) {

                $TP = '"' + $TargetPath + "\" + $Prefix + $ProjectName + $Sufix + "\" + '"'

                try {
                    if (! $_.PSIsContainer) {     
                        Write-Host "Copying:" $_.FullName " in :" $TP  -ForegroundColor Green
                        copy-item $_.FullName -Destination $_.FullName.Replace($ScriptInPath, $TP) -Recurse -force # -WhatIf
                    }                     
                    else {
                        Write-Host "Add Path:" $_.FullName.Replace($ScriptInPath , $TP) -ForegroundColor yellow
                        Add-Path($_.FullName.Replace($ScriptInPath, $TP))
                    }
                }
                catch { 
                    Write-Warning "$global:Modul -  Something went wrong on $_" 
                }
            }
        }
    }
}    
#endregion


#$FilesObject | ConvertTo-Json
Write-Host "`r`n`r`n"
Write-Warning "------------------------------------------------------`r`n"
Write-Warning 'Skript is done!'
Write-Warning "When you don't see any red than is all fine ;-)"
    
if ($global:debugTransScript) { Stop-Transcript }

if ($global:debug) {
    pause
}
else {
    start-countdown 30
}

