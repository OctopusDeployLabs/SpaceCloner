function Copy-OctopusExternalFeeds
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.FeedList -itemType "Feeds" -filters $cloneScriptOptions.ExternalFeedsToClone    
    
    if ($filteredList.length -eq 0)
    {
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

            Save-OctopusExternalFeed -ExternalFeed $copyOfItemToClone -DestinationData $destinationData            
        }
        else 
        {
            Write-OctopusVerbose "External Feed $($feed.Name) already exists, skipping."
        }
    }
        
    Write-OctopusSuccess "External Feeds successfully cloned, reloading destination list"    
    $destinationData.FeedList = Get-OctopusFeedList -OctopusData $DestinationData
}