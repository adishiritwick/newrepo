<#
    This script starts/pauses or restarts an Azure Synapse Analytics SQL Pool
    Pre-requirements:
                    AzModule ----> Install-Module -Name Az.Synapse
        
-	Serv
-	Operation: it needs to be Start/Pause or Restart#>

[CmdletBinding()]
param (
   [Parameter(Mandatory=$true)]
   [string]$ResourceGroupName ="",
   
   [Parameter(Mandatory=$true)]
   [string]$ServerName = "",

   [Parameter(Mandatory=$true)]
   [string]$DatabaseName = "",

   [Parameter(Mandatory=$true)]
   [string]$Operation = ""

)


Begin
    {     
    Write-Output "Connecting on $(Get-Date)"

    #######################################################################
    # If you are using an Automation Account, uncomment the following lines 
    #######################################################################
    
    #Connect to Azure using the Run As Account
    Try{
        $servicePrincipalConnection=Get-AutomationConnection -Name "AzureRunAsConnection"
        Connect-AzAccount  -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    Catch {
        if (!$servicePrincipalConnection){
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Output -Message $_.Exception
            throw $_.Exception
        }
    }
    
    #######################################################################
    # Finish Azure Automation Account Section
    #######################################################################


    # Validation parameters
    $ArrayOperations = "Pause","Start","Restart"

     If ($Operation -notin $ArrayOperations)
     {
           Throw "Only Pause, Start, Restart Operations are valid"
    }

    # Start
    Write-Output "Starting process on $(Get-Date)"

    Try{
        $Status = Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName -DatabaseName $DatabaseName | Select-Object Status | Format-Table -HideTableHeaders | Out-String 
        $Status = $Status -replace "`t|`n|`r",""
        Write-Output "The current status is "$Status.trim()" on $(Get-Date)" 
    }
    Catch {
            Write-Output $_.Exception
            throw $_.Exception
        }

    # Start block
    # Start
    Write-Output "Starting $Operation on $(Get-Date)"

        if(($Operation -eq "Start") -and ($Status.trim() -ne "Online")){
            Write-Output "Starting $Operation Operation"

                     try 
                    {  
                        Write-Output "Starting on $(Get-Date)"
                         Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName -DatabaseName $DatabaseName | Resume-AzSqlDatabase
                    }
                    catch
                    {
                        Write-Output "Error while executing "$Operation
                    }

  
        }
    # Pause block
        if(($Operation -eq "Pause") -and ($Status.trim() -ne "Paused")){
            write-Output "Starting $Operation Operation"

                      try 
                    {  
                        Write-Output "Pausing on $(Get-Date)"
                        Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName -DatabaseName $DatabaseName | Suspend-AzSqlDatabase
                    }
                    catch
                    {
                         Write-Output "Error while executing "$Operation
                    }

  
        }
        # Restart block
        if(($Operation -eq "Restart") -and ($Status.trim() -eq "Online")){
            Write-Output "Starting $Operation Operation"

                    try 
                    {  
                        Write-Output "Pausing on $(Get-Date)"
                        Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName -DatabaseName $DatabaseName | Suspend-AzSqlDatabase

                        Write-Output "Starting on $(Get-Date)"
                        Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName -DatabaseName $DatabaseName | Resume-AzSqlDatabase
                    }
                    catch
                    {
                        Write-Output "Error while executing "$Operation
                    }


  
        }
    }
End
{
    # Exit
    Write-Output "Finished process on $(Get-Date)"
}
