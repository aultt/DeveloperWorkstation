configuration DeveloperWorkstation
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        [string]$datadriveLetter = 'F',
        [string]$TimeZone = "Eastern Standard Time",

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName StorageDsc -ModuleVersion 5.0.0
    Import-DscResource -ModuleName ComputerManagementdsc -ModuleVersion 8.2.0
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.4.1.0
   
    $domain = $DomainName.Split("{.}")[0]

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $True
            RefreshMode = "Push"
            ConfigurationMode = "ApplyOnly"
            ActionAfterReboot = 'ContinueConfiguration'
        }
        
        PowerShellExecutionPolicy 'ExecutionPolicy'
        {
            ExecutionPolicyScope = 'LocalMachine'
            ExecutionPolicy      = 'RemoteSigned'
        }

        WaitForDisk DataVolume{
            DiskId = 2
            RetryIntervalSec = 60
            RetryCount =60
        }

        Disk DataVolume{
            DiskId =  2
            DriveLetter = $datadriveLetter
            FSFormat = 'NTFS'
            AllocationUnitSize = 64kb
            DependsOn = '[WaitForDisk]DataVolume'
        }

        PowerPlan 'HighPerf'
        {
          IsSingleInstance = 'Yes'
          Name             = 'High performance'
        }

        TimeZone 'SetTimeZone'
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        Computer DomainJoin
        {
            Name       = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $AdminCreds
        }
        
        Group Admin
        {
            GroupName = 'Administrators'
            Ensure = 'Present'
            Credential =  $AdminCreds
            MembersToInclude = @("$($domain)\DBA")

            DependsOn = '[Computer]DomainJoin'
            PsDscRunAsCredential = $AdminCreds
        }

        cChocoInstaller InstallChoco
        {
            InstallDir = "${datadriveletter}:\choco"

            DependsOn = '[Computer]DomainJoin','[Disk]DataVolume'
        }
        
        cChocoPackageInstaller installAzureDataStudio
        {
            Name                 = 'azure-data-studio'
            Ensure               = 'Present'
            DependsOn            = '[cChocoInstaller]installChoco'
        }
        cChocoPackageInstaller installAzureDataStudioExt1
        {
            Name                 = 'azure-data-studio-sql-server-admin-pack'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]installAzureDataStudio'
        }
        cChocoPackageInstaller installAzureDataStudioExt2
        {
            Name                 = 'azuredatastudio-powershell'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]installAzureDataStudio'
        }
        cChocoPackageInstaller azcopy
        {
            Name                 = 'azcoyp10'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]installAzureDataStudio'
        }
        cChocoPackageInstaller sqlservermgmtstudio
        {
            Name                 = 'sql-server-management-studio'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]installAzureDataStudio'
        }
        cChocoPackageInstaller vscode
        {
            Name                 = 'vscode'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]installAzureDataStudio'
        }
        cChocoPackageInstaller vscodemssql
        {
            Name                 = 'vscode-mssql'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]vscode'
        }
        cChocoPackageInstaller vscodepowershell
        {
            Name                 = 'vscode-powershell'
            Ensure               = 'Present'
            DependsOn            = '[cChocoPackageInstaller]vscode'
        }
    }
}

$ConfigData = @{
    AllNodes = @(
    @{
        NodeName = 'localhost'
        PSDscAllowPlainTextPassword = $true
    }
    )
}

# $AdminCreds = Get-Credential

# DeveloperWorkstation -DomainName demolab.local -Admincreds $AdminCreds -Verbose -ConfigurationData $ConfigData -OutputPath C:\Packages\Plugins\Microsoft.Powershell.DSC\2.80.0.0\DSCWork\DeveloperWorkstation.0\DeveloperWorkstation

# Start-DscConfiguration -wait -Force -Verbose -Path C:\Packages\Plugins\Microsoft.Powershell.DSC\2.80.0.0\DSCWork\DeveloperWorkstation.0\DeveloperWorkstation


 
 
