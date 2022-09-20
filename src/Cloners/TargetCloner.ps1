function Copy-OctopusTargets
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TargetList -itemType "Target List" -filters $cloneScriptOptions.TargetsToClone

    Write-OctopusChangeLog "Targets"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No targets found to clone matching the filters"
        return
    }

    foreach ($target in $filteredList)
    {
        Write-OctopusVerbose "Starting Clone of target $($target.Name)"

        if ((Get-OctopusTargetCanBeCloned -target $target) -eq $false)
        {
            Write-OctopusChangeLog " - $($target.Name) is unsupported target type, skipping"
            continue
        }

        $matchingItem = Get-OctopusItemByName -ItemName $target.Name -ItemList $destinationData.TargetList

        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "Target $($target.Name) was not found in destination, creating new record."
            Write-OctopusChangeLog " - Add $($target.Name)"

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $target -SpaceId $destinationData.SpaceId -ClearIdValue $true

            Write-OctopusVerbose "Attempting to match Target Environment Ids to the destination"
            $newEnvironmentIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $target.EnvironmentIds -MatchingOption $CloneScriptOptions.InfrastructureEnvironmentScopingMatch -IdListName "$($target.Name) Environments"
            if ($newEnvironmentIds.CanProceed -eq $false)
            {
                continue
            }
            $copyOfItemToClone.EnvironmentIds = @($newEnvironmentIds.NewIdList)  

            Write-OctopusVerbose "Attempting to match Target Tenant Ids to the destination"
            $newTenantIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TenantList -DestinationList $DestinationData.TenantList -IdList $target.TenantIds -MatchingOption $CloneScriptOptions.InfrastructureTenantScopingMatch -IdListName "$($target.Name) Tenants"
            if ($newTenantIds.CanProceed -eq $false)
            {
                continue
            }
            $copyOfItemToClone.TenantIds = @($newTenantIds.NewIdList)

            Write-OctopusVerbose "Attempting to match Account Tenant Ids to the destination"
            $newTenantTags = Convert-SourceTenantTagListToDestinationTenantTagList -tenantTagListToConvert $copyOfItemToClone.TenantTags -destinationDataTenantTagSets $destinationData.TenantTagList -matchingOption $CloneScriptOptions.InfrastructureTenantTagScopingMatch
            if ($newTenantTags.CanProceed -eq $false)
            {
                continue
            }
            $copyOfItemToClone.TenantTags = @($newTenantTags.NewIdList) 

            if ((Test-OctopusObjectHasProperty -objectToTest $target -propertyName "MachinePolicyId") -eq $true -and $null -ne $target.MachinePolicyId)
            {
                $copyOfItemToClone.MachinePolicyId = Convert-SourceIdToDestinationId -SourceList $sourceData.MachinePolicyList -DestinationList $destinationData.MachinePolicyList -IdValue $target.MachinePolicyId -ItemName "$($copyOfItemToClone.Name) Machine Policy" -MatchingOption "ErrorUnlessExactMatch"
            }

            Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Environment Scoping" -idList $copyOfItemToClone.EnvironmentIds -destinationList $DestinationData.EnvironmentList
            Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Tenant Scoping" -idList $copyOfItemToClone.TenantIds -destinationList $DestinationData.TenantList

            if ((Test-OctopusObjectHasProperty -objectToTest $copyOfItemToClone -propertyName "Status") -eq $true)
            {
               $copyOfItemToClone.Status = "Unknown"
            }

            $copyOfItemToClone.HealthStatus = "Unknown"
            $copyOfItemToClone.StatusSummary = ""

            Convert-OctopusCloudRegionTarget -target $copyOfItemToClone -sourceData $sourceData -destinationData $destinationData
            Convert-OctopusK8sTarget -target $copyOfItemToClone -sourceData $sourceData -destinationData $destinationData
            Convert-OctopusAzureWebAppTarget -target $copyOfItemToClone -sourceData $sourceData -destinationData $destinationData
            Convert-OctopusTargetTenantedDeploymentParticipation -target $copyOfItemToClone

            $newOctopusTarget = Save-OctopusTarget -target $copyOfItemToClone -destinationdata $destinationData
            $destinationData.TargetList = Update-OctopusList -itemList $destinationData.TargetList -itemToReplace $newOctopusTarget
        }
        else
        {
            Write-OctopusVerbose "Target $($target.Name) already exists in destination, skipping"
            Write-OctopusChangeLog " - $($target.Name) already exists, skipping"
        }
    }

    Write-OctopusSuccess "Targets successfully cloned."
    
}

