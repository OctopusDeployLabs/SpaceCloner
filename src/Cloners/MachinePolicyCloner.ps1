function Copy-OctopusMachinePolicies
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.MachinePolicyList -itemType "Machine Policies" -filters $cloneScriptOptions.MachinePoliciesToClone

    Write-OctopusChangeLog "Machine Policies"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No machine policies found to clone"
        return
    }
    
    foreach ($machinePolicy in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of machine policy $($machinePolicy.Name)"

        $matchingItem = Get-OctopusItemByName -ItemName $machinePolicy.Name -ItemList $destinationData.MachinePolicyList         

        $machinePolicyToClone = Copy-OctopusObject -ItemToCopy $machinePolicy -ClearIdValue $true -SpaceId $destinationData.SpaceId  
        
        if ($null -ne $matchingItem)
        {
            $machinePolicyToClone.Id = $matchingItem.Id
            Write-OctopusChangeLog " - Update $($machinePolicy.Name)"
        }
        else
        {
            Write-OctopusChangeLog " - Add $($machinePolicy.Name)"    
        }
        
        $updatedMachinePolicy = Save-OctopusMachinePolicy -MachinePolicy $machinePolicyToClone -destinationData $DestinationData 
        $destinationData.MachinePolicyList = Update-OctopusList -itemList $destinationData.MachinePolicyList -itemToReplace $updatedMachinePolicy
    }    

    Write-OctopusSuccess "Machine policies successfully cloned"        
}