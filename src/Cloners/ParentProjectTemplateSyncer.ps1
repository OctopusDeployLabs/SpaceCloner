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

    $filteredSourceList = Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ParentProjectName

    if ($filteredSourceList.Length -ne 1)
    {
        Throw "The project you specified as the template $($CloneScriptOptions.ParentProjectName) resulted in $($filteredList.Length) item(s) found in the source.  This count must be exactly equal to 1.  Please update the filter."
    }

    $sourceProject = $filteredSourceList[0]

    $filteredDestinationList = Get-OctopusFilteredList -itemList $DestinationData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ChildProjectsToSync
    
    foreach($destinationProject in $filteredDestinationList)
    {                
        $sourceChannels = Get-OctopusProjectChannelList -project $project -OctopusData $sourceData
        $destinationChannels = Get-OctopusProjectChannelList -project $destinationProject -OctopusData $DestinationData

        Copy-OctopusProjectDeploymentProcess -sourceChannelList $sourceChannels -sourceProject $sourceProject -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData 

        if ($CloneScriptOptions.CloneProjectRunbooks -eq $true)
        {
            Copy-OctopusProjectRunbooks -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $sourceProject -destinationData $DestinationData -sourceData $SourceData            
        }

        Copy-OctopusProjectVariables -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $sourceProject -destinationData $DestinationData -sourceData $SourceData -cloneScriptOptions $CloneScriptOptions -createdNewProject $createdNewProject        
    }
}