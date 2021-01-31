
<#**********************************************************************************************************************

    **********************************************************************************************************************
    
    Funktion: Skeleton.ps1
    ______________________________________________________________________________________________________________________
    
    Version  Datum           Author        Beschreibung
    -------  ----------      -----------   -----------
	V1.0.0     13.05.2020      Vitaly Ruhl   Erstellungsversion 
	V1.0.1     18.06.2020      Vitaly Ruhl   bereinigen 
    
    Funktionsbeschreibung:
    Windows-Cron (Aufgabenplaner) für BackupII registrieren
    **********************************************************************************************************************
#>

#**********************************************************************************************************************
#Einstellungen
	$ErrorActionPreference = "Continue" #Fehlerbehandlung im Skript - Bei Fehler einfach mal weitergehen, aber Fehler ausgeben....(Möglich:Ignore,SilentlyContinue,Continue,Stop,Inquire) 
	$debug = $false # $true $false

	$NewTaskName = 'HerBackupII-Datei-Sicherungen V1.0.1'
	$CronTriggerScript = '"F:\Programmierung\__Auto-Backups__\FileSicherung.ps1"'
	
	# Trigger einstellen (Grund)
	#$dtv =  get-date ((Get-Date).tostring('dd.MM.yyyy') + ' 03:00:00') # in die Vergangenheit damit zum Test sofortausführung und natürlich nachts wegen Datenmänge... --> geht leider nicht???
	$trig    = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At 3am

	# trigger verkleinern
	#$trig2   = New-ScheduledTaskTrigger -Once -At (Get-date) -RepetitionDuration  (New-TimeSpan -Days 1)  -RepetitionInterval  (New-TimeSpan -Minutes 1)
	#$trig.Repetition = $trig2.Repetition

#**********************************************************************************************************************


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                    # Div Funktionen
#region begin Diverse
	#nicht benötigte wegen Performance entfernen....
	function whr ()	{Write-Host "`r`n`r`n"}
	
	function trenn ($text)
	{
		whr #-ForegroundColor Yellow
		Write-Host '-----------------------------------------------------------------------------------------------'# -ForegroundColor Yellow
		Write-Host "      $text" #-ForegroundColor Yellow
		whr #-ForegroundColor Yellow
	}
	
	function trennY ($text)
	{
		whr -ForegroundColor Yellow
		Write-Host '-----------------------------------------------------------------------------------------------' -ForegroundColor Yellow
		Write-Host "      $text" -ForegroundColor Yellow
		whr -ForegroundColor Yellow
	}
	
	function Get-ScriptDirectory #Rückgabe vollstondiger Pfad zum Skript
	{
		<#
			#Beispiel...
			$InstallPath = Get-ScriptDirectory #Pfad wo der Skript ist
		#>
		$Invocation = (Get-Variable MyInvocation -Scope 1).Value
		Split-Path $Invocation.MyCommand.Path
	}

#endregion
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#**********************************************************************************************************************
#**********************************************************************************************************************
# 									Hauptprogramm

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


#Erstaufruf feststellen...
$EF = Get-ScheduledTask | Where-Object TaskName -eq $NewTaskName -ErrorAction SilentlyContinue

if ($EF)
{
    trenn "die Windows-Aufgabe [$NewTaskName] existiert bereits...  --> Skript überspringen..."
}

else
{
#<#
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #auskommentieren, wenn Skript mit Admin-Rechten laufen soll!!!
    #region begin AdminRechteAnfordern
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
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# #>  
	set-executionpolicy remotesigned -force -ErrorAction SilentlyContinue
    
	#Eventlog-Bereich "Hermes" anlegen - hier werden die Events (Fehler und Hinweise) bei der Erstellung des Crons abgespeichert
	if ($s=Get-WinEvent -ListLog HERMES -ErrorAction SilentlyContinue) 
	{ 
		if ($debug) {Write-Host "eventlog existiert bereits [$s]"}
	} 
	else 
	{
		New-EventLog -Source "HERMES" -LogName "HERMES"
	} 
	
	#Das eigentliche Anlen einer Aufgabe...	
	try 
	{
		#cronjob anlegen...
		$username = "$env:USERDOMAIN\$env:USERNAME" #current user
		$cred = Get-Credential $username #Passwort abfragen (wichtig später für Ausführung des Cron mit Adminrechten)
		$Password = $cred.GetNetworkCredential().Password #Passwort in Klartext Zwischenspeichern, leider kann Aufgabenplaner nicht den Secure-PW benutzen

		$action  = New-ScheduledTaskAction -WorkingDirectory $env:TEMP -Execute $env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe -Argument "-command & $CronTriggerScript"
		$conf    = New-ScheduledTaskSettingsSet -WakeToRun #-RunOnlyIfIdle
		$STPrincipal = New-ScheduledTaskPrincipal -RunLevel Highest -User $username #-Password $Password 
		$MyTask =  New-ScheduledTask -Action $action -Settings $conf -Trigger $trig -Principal $STPrincipal 
		Register-ScheduledTask $NewTaskName -TaskPath "\HERMES" -InputObject $MyTask -User $username -Password $Password -Force 
		Write-EventLog -LogName 'HERMES' -Source 'HERMES' -EventID 1111 -EntryType Information -Message "Windowsaufgabe '$NewTaskName' angelegt von '$CronTriggerScript'"
	}

	catch
	{
		$errText = "Windowsaufgabe '$NewTaskName' --> Anlegen der Aufgabe Fehlgeschlagen `r`n Fehler: $Error `r`n"
		if ($debug) {Write-Host $errText}
		Write-EventLog -LogName 'HERMES' -Source 'HERMES' -EventID 1111 -EntryType Error -Message $errText
	}

	finally
	{
		if ($debug) {Get-ScheduledTask | Where-Object TaskName -eq $NewTaskName }#nochmal anzeigen
	}


    
}

#Set-ExecutionPolicy -Scope Process Unrestricted

if ($debug) {
	trenn 'Skript ausgefuehrt!'
	Write-Host 'Wenn nichts rot, dann alles ok ;-)'
}

#pause














