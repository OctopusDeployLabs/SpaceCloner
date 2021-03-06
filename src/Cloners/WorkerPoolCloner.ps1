function Copy-OctopusWorkerPools
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

    Write-OctopusChangeLog "Worker Pools"
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.WorkerPoolList -itemType "Worker Pool List" -filters $cloneScriptOptions.WorkerPoolsToClone

    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No Worker Pools found to clone matching the filters"
        return
    }

    foreach ($workerPool in $filteredList)
    {          
        if ((Test-OctopusObjectHasProperty -objectToTest $workerPool -propertyName "WorkerPoolType") -eq $true -and $workerPool.WorkerPoolType -eq "DynamicWorkerPool")                    
        {
            Write-OctopusVerbose "The worker pool $($workerPool.Name) is a dynamic worker pool, cannot clone these.  Skipping."
            continue
        }

        if ($DestinationData.OctopusUrl -like "*.octopus.app" -and $SourceData.OctopusUrl -notlike "*.octopus.app" -and $workerPool.IsDefault -eq $true)
        {
            Write-OctopusWarning "The source is self-hosted, the destination is Octopus Cloud, and the worker pool is the default.  Skipping."
            continue
        }

        Write-OctopusVerbose "Starting Clone of Worker Pool $($workerPool.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $workerPool.Name -ItemList $destinationData.WorkerPoolList
                
        If ($null -eq $matchingItem)
        {            
            Write-OctopusVerbose "Worker Pool $($WorkerPool.Name) was not found in destination, creating new record."  
            Write-OctopusChangeLog " - Add $($WorkerPool.Name)"
            
            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $workerpool -SpaceId $destinationData.SpaceId -ClearIdValue $true    

            $added = Add-PropertyIfMissing -objectToTest $copyOfItemToClone -propertyName "WorkerPoolType" -propertyValue "StaticWorkerPool"                  

            $newOctopusWorker = Save-OctopusWorkerPool -workerPool $copyOfItemToClone -destinationData $destinationData            
            $destinationData.WorkerPoolList += $newOctopusWorker
        }
        else 
        {
            Write-OctopusVerbose "Worker Pool $($workerPool.Name) already exists in destination, skipping"  
            Write-OctopusChangeLog " - $($WorkerPool.Name) already exists, skipping"  
        }
    }    

    Write-OctopusSuccess "Worker Pools successfully cloned"    
}