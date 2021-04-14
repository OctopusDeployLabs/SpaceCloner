function Copy-OctopusProjectChannelRules
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $destinationProject,
        $sourceData,
        $destinationData,
        $CloneScriptOptions
    )

    Write-OctopusChangeLog "    - Channel Rules"

    if ($CloneScriptOptions.CloneProjectChannelRules -eq $false)
    {
        Write-OctopusWarning "The parameter CloneProjectChannelRules is set to false skipping the channel rules cloning."
        Write-OctopusChangeLog "      - Skipping Channel Rules cloning because the command line switch is set to false"
        return
    }

    Write-OctopusSuccess "Starting clone of project channel rules"
    $channelList = @()
    foreach($channel in $sourceChannelList)
    {
        $matchingChannel = Get-OctopusItemByName -ItemList $destinationChannelList -ItemName $channel.Name        

        if ($null -eq $matchingChannel)        
        {
            Write-OctopusVerbose "The channel $($channel.Name) does not exists for project $($destinationProject.Name).  Skipping it."
            Write-OctopusChangeLog "      - Skipping $($channel.Name) as it does not exist for the project"
            continue
        }

        if ($null -eq $channel.Rules)
        {
            Write-OctopusVerbose "The channel $($channel.Name) does not have any rules, skipping it."
            Write-OctopusChangeLog "      - Skipping $($channel.Name) as it does not have any rules"
            $channelList += $matchingChannel
            continue
        }
        
        Write-OctopusVerbose "Cloning the channel rules for $($channel.Name)"        

        $cloneChannel = Copy-OctopusObject -ItemToCopy $matchingChannel -ClearIdValue $false -SpaceId $destinationData.SpaceId        

        $cloneChannel.Rules = @(Copy-OctopusObject -ItemToCopy $channel.Rules -clearIdValue $false -SpaceId $null)
        Write-OctopusChangeLog "      - Updating $($channel.Name) rules to match source"
        foreach ($rule in $cloneChannel.Rules)
        {
            $rule.Id = $null
        }

        Write-OctopusVerbose "Updating the channel $($channel.Name) rules to match the source"
        $updatedChannel = Save-OctopusProjectChannel -projectChannel $cloneChannel -destinationData $destinationData                        
        $channelList += $updatedChannel
    }

    $destinationProjectId = $destinationProject.Id
    $destinationData.ProjectChannels.$destinationProjectId = $channelList

    Write-OctopusSuccess "Finished clone of project channels rules"
}