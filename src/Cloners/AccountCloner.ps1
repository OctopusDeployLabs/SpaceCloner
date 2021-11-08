function Copy-OctopusInfrastructureAccounts
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.InfrastructureAccounts -itemType "Infrastructure Accounts" -filters $cloneScriptOptions.InfrastructureAccountsToClone

    Write-OctopusChangeLog "Infrastructure Accounts"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No accounts found to clone matching the filters"
        return
    }

    Write-OctopusPostCloneCleanUpHeader "*************Starting Infrastructure Accounts*************"
    foreach($account in $filteredList)
    {             
        $matchingAccount = Get-OctopusItemByName -ItemName $account.Name -ItemList $DestinationData.InfrastructureAccounts

        if ($null -eq $matchingAccount)
        {
            Write-OctopusVerbose "The account $($account.Name) does not exist.  Creating it."
            Write-OctopusChangeLog " - Add $($account.Name)"

            $accountClone = Copy-OctopusObject -ItemToCopy $account -ClearIdValue $true -SpaceId $DestinationData.SpaceId

            Write-OctopusVerbose "Attempting to match Account Environment Ids to the destination"
            $newEnvironmentIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $accountClone.EnvironmentIds -MatchingOption $CloneScriptOptions.InfrastructureEnvironmentScopingMatch -IdListName "$($account.Name) Environment Scoping"
            if ($newEnvironmentIds.CanProceed -eq $false)
            {
                continue
            }
            $accountClone.EnvironmentIds = @($newEnvironmentIds.NewIdList)  

            Write-OctopusVerbose "Attempting to match Account Tenant Ids to the destination"
            $newTenantIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TenantList -DestinationList $DestinationData.TenantList -IdList $accountClone.TenantIds -MatchingOption $CloneScriptOptions.InfrastructureTenantScopingMatch -IdListName "$($account.Name) Tenant Scoping"
            if ($newTenantIds.CanProceed -eq $false)
            {
                continue
            }
            $accountClone.TenantIds = @($newTenantIds.NewIdList)
            
            Convert-OctopusAWSAccountInformation -accountClone $accountClone
            Convert-OctopusAzureServicePrincipalAccount -accountClone $accountClone
            Convert-OctopusTokenAccount -accountClone $accountClone                                
            Convert-OctopusAccountTenantedDeploymentParticipation -accountClone $accountClone   
            Convert-OctopusSSHAccount -accountClone $accountClone 
            Convert-OctopusAccountDescription -accountClone $accountClone -sourceData $sourceData   
            
            Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Environment Scoping" -idList $accountClone.EnvironmentIds -destinationList $DestinationData.EnvironmentList
            Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Tenant Scoping" -idList $accountClone.TenantIds -destinationList $DestinationData.TenantList

            $newInfrastructureAccount = Save-OctopusAccount -Account $accountClone -DestinationData $DestinationData            
            $destinationData.InfrastructureAccounts += $newInfrastructureAccount
            Write-OctopusPostCloneCleanUp "Account $($account.Name) was created with dummy values."
        }
        else
        {
            Write-OctopusVerbose "The account $($account.Name) already exists.  Skipping it."
            Write-OctopusChangeLog " - $($account.Name) already exists, skipping"
        }
    }
    Write-OctopusPostCloneCleanUpHeader "*************End Infrastructure Accounts*************"

    Write-OctopusSuccess "Infrastructure Accounts successfully cloned."         
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