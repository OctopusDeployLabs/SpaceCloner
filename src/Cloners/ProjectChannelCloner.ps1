function Copy-OctopusProjectChannels
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $destinationProject,
        $sourceData,
        $destinationData
    )

    Write-OctopusSuccess "Starting clone of project channels"
    Write-OctopusChangeLog "    - Channels"
    $projectChannels = @()

    $filteredList = Get-OctopusFilteredList -itemList $sourceChannelList -itemType "Project Channels" -filters $cloneScriptOptions.ChannelsToClone
    
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog "      - No channels found to clone matching the filters"
        return
    }

    foreach($channel in $filteredList)
    {
        $matchingChannel = Get-OctopusItemByName -ItemList $destinationChannelList -ItemName $channel.Name

        if ($null -eq $matchingChannel)
        {
            $cloneChannel = Copy-OctopusObject -ItemToCopy $channel -ClearIdValue $false -SpaceId $destinationData.SpaceId
            $cloneChannel.Id = $null
            $cloneChannel.ProjectId = $destinationProject.Id
            if ($null -ne $cloneChannel.LifeCycleId)
            {
                $cloneChannel.LifeCycleId = Convert-SourceIdToDestinationId -SourceList $SourceData.LifeCycleList -DestinationList $DestinationData.LifeCycleList -IdValue $cloneChannel.LifeCycleId  -ItemName "$($cloneChannel.Name) Lifecycle" -MatchingOption "ErrorUnlessExactMatch"              
            }

            $cloneChannel.Rules = @()            
            Write-OctopusVerbose "The channel $($channel.Name) does not exist for the project $($destinationProject.Name), creating one now.  Please note, I cannot create version rules at this time, so those will be emptied out for now."
            Write-OctopusChangeLog "      - Add $($channel.Name)"
            $newChannel = Save-OctopusProjectChannel -projectChannel $cloneChannel -destinationData $destinationData   
            
            $projectChannels += $newChannel
        }        
        else
        {
            Write-OctopusVerbose "The channel $($channel.Name) already exists for project $($destinationProject.Name).  Skipping it."
            Write-OctopusChangeLog "      - $($channel.Name) already exists, skipping"
            $projectChannels += $matchingChannel
        }
    }

    $destinationProjectId = $destinationProject.Id
    $destinationData.ProjectChannels.$destinationProjectId = $projectChannels

    Write-OctopusSuccess "Finished clone of project channels"

    return $projectChannels
}