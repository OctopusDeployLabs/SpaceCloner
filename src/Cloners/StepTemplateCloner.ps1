function Copy-OctopusStepTemplates
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.StepTemplates -itemType "Step Templates" -filters $cloneScriptOptions.StepTemplatesToClone

    if ($filteredList.length -eq 0)
    {
        return
    }
    
    foreach ($stepTemplate in $filteredList)
    {
        Write-OctopusVerbose "Starting Clone of step template $($stepTemplate.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $stepTemplate.Name -ItemList $destinationData.StepTemplates        

        if ($null -ne $stepTemplate.CommunityActionTemplateId -and $null -eq $matchingItem)
        {
            Write-OctopusVerbose "The step template $($stepTemplate.Name) is a community step template and it hasn't been installed yet, installing"
            $destinationTemplate = Get-OctopusItemByName -ItemList $destinationData.CommunityActionTemplates -ItemName $stepTemplate.Name            

            Save-OctopusCommunityStepTemplate -communityStepTemplate $destinationTemplate -destinationData $destinationData            
        }        
        elseif ($null -eq $stepTemplate.CommunityActionTemplateId -and $null -ne $matchingItem -and $cloneScriptOptions.OverwriteExistingCustomStepTemplates -eq $false)
        {
            Write-OctopusVerbose "The step template $($stepTemplate.Name) already exists on the destination machine and you elected to skip existing step templates, skipping"                        
        }                
        elseif ($null -eq $stepTemplate.CommunityActionTemplateId) 
        {
            Write-OctopusVerbose "Saving $($stepTemplate.Name) to destination."

            $stepTemplateToClone = Copy-OctopusObject -ItemToCopy $stepTemplate -SpaceId $destinationData.SpaceId -ClearIdValue $true    
            if ($null -ne $matchingItem)
            {
                $stepTemplateToClone.Id = $matchingItem.Id
            }

            $destinationStepTemplate = Save-OctopusStepTemplate -StepTemplate $stepTemplateToClone -DestinationData $destinationData            

            Copy-OctopusItemLogo -sourceItem $stepTemplate -destinationItem $destinationStepTemplate -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions
        }        
    }

    Write-OctopusSuccess "Step Templates successfully cloned, reloading destination list"
    $destinationData.StepTemplates = Get-OctopusStepTemplateList -octopusData $destinationData
}