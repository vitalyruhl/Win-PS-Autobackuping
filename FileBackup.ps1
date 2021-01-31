
<#**********************************************************************************************************************
		C:\Windows\System32\WindowsPowerShell\v1.0
    # **********************************************************************************************************************
    #
    #Funktion: FileBackup.ps1
    #______________________________________________________________________________________________________________________
    #
    #Version  Datum           Author        Beschreibung
    #-------  ----------      -----------   -----------
    #V1.0     20.02.2020      Vitaly Ruhl   Erstellungsversion 
	#V1.1     12.03.2020      Vitaly Ruhl   Erweitert, aufgeräumt
    #
    #Funktionsbeschreibung:
    # make File-Backup over robocopy from below selected Folder(s)
    # **********************************************************************************************************************
    #>

#**********************************************************************************************************************
#Settings
$ErrorActionPreference = "Continue" #Fehlerbehandlung im Skript - Bei Fehler einfach mal weitergehen, aber Fehler ausgeben....(Möglich:Ignore,SilentlyContinue,Continue,Stop,Inquire) 
$debug = $true # $true $false
$TransScriptPrefix = "Log_FileBackup-ps1__"
#**********************************************************************************************************************

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#region begin some Functions

function whr ()	{ Write-Host "`r`n`r`n" }
	
function trenn ($text) {
	whr #-ForegroundColor Yellow
	Write-Host '-----------------------------------------------------------------------------------------------'# -ForegroundColor Yellow
	Write-Host "      $text" #-ForegroundColor Yellow
	Write-Host " "
}

function log ($text){
	if ($debug) {
		Write-Host "(debug) - $text" -ForegroundColor Gray
	}	
}
	
function Get-ScriptDirectory { #Return complete Path from this script
	<#
		#Beispiel...
		$InstallPath = Get-ScriptDirectory #Pfad wo der Skript ist
	#>
	$Invocation = (Get-Variable MyInvocation -Scope 1).Value
	return Split-Path $Invocation.MyCommand.Path
}

function Add-Path($MyPath) { #get true if the Path exists, if not -> create it!!!
		<#
			Beispiel: 
			$Pfad="$env:TEMP\PS_Skript"
			Add-Path($Pfad)
		#>
	log("Add-Path - Path:" + $MyPath )
	if (!(Test-Path -path $MyPath -ErrorAction SilentlyContinue )) {
		
		if (!(Test-Path -Path $MyPath)) {# if not -> create it!!!
			#New-Item -Path $MyPath -ItemType Directory -ErrorAction SilentlyContinue # | Out-Null
			New-Item -Path $MyPath -ItemType Directory # | Out-Null
		}      
	}
	return (Test-Path -path $MyPath -ErrorAction SilentlyContinue )
}
	
function Copy-mPath($Source, $Destination){

	if ((Test-Path $Source)){

		log("Copy-mPath - Source:" + $Source + " --> Destination:" + $Destination)
		
		if (Add-Path($Destination)){
			$cmd = 'robocopy "' + $Source +  '" "' + $Destination + '" /mir /w:10 /IPG:100'
			log($cmd)
			Invoke-Expression $cmd 
			
		}
		else{
			trenn " "
			Write-Host "Error biing copy from Source:" + $Source + " --> Destination:" + $Destination -ForegroundColor red
		}
	}
	else{
		trenn " "
		Write-Host "Error biing copy from Source:" + $Source + " --> Destination:" + $Destination -ForegroundColor red
		Write-Host "Source-Path does not exist" -ForegroundColor red
	}

}

#endregion

#**********************************************************************************************************************
#**********************************************************************************************************************
# MAIN
Clear-Host
trenn " "

#$PC  = $env:computername
$datum = Get-Date -Format yyyy.MM.dd_HHmm
$Source = Get-ScriptDirectory

if ($debug -or $true) 
{
	start-transcript "$Source\log\$TransScriptPrefix$(get-date -format yyyy-MM).txt"
	Write-Host "$datum [$connectionstring]"
}

#! ATENTION! do not use the same Destination-Path twice! Robocopy delete all data that the Sourcepath not contained!!!

Copy-mPath "\\192.168.2.205\_Scans_" ("E:\_Scans_") # Ordner Scans von der Nas auf PC sichern
Copy-mPath "D:\Eigene Dateien\Eigene Dateien Sweta\Buchhaltung" ("\\192.168.2.205\Buchhaltung\Buchhaltung") # Ordner Buchhaltung auf der NAS sichern
Copy-mPath "D:\Eigene Dateien\Eigene Dateien Sweta" ("\\192.168.2.205\Unsere_Dokummente\PC-Sicherung") # Ordner Buchhaltung auf der NAS sichern
Copy-mPath "D:\Eigene Dateien\Fotos Bilder\Eigene Fotos" ("\\192.168.2.205\Unsere_Bilder\Unsere Bilder") #Bilder in die NAS schieben
Copy-mPath "F:\Programmierung" ("\\192.168.2.205\Programmierung") # Ordner Programmierung auf der NAS sichern


if ($debug) {
	trenn 'Ready!'
	pause
}


if ($debug -or $true) {Stop-Transcript}
 
exit 




