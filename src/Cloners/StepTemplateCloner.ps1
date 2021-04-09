function Copy-OctopusStepTemplates
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.StepTemplates -itemType "Step Templates" -filters $cloneScriptOptions.StepTemplatesToClone

    Write-OctopusChangeLog "Step Templates"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No step templates found to clone matching the filters"
        return
    }
    
    foreach ($stepTemplate in $filteredList)
    {
        Write-OctopusVerbose "Starting Clone of step template $($stepTemplate.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $stepTemplate.Name -ItemList $destinationData.StepTemplates        

        if ($null -ne $stepTemplate.CommunityActionTemplateId -and $null -eq $matchingItem)
        {
            Write-OctopusVerbose "The step template $($stepTemplate.Name) is a community step template and it hasn't been installed yet, installing"
            Write-OctopusChangeLog " - Install community step template $($stepTemplate.Name)"

            $destinationTemplate = Get-OctopusItemByName -ItemList $destinationData.CommunityActionTemplates -ItemName $stepTemplate.Name            

            $destinationCommunityStep = Save-OctopusCommunityStepTemplate -communityStepTemplate $destinationTemplate -destinationData $destinationData            
            
            $destinationData.StepTemplates = Update-OctopusList -itemList $destinationData.StepTemplates -itemToReplace $destinationCommunityStep
        }        
        elseif ($null -eq $stepTemplate.CommunityActionTemplateId -and $null -ne $matchingItem -and $cloneScriptOptions.OverwriteExistingCustomStepTemplates -eq $false)
        {
            Write-OctopusVerbose "The step template $($stepTemplate.Name) already exists on the destination machine and you elected to skip existing step templates, skipping"                        
            Write-OctopusChangeLog " - $($stepTemplate.Name) left alone due to overwrite custom step templates set to false"
        }                
        elseif ($null -eq $stepTemplate.CommunityActionTemplateId) 
        {
            Write-OctopusVerbose "Saving $($stepTemplate.Name) to destination."

            $stepTemplateToClone = Copy-OctopusObject -ItemToCopy $stepTemplate -SpaceId $destinationData.SpaceId -ClearIdValue $true    
            if ($null -ne $matchingItem)
            {
                $stepTemplateToClone.Id = $matchingItem.Id
                Write-OctopusChangeLog " - Update $($stepTemplate.Name)"
            }
            else
            {
                Write-OctopusChangeLog " - Add $($stepTemplate.Name)"    
            }

            Convert-OctopusPackageList -item $stepTemplateToClone -SourceData $sourceData -destinationData $destinationData

            $destinationStepTemplate = Save-OctopusStepTemplate -StepTemplate $stepTemplateToClone -DestinationData $destinationData            

            Copy-OctopusItemLogo -sourceItem $stepTemplate -destinationItem $destinationStepTemplate -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions

            $destinationData.StepTemplates = Update-OctopusList -itemList $destinationData.StepTemplates -itemToReplace $destinationStepTemplate
        }
        else
        {
            Write-OctopusChangeLog " - $($stepTemplate.Name) already exists, skipping"    
        }        
    }

    Write-OctopusSuccess "Step Templates successfully cloned"    
}