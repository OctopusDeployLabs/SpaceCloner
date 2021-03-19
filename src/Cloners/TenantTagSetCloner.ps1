function Copy-OctopusTenantTags
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    Write-OctopusChangeLog "Tenant Tags"
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TenantTagList -itemType "Tenant Tags" -filters $cloneScriptOptions.TenantTagsToClone
    
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No Tenant Tags found to clone"
        return
    }
    
    foreach($tagSet in $filteredList)
    {
        Write-OctopusVerbose "Starting Clone Of Tag Set $($tagSet.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $tagSet.Name -ItemList $destinationData.TenantTagList
        
        $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $tagSet -SpaceId $destinationData.SpaceId -ClearIdValue $true    

        $tags = @()
        foreach ($tag in $copyOfItemToClone.Tags)
        {
            $itemToAdd = Copy-OctopusObject -ItemToCopy $tag -SpaceId $null -ClearIdValue $true
            if ($null -ne $matchingItem)
            {
                $matchingTag = Get-OctopusItemByName -ItemName $tag.Name -ItemList $matchingItem.Tags
                if ($null -ne $matchingTag)
                {
                    $itemToAdd = Copy-OctopusObject -ItemToCopy $matchingTag -spaceId $null $clearIdValue $false
                }
            }
            
            $tags += $itemToAdd
        }                     

        If ($null -ne $matchingItem)
        {            
            Write-OctopusChangeLog " - Updating $($copyOfItemToClone.Name)"
            foreach ($tag in $matchingItem.Tags)
            {
                $matchingTag = Get-OctopusItemByName -ItemName $tag.Name -ItemList $tagSet.Tags

                if ($null -eq $matchingTag)
                {
                    $tags += Copy-OctopusObject -ItemToCopy $tag -spaceId $null $clearIdValue $false
                }
                else
                {
                    Write-OctopusChangeLog "    - Adding tag $matchingTag"    
                }
            }

            Write-OctopusVerbose "Overwriting $TagSet $($copyOfItemToClone.Name) with data from source."
            $copyOfItemToClone.Id = $matchingItem.Id            
        }
        else
        {
            Write-OctopusChangeLog " - Adding $($copyOfItemToClone.Name)" 
            foreach ($tag in $tags)   
            {
                Write-OctopusChangeLog "    - Adding tag $tag"
            }
        }                

        $copyOfItemToClone.Tags = @($tags)  
        
        $newTenantTagSet = Save-OctopusTenantTagSet -TenantTagSet $copyOfItemToClone -DestinationData $destinationData        
        $destinationData.TenantTagList += $newTenantTagSet        
    }    
    
    Write-OctopusSuccess "Tenant Tags successfully cloned"
}