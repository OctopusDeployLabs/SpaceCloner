function Copy-OctopusLifecycles
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.LifeCycleList -itemType "Lifecycles" -filters $cloneScriptOptions.LifeCyclesToClone

    if ($filteredList.length -eq 0)
    {
        return
    }
    
    foreach ($lifecycle in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of Lifecycle $($lifecycle.Name)"

        $matchingItem = Get-OctopusItemByName -ItemName $lifecycle.Name -ItemList $destinationData.LifeCycleList   

        if ($null -ne $matchingItem -and $CloneScriptOptions.OverwriteExistingLifecyclesPhases -eq $false)             
        {
            Write-OctopusVerbose "Lifecycle already exists and you selected not to overwrite phases, skipping"
            continue
        }        

        $lifeCycleToClone = Copy-OctopusObject -ItemToCopy $lifecycle -ClearIdValue $true -SpaceId $null  
        
        if ($null -ne $matchingItem)
        {
            $lifeCycleToClone.Id = $matchingItem.Id
        }

        foreach ($phase in $lifeCycleToClone.Phases)
        {            
            $phase.OptionalDeploymentTargets = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $phase.OptionalDeploymentTargets)
            $phase.AutomaticDeploymentTargets = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $phase.AutomaticDeploymentTargets)
        }

        Save-OctopusLifecycle -lifecycle $lifeCycleToClone -destinationData $DestinationData        
    }    

    Write-OctopusSuccess "Lifecycles successfully cloned, reloading destination list"    
    $destinationData.LifeCycleList = Get-OctopusLifeCycleList -OctopusData $DestinationData
}