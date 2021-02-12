function Copy-OctopusProcessStepAction
{
    param(
        $sourceAction,
        $sourceChannelList,
        $destinationChannelList,
        $matchingAction,
        $sourceData,
        $destinationData
    )            

    $action = Copy-OctopusObject -ItemToCopy $sourceAction -ClearIdValue $true -SpaceId $null   

    $action.Environments = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $action.Environments)
    $action.ExcludedEnvironments = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $action.ExcludedEnvironments)
    $action.Channels = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceChannelList -DestinationList $destinationChannelList -IdList $action.Channels)
    
    Convert-OctopusProcessActionWorkerPoolId -action $action -sourceData $sourceData -destinationData $destinationData                
    Convert-OctopusProcessActionExecutionContainerFeedId -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusProcessActionStepTemplate -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusProcessActionManualIntervention -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusProcessActionFeedId -action $action -sourceData $sourceData -destinationData $destinationData        
    Convert-OctopusPackageList -item $action -sourceData $sourceData -destinationData $destinationData 
    Convert-OctopusSinglePackageProprty -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusActionIdsForMatchingActionId -action $action -matchingAction $matchingAction

    return $action    
}

function Convert-OctopusProcessActionWorkerPoolId
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if ((Test-OctopusObjectHasProperty -objectToTest $action -propertyName "WorkerPoolId"))
    {
        if ($null -ne $action.WorkerPoolId)
        {
            $action.WorkerPoolId = Convert-SourceIdToDestinationId -SourceList $SourceData.WorkerPoolList -DestinationList $DestinationData.WorkerPoolList -IdValue $action.WorkerPoolId                             
        }
    }
}

function Convert-OctopusProcessActionExecutionContainerFeedId
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if ((Test-OctopusObjectHasProperty -objectToTest $action -propertyName "Container"))
    {
        if ($null -ne $action.Container.FeedId)
        {
            $action.Container.FeedId = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $action.Container.FeedId            
        }
    }
}

function Convert-OctopusProcessActionStepTemplate
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Template.Id")
    {                                        
        $action.Properties.'Octopus.Action.Template.Id' = Convert-SourceIdToDestinationId -SourceList $sourceData.StepTemplates -DestinationList $destinationData.StepTemplates -IdValue $action.Properties.'Octopus.Action.Template.Id' 
        $stepTemplate = Get-OctopusItemById -ItemList $destinationData.StepTemplates -ItemId $action.Properties.'Octopus.Action.Template.Id'
        $action.Properties.'Octopus.Action.Template.Version' = $stepTemplate.Version

        foreach ($parameter in $stepTemplate.Parameters)
        {                                
            if ((Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName $parameter.Name))
            {
                $controlType = $parameter.DisplaySettings.'Octopus.ControlType'
                Write-OctopusVerbose "$($parameter.Name) is control type is $controlType"
                
                if ($controlType -eq "Package")
                {
                    $feedInformation = $action.Properties.$($parameter.Name) | ConvertFrom-Json
                    $feedInformation.FeedId = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $feedInformation.FeedId

                    $action.Properties.$($parameter.Name) = $feedInformation | ConvertTo-Json
                }    
                elseif ($controlType -eq "Sensitive")            
                {
                    if ((Test-OctopusObjectHasProperty -objectToTest $action.Properties.$($parameter.Name) -propertyName "HasValue"))
                    {
                        Write-OctopusPostCloneCleanUp "Set $($parameter.Name) in $($action.Name) to Dummy Value"
                        $action.Properties.$($parameter.Name).NewValue = "DUMMY VALUE"
                        $action.Properties.$($parameter.Name).HasValue = $true
                    }                    
                }
            }            
        }
    }
}

function Convert-OctopusProcessActionManualIntervention
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Manual.ResponsibleTeamIds")
    {
        $manualInterventionSourceTeamIds = @($action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' -split ",")
        $manualInterventionDestinationTeamIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TeamList -DestinationList $DestinationData.TeamList -IdList $manualInterventionSourceTeamIds)

        if ($manualInterventionDestinationTeamIds.Length -eq 0)
        {
            Write-OctopusPostCloneCleanUp "Unable to find matching teams for $($action.Name), converting responsible team to built in team 'team-managers'"                                        
            $action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' = "team-managers"
        }
        else
        {
            $action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' = ($manualInterventionDestinationTeamIds -join ",")
        }        
    }
}

function Convert-OctopusProcessActionFeedId
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Package.FeedId")
    {
        $action.Properties.'Octopus.Action.Package.FeedId' = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $action.Properties.'Octopus.Action.Package.FeedId'
    }
}

function Convert-OctopusSinglePackageProprty
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    $actionScriptTypes = Get-OctopusScriptActionTypes

    if ($action.Packages.Count -eq 1 -and $actionScriptTypes -notcontains $action.ActionType)
    {
        Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.Package.FeedId" -propertyValue $action.Packages[0].FeedId
        Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.Package.PackageId" -propertyValue $action.Packages[0].PackageId
        Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.Package.DownloadOnTentacle" -propertyValue "False"
    }
}

function Convert-OctopusActionIdsForMatchingActionId
{
    param(
        $action,
        $matchingAction
    )

    if ($null -ne $matchingAction)
    {
        Write-OctopusVerbose "The action $($action.Name) already exists, updating the Id"
        $action.Id = $matchingAction.Id

        Write-OctopusVerbose "Ensuring all the existing packages have Ids"
        foreach ($package in $action.Packages)    
        {
            foreach ($matchingActionPackage in $matchingAction.Packages)
            {
                if ($package.PackageId -eq $matchingActionPackage.PackageId)
                {
                    $package.Id = $matchingActionPackage.Id
                    break
                }
            }
        }
    }
}