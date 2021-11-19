function Copy-OctopusLibraryVariableSets
{
    param
    (
        $SourceData,
        $DestinationData,
        $cloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.VariableSetList -itemType "Library Variable Sets" -filters $cloneScriptOptions.LibraryVariableSetsToClone

    Write-OctopusChangeLog "Library Variable Sets"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No Library Variable Sets found to clone matching the filters"
        return
    }
    
    foreach($sourceVariableSet in $filteredList)
    {
        $destinationVariableSetName = $sourceVariableSet.Name
        if ($null -ne $CloneScriptOptions.DestinationVariableSetName)
        {            
            $destinationVariableSetName = $cloneScriptOptions.DestinationVariableSetName
        }

        Write-OctopusSuccess "Starting clone of $($sourceVariableSet.Name) to $destinationVariableSetName on space $($DestinationData.SpaceName)"

        $destinationVariableSet = Get-OctopusItemByName -ItemList $destinationData.VariableSetList -ItemName $destinationVariableSetName

        if ($null -eq $destinationVariableSet)
        {
            Write-OctopusVerbose "Variable Set $($sourceVariableSet.Name) was not found in destination, creating new base record."
            Write-OctopusChangeLog " - Add $($sourceVariableSet.Name)"
            $copySourceVariableSet = Copy-OctopusObject -ItemToCopy $sourceVariableSet -ClearIdValue $true -SpaceId $destinationData.SpaceId                       
            $copySourceVariableSet.VariableSetId = $null
            $copySourceVariableSet.Name = $destinationVariableSetName

            foreach ($template in $copySourceVariableSet.Templates)
            {
                $template.Id = $null
            }

            $destinationVariableSet = Save-OctopusVariableSet -libraryVariableSet $copySourceVariableSet -destinationData $destinationData
            $destinationData.VariableSetList = Update-OctopusList -itemList $destinationData.VariableSetList -itemToReplace $destinationVariableSet
        }
        else
        {
            Write-OctopusVerbose "Variable Set $($sourceVariableSet.Name) already exists in destination."
            Write-OctopusChangeLog " - $($sourceVariableSet.Name) already exists, updating variables" 
            
            foreach ($template in $sourceVariableSet.Templates)
            {
                $matchingTemplate = Get-OctopusItemByName -ItemList $destinationVariableSet.Templates -ItemName $template.Name

                if ($null -eq $matchingTemplate)
                {
                    $templateClone = Copy-OctopusObject -ItemToCopy $template -ClearIdValue $true -SpaceId $null
                    $destinationVariableSet.Templates += $templateClone
                }
                else
                {
                    $matchingTemplate.Label = $template.Label
                    $matchingTemplate.HelpText = $template.HelpText
                    $matchingTemplate.DefaultValue = $template.DefaultValue
                    $matchingTemplate.DisplaySettings.'Octopus.ControlType' = $template.DisplaySettings.'Octopus.ControlType'
                }
            }

            $destinationVariableSet = Save-OctopusVariableSet -libraryVariableSet $destinationVariableSet -destinationData $destinationData
            $destinationData.VariableSetList = Update-OctopusList -itemList $destinationData.VariableSetList -itemToReplace $destinationVariableSet
        }

        Write-OctopusVerbose "The variable set has been created, time to copy over the variables themselves"

        $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $sourceVariableSet -OctopusData $sourceData
        $destinationVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $destinationVariableSet -OctopusData $DestinationData 

        Write-OctopusPostCloneCleanUp "*****************Starting clone of variable set $($sourceVariableSet.Name)*****************"
        Copy-OctopusVariableSetValues -SourceVariableSetVariables $sourceVariableSetVariables -DestinationVariableSetVariables $destinationVariableSetVariables -SourceData $SourceData -DestinationData $DestinationData -CloneScriptOptions $cloneScriptOptions
        Write-OctopusPostCloneCleanUp "*****************Ending clone of variable set $($sourceVariableSet.Name)*******************"
    }

    Write-OctopusSuccess "Library Variable Sets successfully cloned"        
}