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

    if ($CloneScriptOptions.CloneProjectChannelRules -eq $false)
    {
        Write-OctopusWarning "The parameter CloneProjectChannelRules is set to false skipping the channel rules cloning."
        return
    }

    Write-OctopusSuccess "Starting clone of project channel rules"
    foreach($channel in $sourceChannelList)
    {
        $matchingChannel = Get-OctopusItemByName -ItemList $destinationChannelList -ItemName $channel.Name

        if ($null -eq $matchingChannel)        
        {
            Write-OctopusVerbose "The channel $($channel.Name) does not exists for project $($destinationProject.Name).  Skipping it."
            continue
        }

        if ($null -eq $channel.Rules)
        {
            Write-OctopusVerbose "The channel $($channel.Name) does not have any rules, skipping it."
            continue
        }
        
        Write-OctopusVerbose "Cloning the channel rules for $($channel.Name)"
        Write-Host $channel.Rules

        $cloneChannel = Copy-OctopusObject -ItemToCopy $matchingChannel -ClearIdValue $false -SpaceId $destinationData.SpaceId        

        $cloneChannel.Rules = @(Copy-OctopusObject -ItemToCopy $channel.Rules -clearIdValue $false -SpaceId $null)
        foreach ($rule in $cloneChannel.Rules)
        {
            $rule.Id = $null
        }

        Write-OctopusVerbose "Updating the channel $($channel.Name) rules to match the source"
        Save-OctopusProjectChannel -projectChannel $cloneChannel -destinationData $destinationData                        
    }

    Write-OctopusSuccess "Finished clone of project channels rules"
}