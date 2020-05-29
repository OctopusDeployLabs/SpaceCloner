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
    foreach($channel in $sourceChannelList)
    {
        $matchingChannel = Get-OctopusItemByName -ItemList $destinationChannelList -ItemName $channel.Name

        if ($null -eq $matchingChannel)
        {
            $cloneChannel = Copy-OctopusObject -ItemToCopy $channel -ClearIdValue $false -SpaceId $destinationData.SpaceId
            $cloneChannel.Id = $null
            $cloneChannel.ProjectId = $destinationProject.Id
            if ($null -ne $cloneChannel.LifeCycleId)
            {
                $cloneChannel.LifeCycleId = Convert-SourceIdToDestinationId -SourceList $SourceData.LifeCycleList -DestinationList $DestinationData.LifeCycleList -IdValue $cloneChannel.LifeCycleId
            }

            $cloneChannel.Rules = @()

            Write-OctopusVerbose "The channel $($channel.Name) does not exist for the project $($destinationProject.Name), creating one now.  Please note, I cannot create version rules, so those will be emptied out"
            Save-OctopusProjectChannel -projectChannel $cloneChannel -destinationData $destinationData            
        }        
        else
        {
            Write-OctopusVerbose "The channel $($channel.Name) already exists for project $($destinationProject.Name).  Skipping it."
        }
    }
    Write-OctopusSuccess "Finished clone of project channels"
}