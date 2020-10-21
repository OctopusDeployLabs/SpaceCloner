function Copy-OctopusInfrastructureAccounts
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.InfrastructureAccounts -itemType "Infrastructure Accounts" -filters $cloneScriptOptions.InfrastructureAccountsToClone

    if ($filteredList.length -eq 0)
    {
        return
    }

    Write-OctopusPostCloneCleanUpHeader "*************Starting Infrastructure Accounts*************"
    foreach($account in $filteredList)
    {             
        $matchingAccount = Get-OctopusItemByName -ItemName $account.Name -ItemList $DestinationData.InfrastructureAccounts

        if ($null -eq $matchingAccount)
        {
            Write-OctopusVerbose "The account $($account.Name) does not exist.  Creating it."

            $accountClone = Copy-OctopusObject -ItemToCopy $account -ClearIdValue $true -SpaceId $DestinationData.SpaceId

            $accountClone.EnvironmentIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $accountClone.EnvironmentIds)  
            $accountClone.TenantIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TenantList -DestinationList $DestinationData.TenantList -IdList $accountClone.TenantIds)
            
            Convert-OctopusAWSAccountInformation -accountClone $accountClone
            Convert-OctopusAzureServicePrincipalAccount -accountClone $accountClone
            Convert-OctopusTokenAccount -accountClone $accountClone                                
            Convert-OctopusAccountTenantedDeploymentParticipation -accountClone $accountClone   
            Convert-OctopusSSHAccount -accountClone $accountClone 
            Convert-OctopusAccountDescription -accountClone $accountClone -sourceData $sourceData                   

            Save-OctopusAccount -Account $accountClone -DestinationData $DestinationData            
            Write-OctopusPostCloneCleanUp "Account $($account.Name) was created with dummy values."
        }
        else
        {
            Write-OctopusVerbose "The account $($account.Name) already exists.  Skipping it."
        }
    }
    Write-OctopusPostCloneCleanUpHeader "*************End Infrastructure Accounts*************"

    Write-OctopusSuccess "Infrastructure Accounts successfully cloned, reloading destination list"    
    $destinationData.InfrastructureAccounts = Get-OctopusInfrastructureAccountList -OctopusData $DestinationData
}

function Convert-OctopusAWSAccountInformation
{
    param ($accountClone)

    if ($accountClone.AccountType -ne "AmazonWebServicesAccount")
    {
        return
    } 
    
    $accountClone.SecretKey.HasValue = $false
    $accountClone.SecretKey.NewValue = "DUMMY VALUE DUMMY VALUE"    
}

function Convert-OctopusAzureServicePrincipalAccount
{
    param ($accountClone)

    if ($accountClone.AccountType -ne "AzureServicePrincipal")
    {
        return
    }

    $accountClone.Password.HasValue = $false
    $accountClone.Password.NewValue = "DUMMY VALUE DUMMY VALUE"    
}

function Convert-OctopusTokenAccount
{
    param ($accountClone)

    if($accountClone.AccountType -ne "Token")
    {
        return
    }

    $accountClone.Token.HasValue = $false
    $accountClone.Token.NewValue = "DUMMY VALUE"                    
}

function Convert-OctopusAccountTenantedDeploymentParticipation
{
    param ($accountClone)

    if ($accountClone.TenantIds.Length -eq 0)
    {
        $accountClone.TenantedDeploymentParticipation = "Untenanted"
    }
}

function Convert-OctopusSSHAccount
{
    param ($accountClone)

    if ($accountClone.AccountType -ne "SshKeyPair")
    {
        return
    }

    $accountClone.PrivateKeyFile.HasValue = $true
    $accountClone.PrivateKeyFile.NewValue = "VGVzdA=="
}

function Convert-OctopusAccountDescription
{
    param (
        $accountClone,
        $sourceData
        )

    if (Get-Member -InputObject $accountClone -Name "Description" -MemberType Properties)
    {
        $accountClone.Description = "$($accountClone.Description) Cloned from space $($sourceData.SpaceName) on $($sourceData.OctopusUrl).  Any keys/sensitive variables were set to DUMMY VALUE"
    }
}