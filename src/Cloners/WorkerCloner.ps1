function Copy-OctopusWorkers
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    if ($sourceData.HasWorkers -eq $false -or $destinationData.HasWorkers -eq $false)
    {
        Write-OctopusWarning "The source or destination Octopus instance doesn't have workers, skipping cloning workers"
        return
    }
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.WorkerList -itemType "Worker List" -filters $cloneScriptOptions.WorkersToClone

    if ($filteredList.length -eq 0)
    {
        return
    }

    if ($sourceData.OctopusUrl -ne $destinationData.OctopusUrl)
    {
        Write-OctopusCritical "You are cloning workers from one instance to another, the server thumbprints will not be accepted by the workers until you run Tentacle.exe configure --trust='your server thumbprint'"
    }

    foreach ($worker in $filteredList)
    {                              
        Write-OctopusVerbose "Starting Clone of Worker $($worker.Name)"

        if ($worker.Endpoint.CommunicationStyle -eq "TentacleActive")
        {
            Write-OctopusWarning "The worker $($worker.Name) is a polling tentacle, this script cannot clone polling tentacles, skipping."
            continue
        }
        
        $matchingItem = Get-OctopusItemByName -ItemName $worker.Name -ItemList $destinationData.WorkerList
                
        If ($null -eq $matchingItem)
        {            
            Write-OctopusVerbose "Worker $($worker.Name) was not found in destination, creating new record."                                        

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $worker -SpaceId $destinationData.SpaceId -ClearIdValue $true    

            $copyOfItemToClone.WorkerPoolIds = @(Get-OctopusFilteredWorkerPoolIdList -sourceData $sourceData -destinationData $destinationData -worker $worker)
            $copyOfItemToClone.MachinePolicyId = Convert-SourceIdToDestinationId -SourceList $sourceData.MachinePolicyList -DestinationList $destinationData.MachinePolicyList -IdValue $worker.MachinePolicyId
            $copyOfItemToClone.Status = "Unknown"
            $copyOfItemToClone.HealthStatus = "Unknown"
            $copyOfItemToClone.StatusSummary = ""
            $copyOfItemToClone.IsInProcess = $false

            if ($copyOfItemToClone.WorkerPoolIds.Length -eq 0)
            {
                Write-OctopusWarning "The worker $($worker.Name) is tied to a pool that is not allowed to be cloned and there are no other pools for it.  Skipping the worker."
                continue
            }

            Save-OctopusWorker -worker $copyOfItemToClone -destinationData $destinationData            
        }
        else 
        {
            Write-OctopusVerbose "Worker $($worker.Name) already exists in destination, skipping"    
        }
    }    

    Write-OctopusSuccess "Workers successfully cloned, reloading destination list"
    $destinationData.WorkerList = Get-OctopusWorkerList -OctopusData $DestinationData
}

function Get-OctopusFilteredWorkerPoolIdList
{
    param (
        $sourceData,
        $destinationData,
        $worker)
    
    $workerPoolIdsToReturn = @()

    foreach ($workerPoolId in $worker.WorkerPoolIds)
    {
        $workerPool = Get-OctopusItemById -itemList $sourceData.WorkerPoolList -itemId $workerPoolId
        if ($DestinationData.OctopusUrl -like "*.octopus.app" -and $SourceData.OctopusUrl -notlike "*.octopus.app" -and $workerPool.IsDefault -eq $true)
        {
            Write-OctopusVerbose "The worker is assigned to the default worker pool, but we are going from self-hosted to the cloud.  This is not allowed.  Removing this worker pool reference"
            continue
        }

        $destinationWorkerPoolId = Convert-SourceIdToDestinationId -SourceList $sourceData.WorkerPoolList -DestinationList $destinationData.WorkerPoolList -IdValue $workerPoolId            
        $workerPoolIdsToReturn += $destinationWorkerPoolId
    }

    return $workerPoolIdsToReturn
}