function Copy-OctopusTargets
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )    
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TargetList -itemType "target List" -filters $cloneScriptOptions.WorkersToClone

    if ($filteredList.length -eq 0)
    {
        return
    }

    if ($sourceData.OctopusUrl -ne $destinationData.OctopusUrl)
    {
        Write-OctopusCritical "You are cloning workers from one instance to another, the server thumbprints will not be accepted by the workers until you run Tentacle.exe configure --trust='your server thumbprint'"
    }    

    foreach ($target in $filteredList)
    {                              
        Write-OctopusVerbose "Starting Clone of target $($target.Name)"

        if ((Get-OctopusTargetCanBeCloned -target $target) -eq $false)
        {
            continue
        }
        
        $matchingItem = Get-OctopusItemByName -ItemName $target.Name -ItemList $destinationData.TargetList
                
        If ($null -eq $matchingItem)
        {            
            Write-OctopusVerbose "Target $($target.Name) was not found in destination, creating new record."                                        

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $target -SpaceId $destinationData.SpaceId -ClearIdValue $true    

            $copyOfItemToClone.EnvironmentIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $target.EnvironmentIds)  
            $copyOfItemToClone.TenantIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TenantList -DestinationList $DestinationData.TenantList -IdList $target.TenantIds)
            
            $copyOfItemToClone.MachinePolicyId = Convert-SourceIdToDestinationId -SourceList $sourceData.MachinePolicyList -DestinationList $destinationData.MachinePolicyList -IdValue $target.MachinePolicyId
            $copyOfItemToClone.Status = "Unknown"
            $copyOfItemToClone.HealthStatus = "Unknown"
            $copyOfItemToClone.StatusSummary = ""  
            
            Convert-OctopusCloudRegionTarget -target $copyOfItemToClone -sourceData $sourceData -destinationData $destinationData
            Convert-OctopusK8sTarget -target $copyOfItemToClone -sourceData $sourceData -destinationData $destinationData
            Convert-OctopusAzureWebAppTarget -target $copyOfItemToClone -sourceData $sourceData -destinationData $destinationData
            Convert-OctopusTargetTenantedDeploymentParticipation -target $copyOfItemToClone

            Save-OctopusTarget -target $copyOfItemToClone -destinationdata $destinationData            
        }
        else 
        {
            Write-OctopusVerbose "Target $($target.Name) already exists in destination, skipping"    
        }
    }    

    Write-OctopusSuccess "Targets successfully cloned, reloading destination list"
    $destinationData.TargetList = Get-OctopusTargetList -OctopusData $DestinationData
}

function Get-OctopusTargetCanBeCloned
{
    param ($target)
    
    if ($target.Endpoint.CommunicationStyle -eq "TentacleActive")
    {
        Write-OctopusWarning "The Target $($target.Name) is a polling tentacle, this script cannot clone polling tentacles, skipping."
        return $false
    }

    if ($target.EndPoint.CommunicationStyle -ne "None" -and $target.Endpoint.CommunicationStyle -ne "Kubernetes" -and $target.Endpoint.CommunicationStyle -ne "TentacleActive" -and $target.Endpoint.CommunicationStyle -ne "AzureWebApp")
    {
        Write-OctopusWarning "$($target.Name) is not going to be cloned, at this time this script supports cloud regions, K8s targets, listentin tentacles, and Azure Web Apps."
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

    $target.EndPoint.DefaultWorkerPoolId = Convert-SourceIdToDestinationId -SourceList $sourceData.WorkerPoolList -DestinationList $destinationData.WorkerPoolList -IdValue $target.EndPoint.DefaultWorkerPoolId
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

    if ($target.Endpoint.Authentication.AuthenticationType -eq "KubernetesAzure" -or $target.Endpoint.Authentication.AuthenticationType -eq "KubernetesAWS")
    {
        $target.EndPoint.Authentication.AccountId = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $target.EndPoint.Authentication.AccountId
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

    $target.EndPoint.AccountId = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $target.EndPoint.AccountId    
}

function Convert-OctopusTargetTenantedDeploymentParticipation
{
    param ($target)

    if ($target.TenantIds.Length -eq 0)
    {
        $target.TenantedDeploymentParticipation = "Untenanted"
    }
}