
<#**********************************************************************************************************************

    **********************************************************************************************************************
    
    Funktion: Skeleton.ps1
    ______________________________________________________________________________________________________________________
    
    Version  Datum           Author        Beschreibung
    -------  ----------      -----------   -----------
	V1.0.0     13.05.2020      Vitaly Ruhl   Erstellungsversion 
	V1.0.1     18.06.2020      Vitaly Ruhl   bereinigen 
    
    Funktionsbeschreibung:
    Windows-Cron (Aufgabenplaner) registrieren
    **********************************************************************************************************************
#>

#**********************************************************************************************************************
#Settings
	$ErrorActionPreference = "Continue" #Fehlerbehandlung im Skript - Bei Fehler einfach mal weitergehen, aber Fehler ausgeben....(Möglich:Ignore,SilentlyContinue,Continue,Stop,Inquire) 
	$debug = $false # $true $false

	$NewTaskName = 'FileBackup V1.0.1'
	$CronTriggerScript = '"F:\Programmierung\__Auto-Backups__\FileBackup.ps1"'
	
	# Set the Trigger
	$trig    = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Saturday -At 3am

#**********************************************************************************************************************


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#region begin some Functions

	function whr ()	{Write-Host "`r`n`r`n"}
	
	function trenn ($text)
	{
		whr #-ForegroundColor Yellow
		Write-Host '-----------------------------------------------------------------------------------------------'# -ForegroundColor Yellow
		Write-Host "      $text" #-ForegroundColor Yellow
		whr #-ForegroundColor Yellow
	}
		
	function Get-ScriptDirectory #Rückgabe vollstondiger Pfad zum Skript
	{
		<#
			#Beispiel...
			$InstallPath = Get-ScriptDirectory #Pfad wo der Skript ist
		#>
		$Invocation = (Get-Variable MyInvocation -Scope 1).Value
		return Split-Path $Invocation.MyCommand.Path
	}

#endregion
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#**********************************************************************************************************************
#**********************************************************************************************************************
# MAIN Functions

#$PC  = $env:computername #Aktuellen PC-Namen ermitteln

$datum = Get-Date -Format yyyy_MM_dd_HHmm
#$dt = Get-Date -Format yyyy_MM #_HHmm
$InstallPath = Get-ScriptDirectory #Pfad wo der Skript ist

if ($debug) 
{
    Clear-Host
    trenn " Debug aktiv "
    Write-Host ""
    Write-Host "Datum/Zeit        : [$datum]"
    Write-Host "Verzeichnis       : [$InstallPath]"
    Write-Host ""
}


#Check for Cron exists
$EF = Get-ScheduledTask | Where-Object TaskName -eq $NewTaskName -ErrorAction SilentlyContinue

if ($EF)
{
	trenn "The Windows-Task [$NewTaskName] exists...  --> Plese delete them manually and run again..."
	Pause
	return
}

else
{
#<#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#region begin Force Admin-Rights
		#https://www.heise.de/ct/hotline/PowerShell-Skript-mit-Admin-Rechten-1045393.html
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $princ = New-Object System.Security.Principal.WindowsPrincipal($identity)
        if(!$princ.IsInRole( `
           [System.Security.Principal.WindowsBuiltInRole]::Administrator))
        {
          $powershell = [System.Diagnostics.Process]::GetCurrentProcess()
          $psi = New-Object System.Diagnostics.ProcessStartInfo $powerShell.Path
          $script = $MyInvocation.MyCommand.Path
          $prm = $script
          foreach($a in $args) {
            $prm += ' ' + $a
          }
          $psi.Arguments = $prm
          $psi.Verb = "runas"
          [System.Diagnostics.Process]::Start($psi) | Out-Null
          return;
        }
    #endregion
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#> 
  
	#set-executionpolicy remotesigned -force -ErrorAction SilentlyContinue
    
	# create Eventlog-Group "MyBackups" if Exists
	if ($s=Get-WinEvent -ListLog MyBackups -ErrorAction SilentlyContinue) 
	{ 
		if ($debug) {Write-Host "eventlog really exists [$s]"}
	} 
	else 
	{
		New-EventLog -Source "MyBackups" -LogName "MyBackups"
	} 
	
	try 
	{
		#Create CronJob ...
		$username = "$env:USERDOMAIN\$env:USERNAME" #current user
		$cred = Get-Credential $username #get Password -> be sure the User has Admin Rights!
		$Password = $cred.GetNetworkCredential().Password #store temporaly Password in clear text -> Windows Task-Manager dont accept crypted keys

		$action  = New-ScheduledTaskAction -WorkingDirectory $env:TEMP -Execute $env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe -Argument "-command & $CronTriggerScript"
		$conf    = New-ScheduledTaskSettingsSet -WakeToRun #-RunOnlyIfIdle
		$STPrincipal = New-ScheduledTaskPrincipal -RunLevel Highest -User $username #-Password $Password 
		$MyTask =  New-ScheduledTask -Action $action -Settings $conf -Trigger $trig -Principal $STPrincipal 
		Register-ScheduledTask $NewTaskName -TaskPath "\MyBackups" -InputObject $MyTask -User $username -Password $Password -Force 
		Write-EventLog -LogName 'MyBackups' -Source 'MyBackups' -EventID 1111 -EntryType Information -Message "Windows-Cron '$NewTaskName' crated from '$CronTriggerScript'"
	}

	catch
	{
		$errText = "Windows-Cron '$NewTaskName' --> creation failed `r`n Error: $Error `r`n"
		if ($debug) {Write-Host $errText}
		Write-EventLog -LogName 'MyBackups' -Source 'MyBackups' -EventID 1111 -EntryType Error -Message $errText
	}

	finally
	{
		if ($debug) {Get-ScheduledTask | Where-Object TaskName -eq $NewTaskName } #Schow the creeated Task - when nothing to see --> get wrong!
	}


    
}

#Set-ExecutionPolicy -Scope Process Unrestricted

if ($debug) {
	trenn 'Ready!'
	pause
}

#pause