function Get-OctopusTargetCanBeCloned
{
    param ($target)

    if ($target.Endpoint.CommunicationStyle -eq "TentacleActive")
    {
        Write-OctopusWarning "The Target $($target.Name) is a polling tentacle, this script cannot clone polling tentacles, skipping."
        return $false
    }

    if ($target.EndPoint.CommunicationStyle -ne "None" -and $target.Endpoint.CommunicationStyle -ne "Kubernetes" -and $target.Endpoint.CommunicationStyle -ne "TentaclePassive" -and $target.Endpoint.CommunicationStyle -ne "AzureWebApp")
    {
        Write-OctopusWarning "$($target.Name) is not going to be cloned, at this time this script supports cloud regions, K8s targets, listening tentacles, and Azure Web Apps."
        return $false
    }

    if ($target.Endpoint.CommunicationStyle -eq "Kubernetes")
    {
        if ($target.Endpoint.Authentication.AuthenticationType -eq "KubernetesStandard")
        {
            Write-OctopusWarning "Target $($target.Name) is a K8s cluster authentication using a certification, at this time this script cannot clone that."
            return $false
        }
    }

    return $true
}

function Convert-OctopusCloudRegionTarget
{
    param(
        $target,
        $sourceData,
        $destinationData)

    if ($target.Endpoint.CommunicationStyle -ne "None")
    {
        return
    }

    if ($null -eq $target.EndPoint.DefaultWorkerPoolId)
    {
        return
    }

    $target.EndPoint.DefaultWorkerPoolId = Convert-SourceIdToDestinationId -SourceList $sourceData.WorkerPoolList -DestinationList $destinationData.WorkerPoolList -IdValue $target.EndPoint.DefaultWorkerPoolId -ItemName "$($target.Name) Default Worker Pool" -MatchingOption "ErrorUnlessExactMatch"
}

function Convert-OctopusK8sTarget
{
    param(
        $target,
        $sourceData,
        $destinationData)

    if ($target.Endpoint.CommunicationStyle -ne "Kubernetes")
    {
        return
    }

    if ($target.Endpoint.Authentication.AuthenticationType -eq "KubernetesAzure" -or $target.Endpoint.Authentication.AuthenticationType -eq "KubernetesAWS" -or $target.Endpoint.Authentication.AuthenticationType -eq "KubernetesGCP")
    {
        $target.EndPoint.Authentication.AccountId = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $target.EndPoint.Authentication.AccountId -ItemName "$($target.Name) K8s Auth Account" -MatchingOption "ErrorUnlessExactMatch"
    }
}

function Convert-OctopusAzureWebAppTarget
{
    param(
        $target,
        $sourceData,
        $destinationData)

    if ($target.Endpoint.CommunicationStyle -ne "AzureWebApp")
    {
        return
    }

    $target.EndPoint.AccountId = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $target.EndPoint.AccountId -ItemName "$($target.Name) Azure Account" -MatchingOption "ErrorUnlessExactMatch"
}

function Convert-OctopusTargetTenantedDeploymentParticipation
{
    param ($target)

    if ($target.TenantIds.Length -eq 0)
    {
        $target.TenantedDeploymentParticipation = "Untenanted"
    }
}