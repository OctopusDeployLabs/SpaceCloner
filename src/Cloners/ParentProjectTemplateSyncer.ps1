function Sync-OctopusMasterOctopusProjectWithChildProjects
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )  

    if ([string]::IsNullOrWhiteSpace($CloneScriptOptions.ParentProjectName) -eq $true -or [string]::IsNullOrWhiteSpace($CloneScriptOptions.ChildProjectsToSync) -eq $true)
    {
        Write-OctopusWarning "The template project parameter or the clone project parameter wasn't specified skipping the sync child projects process"
        return
    }

    $filteredSourceList = @(Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ParentProjectName)

    if ($filteredSourceList.Count -ne 1)
    {
        Throw "The project you specified as the template $($CloneScriptOptions.ParentProjectName) resulted in $($filteredList.Count) item(s) found in the source.  This count must be exactly equal to 1.  Please update the filter."
    }

    $sourceProject = $filteredSourceList[0]

    $filteredDestinationList = Get-OctopusFilteredList -itemList $DestinationData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ChildProjectsToSync
    
    foreach($destinationProject in $filteredDestinationList)
    {                
        $sourceChannels = Get-OctopusProjectChannelList -project $sourceProject -OctopusData $sourceData
        $destinationChannels = Get-OctopusProjectChannelList -project $destinationProject -OctopusData $DestinationData

        if ($CloneScriptOptions.CloneProjectDeploymentProcess -eq $true)
        {
            Copy-OctopusProjectDeploymentProcess -sourceChannelList $sourceChannels -sourceProject $sourceProject -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData -cloneScriptOptions $CloneScriptOptions
        }

        if ($CloneScriptOptions.CloneProjectRunbooks -eq $true)
        {
            Copy-OctopusProjectRunbooks -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $sourceProject -destinationData $DestinationData -sourceData $SourceData -cloneScriptOptions $CloneScriptOptions            
        }
        
        Copy-OctopusProjectVariables -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $sourceProject -destinationData $DestinationData -sourceData $SourceData -cloneScriptOptions $CloneScriptOptions -createdNewProject $false        
        Copy-OctopusProjectChannelRules -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData -cloneScriptOptions $CloneScriptOptions
        Copy-OctopusProjectReleaseVersioningSettings -sourceData $sourceData -sourceProject $sourceProject -sourceChannels $sourceChannels -destinationData $destinationData -destinationProject $destinationProject -destinationChannels $destinationChannels -CloneScriptOptions $CloneScriptOptions
    }
}