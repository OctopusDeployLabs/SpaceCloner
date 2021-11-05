function Copy-OctopusDeploymentProcess
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $sourceData,
        $destinationData,
        $sourceDeploymentProcessSteps,
        $destinationDeploymentProcessSteps,
        $cloneScriptOptions
    )

    Write-OctopusVerbose "Looping through the source steps to get them added"
    $newDeploymentProcessSteps = @()
    foreach($step in $sourceDeploymentProcessSteps)
    {
        $matchingStep = Get-OctopusItemByName -ItemList $destinationDeploymentProcessSteps -ItemName $step.Name
                
        if ($null -eq $matchingStep)
        {
            Write-OctopusVerbose "The step $($step.Name) was not found, cloning from source and removing id"            
            Write-OctopusChangeLog "      - Adding step $($step.Name)"
            $stepToAdd = Copy-OctopusObject -ItemToCopy $step -ClearIdValue $true -SpaceId $null                        
        }
        else
        {
            Write-OctopusVerbose "Matching step $($step.Name) found, using that existing step"
            Write-OctopusChangeLog "      - Updating step $($step.Name)"
            $stepToAdd = Copy-OctopusObject -ItemToCopy $matchingStep -ClearIdValue $false -SpaceId $null
        }

        Write-OctopusVerbose "Looping through the source actions to add them to the step"
        $newStepActions = @()
        foreach ($action in $step.Actions)
        {
            $matchingAction = Get-OctopusItemByName -ItemList $matchingStep.Actions -ItemName $action.Name
            $clonedStep = Copy-OctopusProcessStepAction -sourceAction $action -sourceChannelList $sourceChannelList -destinationChannelList $destinationChannelList -sourceData $sourceData -destinationData $destinationData -matchingAction $matchingAction -CloneScriptOptions $cloneScriptOptions                  

            if ($null -ne $clonedStep)
            {                
                $newStepActions += $clonedStep                

                if ($null -ne $matchingAction)
                {
                    Write-OctopusChangeLog "        - Updating action $($action.Name)"
                }
                else 
                {
                    Write-OctopusChangeLog "        - Adding action $($action.Name)"
                }
            }            
        }

        if ($cloneScriptOptions.ProcessCloningOption.ToLower().Trim() -eq "KeepAdditionalDestinationSteps")
        {
            Write-OctopusVerbose "Looping through the destination step to make sure we didn't miss any actions"
            foreach ($action in $stepToAdd.Actions)
            {
                $matchingAction = Get-OctopusItemByName -ItemList $step.Actions -ItemName $action.Name

                if ($null -eq $matchingAction)
                {
                    Write-OctopusVerbose "The action $($action.Name) didn't exist at the source, adding that back to the destination list"  
                    Write-OctopusChangeLog "        - $($action.Name) exists on destination, but not on the source, leaving as is"              
                    $newStepActions += Copy-OctopusObject -ItemToCopy $action -ClearIdValue $false -SpaceId $null
                }
            }
        }
        else
        {
            Write-OctopusVerbose "The parameter ProcessCloningOption was set to SourceOnly, skipping any steps on the destination not in the source."    
        }
        
        $stepToAdd.Actions = @()
        foreach ($newStepAction in $newStepActions)
        {
            if ($null -ne $newStepAction)
            {
                $stepToAdd.Actions += $newStepAction
            }
        }              

        if ($stepToAdd.Actions.Length -gt 0)
        {
            $newDeploymentProcessSteps += $stepToAdd
        }
    }

    if ($cloneScriptOptions.ProcessCloneOptions.ToLower().Trim() -eq "KeepAdditionalDestinationSteps")
    {
        Write-OctopusVerbose "Looping through the destination deployment process steps to make sure we didn't miss anything"
        foreach ($step in $destinationDeploymentProcessSteps)
        {
            $matchingStep = Get-OctopusItemByName -ItemList $sourceDeploymentProcessSteps -ItemName $step.Name

            if ($null -eq $matchingStep)
            {
                Write-OctopusVerbose "The step $($step.Name) didn't exist in the source, adding that back to the destiantion list"
                Write-OctopusChangeLog "      - $($step.Name) exists on destination, but not on source, leaving alone"
                $newDeploymentProcessSteps += Copy-OctopusObject -ItemToCopy $step -ClearIdValue $false -SpaceId $null
            }
        }
    }
    else
    {
        Write-OctopusVerbose "The parameter ProcessCloningOption was set to SourceOnly, skipping any steps on the destination not in the source."
    }

    return @($newDeploymentProcessSteps)
}