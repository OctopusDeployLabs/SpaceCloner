function Copy-OctopusProjectGroups
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.ProjectGroupList -itemType "Project Groups" -filters $cloneScriptOptions.ProjectGroupsToClone
    Write-OctopusChangeLog "Project Groups"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusVerbose " - No Project Groups found to clone"
        return
    }
    
    foreach ($projectGroup in $filteredList)
    {
        Write-OctopusVerbose "Starting Clone Of Project Group $($projectGroup.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $projectGroup.Name -ItemList $destinationData.ProjectGroupList                

        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "Project Group $($projectGroup.Name) was not found in destination, creating new record."
            Write-OctopusChangeLog " - Add $($projectGroup.Name)"  

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $projectGroup -SpaceId $destinationData.SpaceId -ClearIdValue $true                                          

            $newProjectGroup = Save-OctopusProjectGroup -ProjectGroup $copyOfItemToClone -DestinationData $destinationData            
            $destinationData.ProjectGroupList += $newProjectGroup
        }
        else 
        {
            Write-OctopusChangeLog " - $($projectGroup.Name) already exists, skipping"
            Write-OctopusVerbose "Project Group $($projectGroup.Name) already exists in destination, skipping"    
        }
    } 
    
    Write-OctopusSuccess "Project Groups successfully cloned"    
}