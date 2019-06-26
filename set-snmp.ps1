<#
    .DESCRIPTION
        Script to modify SNMP settings

    .NOTES
        2/25/2019 - Added menu for cluster selection
        2/25/2019 - Removed SNMP Targets
        2/25/2019 - Staticly set $community variable
        2/27/2019 - v2.1 Rewrote Set SNMP to use esxcli -V2
#>

##################################################################################
# Script:           set-snmp.ps1
# Date:             2/25/2019
# Author:           Elihu J aka. virtualramblings (c) 2019
# Version:          2.1
##################################################################################

# Add the VMware Module
if (!(Get-Module VMware.VimAutomation.Core)) {
    Import-Module VMware.VimAutomation.Core
}

# Parameters
$outputdir = "C:\Support\snmp"
$date = Get-Date -Format M-d-yy

# Validate folders
If (Test-Path -Path $outputdir) {
} else {
New-Item -ItemType Directory -Path $outputdir
}

# Connect to vCenter
$vcenter = Read-Host “Enter vCenter FQDN“

Connect-VIServer -Server $vcenter

$serverlist = $global:DefaultVIServer

if ($serverlist -eq $null) {
    BREAK
    } else {
}

# Set SNMP variables
$community = Read-Host "SNMP Community Name"

# Run stuff
Do {
    Write-Host "`nPress 'm' to Modify SNMP or press 'q' to Quit`n"

    $input = Read-Host "Select"
    switch ($input){
        'm' {          
            
            Write-Host "`nHere are the clusters for $vcenter"
            # Create dynamic menu for Cluster selection
            $global:i=0
            $menu = Get-Cluster | Select @{Name="Line";Expression={$global:i++;$global:i}},Name
            $menu | Format-Table -AutoSize
            $r = Read-Host "Select cluster"
            $clsname = $menu | ? {$_.Line -eq "$r"} | Select -ExpandProperty Name

            # Get all hosts in vCenter managed Cluster so we can cycle thru them
            $hosts = Get-Cluster -Name $clsname | Get-VMHost

            ForEach ($vmhost in $hosts) {
            $esxcli = Get-EsxCli -VMHost $vmhost -V2

            # Modify SNMP
            $snmpargs = $esxcli.system.snmp.set.CreateArgs()
            $snmpargs.reset = "true"
            $snmpargs.enable = "true"
            $snmpargs.communities = $community
            $esxcli.system.snmp.set.Invoke($snmpargs)
            }

            # Output SNMP Settings
            $result = @()
            ForEach ($vmhost in $hosts) {

            # Get current SNMP settings
            $snmpget = $esxcli.system.snmp.get.Invoke()

            $result += [PSCustomObject] @{
                Hostname = $vmhost
                Enabled = "$($snmpget | Select -ExpandProperty Enable)" 
                Port = "$($snmpget | select -ExpandProperty Port)"
                Communities = "$($snmpget | Select -ExpandProperty Communities)"
                #Targets = "$($snmpget | Select -ExpandProperty Targets)"
                }
            $result | Out-File -FilePath "$outputdir\SNMP_$clsname-$date.txt"
            }
        Write-Host "`nSNMP Settings have been modified for $clsname. Settings have been exported to $outputdir\SNMP_$clsname-$date.txt`n" -BackgroundColor Black -ForegroundColor Green
    }
        'q' {

            # Exit the loop
            Write-Host "`nClosing connections"
            }
    }
} until($input -eq 'q')

# Disconnect from vCenter
Disconnect-VIServer * -Confirm:$false
