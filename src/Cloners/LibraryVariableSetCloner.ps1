function Copy-OctopusLibraryVariableSets
{
    param
    (
        $SourceData,
        $DestinationData,
        $cloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.VariableSetList -itemType "Library Variable Sets" -filters $cloneScriptOptions.LibraryVariableSetsToClone

    if ($filteredList.length -eq 0)
    {
        return
    }
    
    foreach($sourceVariableSet in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of $($sourceVariableSet.Name)"

        $destinationVariableSet = Get-OctopusItemByName -ItemList $destinationData.VariableSetList -ItemName $sourceVariableSet.Name

        if ($null -eq $destinationVariableSet)
        {
            Write-OctopusVerbose "Variable Set $($sourceVariableSet.Name) was not found in destination, creating new base record."
            $copySourceVariableSet = Copy-OctopusObject -ItemToCopy $sourceVariableSet -ClearIdValue $true -SpaceId $destinationData.SpaceId                       
            $copySourceVariableSet.VariableSetId = $null

            $destinationVariableSet = Save-OctopusVariableSet -libraryVariableSet $copySourceVariableSet -destinationData $destinationData
        }
        else
        {
            Write-OctopusVerbose "Variable Set $($sourceVariableSet.Name) already exists in destination."
        }

        Write-OctopusVerbose "The variable set has been created, time to copy over the variables themselves"

        $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $sourceVariableSet -OctopusData $sourceData
        $destinationVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $destinationVariableSet -OctopusData $DestinationData 

        Write-OctopusPostCloneCleanUp "*****************Starting clone of variable set $($sourceVariableSet.Name)*****************"
        Copy-OctopusVariableSetValues -SourceVariableSetVariables $sourceVariableSetVariables -DestinationVariableSetVariables $destinationVariableSetVariables -SourceData $SourceData -DestinationData $DestinationData -SourceProjectData @{} -DestinationProjectData @{} -CloneScriptOptions $cloneScriptOptions
        Write-OctopusPostCloneCleanUp "*****************Ending clone of variable set $($sourceVariableSet.Name)*******************"
    }

    Write-OctopusSuccess "Library Variable Sets successfully cloned, reloading destination list"    
    $destinationData.VariableSetList = Get-OctopusLibrarySetList -OctopusData $DestinationData
}