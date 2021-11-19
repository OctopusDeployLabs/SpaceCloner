function Copy-OctopusEnvironments
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.EnvironmentList -itemType "Environment" -filters $cloneScriptOptions.EnvironmentsToClone        
    Write-OctopusChangeLog "Environments"

    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No Environments found to clone matching the filters"
        return
    }    

    foreach ($environment in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of Environment $($environment.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $environment.Name -ItemList $destinationData.EnvironmentList                

        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "Environment $($environment.Name) was not found in destination, creating new record."
            Write-OctopusChangeLog " - Add $($environment.Name)"                    

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $environment -SpaceId $destinationData.SpaceId -ClearIdValue $true    

            $newEnvironment = Save-OctopusEnvironment -environment $copyOfItemToClone -DestinationData $destinationData            

            $destinationData.EnvironmentList = Update-OctopusList -itemList $destinationData.EnvironmentList -itemToReplace $newEnvironment
        }
        else 
        {
            Write-OctopusVerbose "Environment $($environment.Name) already exists in destination, skipping"  
            Write-OctopusChangeLog " - $($environment.Name) already exists, skipping"  
        }
    }    

    Write-OctopusSuccess "Environments successfully cloned"        
}
