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

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.WorkerPoolList -itemType "Worker Pool List" -filters $cloneScriptOptions.WorkerPoolsToClone

    if ($filteredList.length -eq 0)
    {
        return
    }

    foreach ($workerPool in $filteredList)
    {                              
        Write-OctopusVerbose "Starting Clone of Worker Pool $($workerPool.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $workerPool.Name -ItemList $destinationData.WorkerPoolList
                
        If ($null -eq $matchingItem)
        {            
            Write-OctopusVerbose "Worker Pool $($WorkerPool.Name) was not found in destination, creating new record."                                        

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $workerpool -SpaceId $destinationData.SpaceId -ClearIdValue $true    

            Add-PropertyIfMissing -objectToTest $copyOfItemToClone -propertyName "WorkerPoolType" -propertyValue "StaticWorkerPool"                  

            Save-OctopusWorkerPool -workerPool $copyOfItemToClone -destinationData $destinationData            
        }
        else 
        {
            Write-OctopusVerbose "Worker Pool $($workerPool.Name) already exists in destination, skipping"    
        }
    }    

    Write-OctopusSuccess "Worker Pools successfully cloned, reloading destination list"
    $destinationData.WorkerPoolList = Get-OctopusWorkerPoolList -OctopusData $DestinationData
}