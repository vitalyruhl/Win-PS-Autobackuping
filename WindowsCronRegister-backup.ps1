
<#**********************************************************************************************************************

    **********************************************************************************************************************
    
    Funktion: Skeleton.ps1
    ______________________________________________________________________________________________________________________
    
    Version  Datum           Author        Beschreibung
    -------  ----------      -----------   -----------
	V1.0.0     13.05.2020      Vitaly Ruhl   Initial Version
	V1.0.1     18.06.2020      Vitaly Ruhl   Cleared Code 
	V1.0.2     18.09.2022      Vitaly Ruhl   Get source automaticly, Eventlog-Name changeble 
    
    Function:
    register Windows-Cron (Taskplaner)
    **********************************************************************************************************************
#>

#**********************************************************************************************************************
#Settings
	$ErrorActionPreference = "Continue" 
	$debug = $false # $true $false

	$NameEventLog = "MyBackups"
	$NewTaskName = 'FileBackup V1.0.1'
		# Set the Trigger weekly on Sunday at 03:00 am
	$trig    = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Saturday -At 3am

#**********************************************************************************************************************


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#region begin some Functions

	function whr ()	{Write-Host "`r`n`r`n"}
	
	function section ($text)
	{
		whr #-ForegroundColor Yellow
		Write-Host '-----------------------------------------------------------------------------------------------'# -ForegroundColor Yellow
		Write-Host "      $text" #-ForegroundColor Yellow
		whr #-ForegroundColor Yellow
	}
		
	function Get-ScriptDirectory { #Return complete Path from this script
		<#
			$InstallPath = Get-ScriptDirectory
		#>
		$Invocation = (Get-Variable MyInvocation -Scope 1).Value
		return Split-Path $Invocation.MyCommand.Path
	}

#endregion
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#**********************************************************************************************************************
#**********************************************************************************************************************
# MAIN Functions

#$PC  = $env:computername 

$currentDateTime = Get-Date -Format yyyy_MM_dd_HHmm
#$dt = Get-Date -Format yyyy_MM #_HHmm
$InstallPath = Get-ScriptDirectory 
$CronTriggerScript = "$InstallPath\Backup.ps1"
	

if ($debug) 
{
    Clear-Host
    section " Debug aktiv "
    Write-Host ""
    Write-Host "Datum/Zeit        : [$currentDateTime]"
    Write-Host "Verzeichnis       : [$InstallPath]"
    Write-Host ""
}


#Check for Cron exists
$EF = Get-ScheduledTask | Where-Object TaskName -eq $NewTaskName -ErrorAction SilentlyContinue

if ($EF)
{
	section "The Windows-Task [$NewTaskName] exists...  --> Plese delete them manually and run again..."
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
		New-EventLog -Source "$NameEventLog" -LogName "$NameEventLog"
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
		Register-ScheduledTask $NewTaskName -TaskPath "\$NameEventLog" -InputObject $MyTask -User $username -Password $Password -Force 
		Write-EventLog -LogName "$NameEventLog" -Source "$NameEventLog" -EventID 1111 -EntryType Information -Message "Windows-Cron '$NewTaskName' crated from '$CronTriggerScript'"
	}

	catch
	{
		$errText = "Windows-Cron '$NewTaskName' --> creation failed `r`n Error: $Error `r`n"
		if ($debug) {Write-Host $errText}
		Write-EventLog -LogName "$NameEventLog" -Source "$NameEventLog" -EventID 1111 -EntryType Error -Message $errText
	}

	finally
	{
		if ($debug) {Get-ScheduledTask | Where-Object TaskName -eq $NewTaskName } #Show the creeated Task - when nothing to see --> get wrong!
	}


    
}

#Set-ExecutionPolicy -Scope Process Unrestricted

if ($debug) {
	section 'Ready!'
	pause
}

#pause














