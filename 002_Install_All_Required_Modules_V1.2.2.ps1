

#**********************************************************************************************************************

    #**********************************************************************************************************************
    #(c) HERMES Systeme GmbH                             Telefon: +49 (0) 4431 9360-0
    #    MSR & Automatisierungstechnik                   Telefax: +49 (0) 4431 9360-60
    #    Visbeker Str. 55                                E-Mail: info@hermes-systeme.de
    #   27793 Wildeshausen                              Home: www.hermes-systeme.de
    #______________________________________________________________________________________________________________________
    #
    #Function: alle wichtigen PS-Module installieren, solange noch die Internetverbindung bei der Einrichtung da ist
	#Sollte mit Admin-Rechten und Internetverbindung gestartet werden!
    #______________________________________________________________________________________________________________________
    #

    #**********************************************************************************************************************
    #Anderungsverlauf 
    #Version  Datum           Author        Beschreibung
    #-------  ----------      -----------   -----------                                         
    #V1.0.0   02.01.2020      ViRu          Skripterstellung
	#V1.1.0   26.02.2020      ViRu          exec. Pol und countdown hinzugefügt
    #V1.2.0   27.05.2020      ViRu          bugfix: bei Einigen älteren Versionen fehlt der neue Package-provider --> auch hinzufügen
    #V1.2.1   17.06.2020      ViRu          bugfix: ExecutionPolicy auf alle Scopes anwenden und forcen
    #V1.2.2   17.12.2020      ViRu          ein paar nützlich Module hinzugefügt und Pause anstatt countdown
    # 
    #********************************************************************************************************************** 



#**********************************************************************************************************************
#Einstellungen
$ErrorActionPreference = "Continue" #Fehlerbehandlung im Skript - Bei Fehler einfach mal weitergehen, aber Fehler ausgeben....(Möglich:Ignore,SilentlyContinue,Continue,Stop,Inquire) 
Set-Alias wh Write-Host # mann ist ja Faul so kann man abkürzen.... wh "Hello World!" 

#$debug = $false # $true $false

#**********************************************************************************************************************

# Offline installieren
# 1. wo es bereits istalliert ist modul exportieren (sehen kann mann so:[(Get-Module -ListAvailable sqls*).path])
#   1.1 save-module -name SqlServer -Path D:\Arbeiten\__Austausch_Tools\PowerShell\Diverses\offline-install
#   1.2 save-module -name NetAdapter -Path D:\Arbeiten\__Austausch_Tools\PowerShell\Diverses\offline-install


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                       # Div Funktionen

#nicht benötigte wegen Performance entfernen....
function whr ()	{Write-Host "`r`n`r`n"}
	
	function trenn ($text)
	{
		whr #-ForegroundColor Yellow
		wh '-----------------------------------------------------------------------------------------------'# -ForegroundColor Yellow
		wh "      $text" #-ForegroundColor Yellow
		whr #-ForegroundColor Yellow
	}
	
	function trennY ($text)
	{
		whr -ForegroundColor Yellow
		wh '-----------------------------------------------------------------------------------------------' -ForegroundColor Yellow
		wh "      $text" -ForegroundColor Yellow
		whr -ForegroundColor Yellow
	}
	
                                            # Div Funktionen
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




#**********************************************************************************************************************
#**********************************************************************************************************************
# Hauptprogramm

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

Clear-Host

#Execution-policy einstellen
set-executionpolicy remotesigned -force  -ErrorAction SilentlyContinue
Get-ExecutionPolicy -list |ForEach-Object {Set-ExecutionPolicy -scope $_.scope remotesigned -force -ErrorAction SilentlyContinue} #in allen scopes durchlaufen

trenn " --> Sicherstellen, dass der NuGet auf dem neusten Stand ist..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force


trenn " --> Modul für SQL-Server-Verwaltung und direkten Zugriff auf die Tabellen installieren..."
#install-module sqlps; #das ist die alte Version... falls die installiert ist muss die neue mit "-AllowClobber" ausgeführt werden!
try
{
    install-module SqlServer -AllowClobber
}
catch
{
    install-module SqlServer
}
finally
{
    import-module SqlServer
}



# ############# Optionale Module, die nicht wirklich nötig sind... ##############################
# ############# Die meisten sind ab Win10 1709 bereits automatisch mit dabei!  ##############################
<#

trenn " --> Modul für ntp installieren..."
install-module ntptime # -AllowClobber
Import-module ntptime


trenn " --> Modul für Windows-Update..."
install-module pswindowsupdate
import-module pswindowsupdate

import-module WindowsUpdate



trenn " --> Modul für RemoteAcces über PS..."
#install-module RemoteAccess
import-module RemoteAccess


trenn " --> Modul für Netzwerk-Administration..."
#install-module DnsClient
import-module DnsClient

#install-module DnsServer
import-module DnsServer

#install-module NetAdapter
import-module NetAdapter

#install-module NetTCPIP
import-module NetTCPIP

trenn " --> Modul für Netzwerk-Sicherheit installieren..."
#install-module NetSecurity # -AllowClobber
Import-module NetSecurity

trenn " --> Modul für Windows-Image..."
#install-module DISM
import-module DISM

trenn " --> Modul für Aufgabenplannung..."
#install-module ScheduledTasks
import-module ScheduledTasks

#>
	
trenn 'Skript ausgefuehrt!'
wh 'Wenn nichts rot, dann alles ok ;-)'

pause

<#
#**********************************************************************************************************************
#Div. Infos
#C:\Windows\System32\WindowsPowerShell\v1.0
#>

