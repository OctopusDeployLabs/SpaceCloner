function Copy-OctopusLifecycles
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.LifeCycleList -itemType "Lifecycles" -filters $cloneScriptOptions.LifeCyclesToClone

    Write-OctopusChangeLog "Lifecycles"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No Lifecycles found to clone matching the filters"
        return
    }
    
    foreach ($lifecycle in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of Lifecycle $($lifecycle.Name)"

        $matchingItem = Get-OctopusItemByName -ItemName $lifecycle.Name -ItemList $destinationData.LifeCycleList   

        if ($null -ne $matchingItem -and $CloneScriptOptions.OverwriteExistingLifecyclesPhases -eq $false)             
        {
            Write-OctopusVerbose "Lifecycle already exists and you selected not to overwrite phases, skipping"
            Write-OctopusChangeLog " - $($lifecycle.Name) already exists, option set to not overwrite, skipping"
            continue
        }        

        $lifeCycleToClone = Copy-OctopusObject -ItemToCopy $lifecycle -ClearIdValue $true -SpaceId $null  
        
        if ($null -ne $matchingItem)
        {
            $lifeCycleToClone.Id = $matchingItem.Id
            Write-OctopusChangeLog " - Updating $($lifecycle.Name)"
        }
        else
        {
            Write-OctopusChangeLog " - Add $($lifecycle.Name)"    
        }

        foreach ($phase in $lifeCycleToClone.Phases)
        {          
            Write-OctopusChangeLog "    - Phase $($phase.Name)"

            $phase.OptionalDeploymentTargets = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $phase.OptionalDeploymentTargets)
            $phase.AutomaticDeploymentTargets = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $phase.AutomaticDeploymentTargets)

            Write-OctopusChangeLogListDetails -prefixSpaces "       " -listType "Manual Deployment Environments" -idList $phase.OptionalDeploymentTargets -destinationList $DestinationData.EnvironmentList
            Write-OctopusChangeLogListDetails -prefixSpaces "       " -listType "Automatic Deployment Environments" -idList $phase.AutomaticDeploymentTargets -destinationList $DestinationData.EnvironmentList

            $phase.ReleaseRetentionPolicy = Test-OctopusLifeCycleRetentionPolicy -retentionPolicy $phase.ReleaseRetentionPolicy -DestinationData $destinationData
            $phase.TentacleRetentionPolicy = Test-OctopusLifeCycleRetentionPolicy -retentionPolicy $phase.TentacleRetentionPolicy -DestinationData $destinationData        
        }

        $lifeCycleToClone.ReleaseRetentionPolicy = Test-OctopusLifeCycleRetentionPolicy -retentionPolicy $lifeCycleToClone.ReleaseRetentionPolicy -DestinationData $destinationData
        $lifeCycleToClone.TentacleRetentionPolicy = Test-OctopusLifeCycleRetentionPolicy -retentionPolicy $lifeCycleToClone.TentacleRetentionPolicy -DestinationData $destinationData        

        $updatedLifecycle = Save-OctopusLifecycle -lifecycle $lifeCycleToClone -destinationData $DestinationData  
        $destinationData.LifeCycleList = Update-OctopusList -itemList $destinationData.LifeCycleList -itemToReplace $updatedLifecycle
    }

    Write-OctopusSuccess "Lifecycles successfully cloned"        
}

function Test-OctopusLifeCycleRetentionPolicy
{
    param(
        $retentionPolicy,
        $DestinationData
    )

    if ($null -eq $retentionPolicy)
    {
        return $null
    }

    if ($DestinationData.OctopusUrl -notlike "*.octopus.app")
    {
        return $retentionPolicy
    }

    Write-OctopusVerbose "The destination URL is a cloud instance, verifying the retention policies meet the cloud rules"

    if ($retentionPolicy.Unit -eq "Days" -and $retentionPolicy.QuantityToKeep -le 30 -and $retentionPolicy.QuantityToKeep -gt 0)
    {
        Write-OctopusVerbose "The retention policy meets requirements, leaving as is."

        $retentionPolicy.ShouldKeepForever = $false

        return $retentionPolicy
    }
    
    Write-OctopusWarning "The retention policy doesn't meet requirements, setting to be 30 days."

    $retentionPolicy.ShouldKeepForever = $false
    $retentionPolicy.QuantityToKeep = 30
    $retentionPolicy.Unit = "Days"        

    return $retentionPolicy
}