function Copy-OctopusDeploymentProcess
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $sourceData,
        $destinationData,
        $sourceDeploymentProcessSteps,
        $destinationDeploymentProcessSteps
    )

    Write-OctopusVerbose "Looping through the source steps to get them added"
    $newDeploymentProcessSteps = @()
    foreach($step in $sourceDeploymentProcessSteps)
    {
        $matchingStep = Get-OctopusItemByName -ItemList $destinationDeploymentProcessSteps -ItemName $step.Name
        
        $newStep = $false
        if ($null -eq $matchingStep)
        {
            Write-OctopusVerbose "The step $($step.Name) was not found, cloning from source and removing id"            
            $stepToAdd = Copy-OctopusObject -ItemToCopy $step -ClearIdValue $true -SpaceId $null            
            $newStep = $true
        }
        else
        {
            Write-OctopusVerbose "Matching step $($step.Name) found, using that existing step"
            $stepToAdd = Copy-OctopusObject -ItemToCopy $matchingStep -ClearIdValue $false -SpaceId $null
        }

        Write-OctopusVerbose "Looping through the source actions to add them to the step"
        $newStepActions = @()
        foreach ($action in $step.Actions)
        {
            $matchingAction = Get-OctopusItemByName -ItemList $stepToAdd.Actions -ItemName $action.Name

            if ($null -eq $matchingAction -or $newStep -eq $true)
            {
                Write-OctopusVerbose "The action $($action.Name) doesn't exist for the step, adding that to the list"
                $clonedStep = Copy-OctopusProcessStepAction -sourceAction $action -sourceChannelList $sourceChannelList -destinationChannelList $destinationChannelList -sourceData $sourceData -destinationData $destinationData         

                if ($null -ne $clonedStep)
                {
                    $newStepActions += $clonedStep
                }
            }            
            else
            {
                Write-OctopusVerbose "The action $($action.Name) already exists for the step, adding existing item to list"
                $newStepActions += Copy-OctopusObject -ItemToCopy $matchingAction -ClearIdValue $false -SpaceId $null
            }
        }

        Write-OctopusVerbose "Looping through the destination step to make sure we didn't miss any actions"
        foreach ($action in $stepToAdd.Actions)
        {
            $matchingAction = Get-OctopusItemByName -ItemList $step.Actions -ItemName $action.Name

            if ($null -eq $matchingAction)
            {
                Write-OctopusVerbose "The action $($action.Name) didn't exist at the source, adding that back to the destination list"
                $newStepActions += Copy-OctopusObject -ItemToCopy $action -ClearIdValue $false -SpaceId $null
            }
        }
        
        $stepToAdd.Actions = @($newStepActions)

        if ($stepToAdd.Actions.Length -gt 0)
        {
            $newDeploymentProcessSteps += $stepToAdd
        }
    }

    Write-OctopusVerbose "Looping through the destination deployment process steps to make sure we didn't miss anything"
    foreach ($step in $destinationDeploymentProcessSteps)
    {
        $matchingStep = Get-OctopusItemByName -ItemList $sourceDeploymentProcessSteps -ItemName $step.Name

        if ($null -eq $matchingStep)
        {
            Write-OctopusVerbose "The step $($step.Name) didn't exist in the source, adding that back to the destiantion list"
            $newDeploymentProcessSteps += Copy-OctopusObject -ItemToCopy $step -ClearIdValue $false -SpaceId $null
        }
    }

    return @($newDeploymentProcessSteps)
}