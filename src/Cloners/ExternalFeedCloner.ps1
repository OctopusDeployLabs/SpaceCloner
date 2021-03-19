function Copy-OctopusExternalFeeds
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.FeedList -itemType "Feeds" -filters $cloneScriptOptions.ExternalFeedsToClone    
    Write-OctopusChangeLog "External Feeds"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No external feeds found"
        return
    }

    foreach ($feed in $filteredList)
    {
        Write-OctopusVerbose "Starting Clone of External Feed $($feed.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $feed.Name -ItemList $destinationData.FeedList
                
        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "External Feed $($feed.Name) was not found in destination, creating new record."                 

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $feed -SpaceId $destinationData.SpaceId -ClearIdValue $true 
            
            if ($feed.FeedType -eq "AwsElasticContainerRegistry")
            {
                Throw "Unable to clone $($feed.Name) because it is an AWS Elastic Container Registry.  When it is created Octopus will test the AWS credentials.  As this is making API calls, I do not have access to said credentials.  Without this feed the remainder of your clone will most likely fail.  Please create the external feed on the destination and try again.  Exiting."
            }

            Write-OctopusChangeLog " - Add $($feed.Name)"

            $newExternalFeed = Save-OctopusExternalFeed -ExternalFeed $copyOfItemToClone -DestinationData $destinationData            
            $destinationData.FeedList += $newExternalFeed
        }
        else 
        {
            Write-OctopusVerbose "External Feed $($feed.Name) already exists, skipping."
            Write-OctopusChangeLog " - $($feed.Name) already exists, skipping"
        }
    }
        
    Write-OctopusSuccess "External Feeds successfully cloned"        
}