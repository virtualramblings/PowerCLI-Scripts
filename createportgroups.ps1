<#
    .DESCRIPTION
        Script to create port groups on vDS from CSV
    .NOTES
#>

##################################################################################
# Script:           createportgroups.ps1
# Date:             6/28/2019
# Author:           Elihu J aka. virtualramblings (c) 2019
# Version:          1.0
##################################################################################

# Add the VMware Module
if (!(Get-Module VMware.VimAutomation.Core)) {
    Import-Module VMware.VimAutomation.Core
}

# Parameters
$wrkdir = "C:\Support\portgroups"

# Connect to vCenter
$vcenter = Read-Host "Enter vCenter FQDN"

Connect-VIServer -Server $vcenter

Import-Csv $wrkdir\portgroups.csv | foreach {
    New-VDPortgroup -VDSwitch (Get-VDSwitch) -Name $_.name -VlanId $_.vlan
    }

# Disconnect from vCenter
Disconnect-VIServer * -Confirm:$false
