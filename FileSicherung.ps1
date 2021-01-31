
<#**********************************************************************************************************************
		C:\Windows\System32\WindowsPowerShell\v1.0
    # **********************************************************************************************************************
    #
    #Funktion: FileSicherung.ps1
    #______________________________________________________________________________________________________________________
    #
    #Version  Datum           Author        Beschreibung
    #-------  ----------      -----------   -----------
    #V1.0     20.02.2020      Vitaly Ruhl   Erstellungsversion 
	#V1.1     12.03.2020      Vitaly Ruhl   Erweitert, aufgeräumt
    #
    #Funktionsbeschreibung:
    #HerBackupII FileSicherung über Cron -> hier die Filesicherung
    # **********************************************************************************************************************
    #>

#**********************************************************************************************************************
#Einstellungen
$ErrorActionPreference = "Continue" #Fehlerbehandlung im Skript - Bei Fehler einfach mal weitergehen, aber Fehler ausgeben....(Möglich:Ignore,SilentlyContinue,Continue,Stop,Inquire) 
$debug = $true # $true $false

#**********************************************************************************************************************

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Div Funktionen
#region begin Diverse
#nicht benötigte wegen Performance entfernen....
function whr ()	{ Write-Host "`r`n`r`n" }
	
function trenn ($text) {
	whr #-ForegroundColor Yellow
	Write-Host '-----------------------------------------------------------------------------------------------'# -ForegroundColor Yellow
	Write-Host "      $text" #-ForegroundColor Yellow
	whr #-ForegroundColor Yellow
}

function log ($text)
	{
		if ($debug) {
			Write-Host "(debug) - $text" -ForegroundColor Gray
		}
		
	}

function Add-Path($MyPath) { #Prüft, ob der Pfad vorhanden ist, sonnst erstellt einen neuen.....
	<#
			Beispiel: 
			$Pfad="$env:TEMP\PS_Skript"
			Add-Path($Pfad)
		#>
	log("Add-Path - Path:" + $MyPath )
	if (!(Test-Path -path $MyPath -ErrorAction SilentlyContinue )) {
		# Pfad anlegen wenn nicht vorhanden
		if (!(Test-Path -Path $MyPath)) {
			#New-Item -Path $MyPath -ItemType Directory -ErrorAction SilentlyContinue # | Out-Null
			New-Item -Path $MyPath -ItemType Directory # | Out-Null
		}      
	}
	return (Test-Path -path $MyPath -ErrorAction SilentlyContinue )
}

#endregion

#**********************************************************************************************************************
#**********************************************************************************************************************
# 									Hauptprogramm
Clear-Host
trenn " "
	
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
			Write-Host "Fehler beim Kopieren -> Source:" + $Source + " --> Destination:" + $Destination -ForegroundColor red
		}
	}
	else{
		trenn " "
		Write-Host "Fehler beim Kopieren -> Source:" + $Source + " --> Destination:" + $Destination -ForegroundColor red
		Write-Host "Source-Pfad existiert nicht" -ForegroundColor red
	}

}

#! ATENTION! do not use the same Destination-Path twice! Robocopy delete all data that the Sourcepath not contained!!!

Copy-mPath "D:\Eigene Dateien\Fotos Bilder\Eigene Fotos" ("\\192.168.2.205\Unsere_Bilder\Unsere Bilder") #Bilder in die NAS schieben
Copy-mPath "\\192.168.2.205\_Scans_" ("E:\_Scans_") # Ordner Scans von der Nas auf PC sichern
Copy-mPath "F:\Programmierung" ("\\192.168.2.205\Programmierung") # Ordner Programmierung auf der NAS sichern
Copy-mPath "D:\Eigene Dateien\Eigene Dateien Sweta\Buchhaltung" ("\\192.168.2.205\Buchhaltung\Buchhaltung") # Ordner Buchhaltung auf der NAS sichern
Copy-mPath "D:\Eigene Dateien\Eigene Dateien Sweta" ("\\192.168.2.205\Unsere_Dokummente\PC-Sicherung") # Ordner Buchhaltung auf der NAS sichern

trenn 'Skript ausgefuehrt!'
Write-Host 'Wenn nichts rot, dann alles ok ;-)'

pause
<##**********************************************************************************************************************
	#Div. Infos
	C:\Windows\System32\WindowsPowerShell\v1.0
#>





