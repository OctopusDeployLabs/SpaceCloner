param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,
    $ProjectsToClone,    
    $EnvironmentsToExclude,                                      
    $WorkersToExclude,
    $TargetsToExclude,    
    $TenantsToExclude,    
    $OverwriteExistingVariables,
    $AddAdditionalVariableValuesOnExistingVariableSets,
    $OverwriteExistingCustomStepTemplates,
    $OverwriteExistingLifecyclesPhases,
    $CloneProjectRunbooks,
    $CloneTeamUserRoleScoping,
    $CloneProjectChannelRules,
    $CloneProjectVersioningReleaseCreationSettings  
)

. ($PSScriptRoot + ".\src\Core\Logging.ps1")
. ($PSScriptRoot + ".\src\Core\Util.ps1")

. ($PSScriptRoot + ".\src\DataAccess\OctopusDataAdapter.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusDataFactory.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusRepository.ps1")

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName

$cloneSpaceCommandLineOptions = @{
    EnvironmentsToClone = @(); #done
    WorkerPoolsToClone = @(); #done
    ProjectGroupsToClone = @(); #done
    TenantTagsToClone = @(); 
    ExternalFeedsToClone = @(); #done
    StepTemplatesToClone = @(); #done
    InfrastructureAccountsToClone = @(); 
    LibraryVariableSetsToClone = @(); #done 
    LifeCyclesToClone = @(); #done
    ScriptModulesToClone = @(); #done
    MachinePoliciesToClone = @(); #done
    WorkersToClone = @(); #done
    TargetsToClone = @(); #done
    TenantsToClone = @();
    SpaceTeamsToClone = @(); #done
    PackagesToClone = @(); #done
    RolesToClone = @(); #done
}

function Get-OctopusIsInExclusionList
{
    param(
        $exclusionList, 
        $itemName)

    foreach ($item in $exclusionList)
    {
        if ($item.Name -eq $itemName)
        {
            return $true
        }
    }

    return $false
}

function Add-OctopusIdToCloneList
{
    param(
        $itemId,
        $destinationList,
        $sourceList,
        $exclusionFilter,
        $itemType
    )

    $exclusionList = Get-OctopusExclusionList -itemList $sourceList -itemType $itemType -filters $exclusionFilter
    $matchingItem = Get-OctopusItemById -ItemList $sourceList -ItemId $itemId

    if ($null -ne $matchingItem)
    {
        $matchingItemName = $matchingItem.Name
        if ($destinationList -notcontains $matchingItemName -and (Get-OctopusIsInExclusionList -exclusionList $exclusionList -itemName $matchingItemName) -eq $false )
        {
            $destinationList += $matchingItemName
        }
    }
}

function Add-OctopusActionWorkerPoolIdToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    if ((Test-OctopusObjectHasProperty -objectToTest $action -propertyName "WorkerPoolId"))
    {
        if ($null -ne $action.WorkerPoolId)
        {
            Write-OctopusSuccess "Adding workerpool ${$action.Name}"
            Add-OctopusIdToCloneList -itemId $action.WorkerPoolId -itemType "Worker Pool" -destinationList $cloneSpaceCommandLineOptions.WorkerPoolsToClone -sourceList $sourceData.WorkerPoolList -exclusionFilter $null
        }
    }
}

function Add-OctopusActionEnvironmentsToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    Write-OctopusSuccess "Getting Environments for ${$step.Name}"
    foreach ($environment in $action.Environments)
    {
        Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionFilter $EnvironmentsToExclude
    }

    foreach ($environment in $action.ExcludedEnvironments)
    {
        Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionFilter $EnvironmentsToExclude
    }
}

function Add-OctopusActionStepTemplateToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Template.Id")
    {                                        
        Write-OctopusSuccess "${$action.Name} is a step template adding the step template to the list"
        Add-OctopusIdToCloneList -itemId $action.Properties.'Octopus.Action.Template.Id' -itemType "Step Template" -destinationList $cloneSpaceCommandLineOptions.StepTemplatesToClone -sourceList $sourceData.StepTemplates -exclusionFilter $null
        Add-OctopusIdToCloneList -itemId $action.Properties.'Octopus.Action.Template.Id' -itemType "Step Template" -destinationList $cloneSpaceCommandLineOptions.StepTemplatesToClone -sourceList $sourceData.CommunityActionTemplates -exclusionFilter $null                
    }
}

function Add-OctopusActionPackagesToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    foreach ($package in $action.Packages)
    {
        Write-OctopusSuccess "Adding Feed for ${$package.PackageId} to the list"
        Add-OctopusIdToCloneList -itemId $package.FeedId -itemType "Feed" -destinationList $cloneSpaceCommandLineOptions.ExternalFeedsToClone -sourceList $sourceData.FeedList -exclusionFilter $EnvironmentsToExclude
        $feed = Get-OctopusItemById -itemId $package.FeedId -ItemList $sourceData.FeedList

        if ($feed.FeedType -eq "BuiltIn" -and $cloneSpaceCommandLineOptions.PackagesToClone -notcontains $package.PackageId)
        {
            Write-OctopusSuccess "The feed for ${$package.PackageId} is the internal feed, adding that package to the clone list"
            $cloneSpaceCommandLineOptions.PackagesToClone += $package.PackageId
        }
    }
}

function Add-OctopusStepRolesToCloneList
{
    param (
        $step,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    if (Test-OctopusObjectHasProperty -objectToTest $step.Properties -propertyName "Octopus.Action.TargetRoles")
    {
        $roleList = @($action.Properties.'Octopus.Action.TargetRoles' -split ",")
        foreach ($role in $roleList)
        {
            if ($cloneSpaceCommandLineOptions.RolesToClone -notcontains $role)
            {
                Write-OctopusSuccess "The step ${$step.Name} is associated with role $role.  Adding that to list to use for determining which machines to clone"
                $cloneSpaceCommandLineOptions.RolesToClone += $role
            }
        }
    }    
}

function Add-OctopusActionSpaceTeamToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Manual.ResponsibleTeamIds")
    {
        $manualInterventionSourceTeamIds = @($action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' -split ",")
        foreach ($team in $manualInterventionSourceTeamIds)
        {
            Write-OctopusSuccess "Adding $team to clone list"
            Add-OctopusIdToCloneList -itemId $team -itemType "Space Team" -destinationList $cloneSpaceCommandLineOptions.SpaceTeamsToClone -sourceList $sourceData.TeamList -exclusionFilter $null
        }        
    }
}

function Add-OctopusDeploymentProcessToCloneList
{
    param (
        $sourceDeploymentProcess,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    foreach ($step in $sourceDeploymentProcess.Steps)
    {
        Add-OctopusStepRolesToCloneList -step $step -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions

        foreach ($action in $step.Actions)
        {
            Add-OctopusActionSpaceTeamToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionPackagesToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionStepTemplateToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionEnvironmentsToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionWorkerPoolIdToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
        }
    }
}

function Add-OctopusVariableSetItemsToCloneList
{
    param (
        $variableSet,
        $sourceData,
        $cloneSpaceCommandLineOptions,
        $environmentsToExclude
    )

    foreach ($octopusVariable in $sourceVariableSetVariables.Variables)
    {                             
        $variableName = $octopusVariable.Name        
        
        if (Get-Member -InputObject $octopusVariable.Scope -Name "Environment" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has environment scoping, adding each item to the clone list"
            foreach ($environment in $octopusVariable.Scope.Environment)
            {
                Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionFilter $EnvironmentsToExclude
            }            
        }     

        if ($octopusVariable.Type -match ".*Account")
        {
            Write-OctopusVerbose "$variableName is an account, adding each item to the clone list"
            Add-OctopusIdToCloneList -itemId $octopusVariable.Value -itemType "Infrastructure Account" -destinationList $cloneSpaceCommandLineOptions.InfrastructureAccountsToClone -sourceList $sourceData.InfrastructureAccounts -exclusionFilter $null            
        }

        if ($octopusVariable.Type -match "WorkerPool")
        {
            Write-OctopusVerbose "$variableName is a workerpool, adding each item to the clone list"
            Add-OctopusIdToCloneList -itemId $octopusVariable.Value -itemType "Worker Pool" -destinationList $cloneSpaceCommandLineOptions.WorkerPoolsToClone -sourceList $sourceData.WorkerPoolList -exclusionFilter $null            
        }
    }
}

function Add-OctopusLifeCycleEnvironmentsToCloneList
{
    param (
        $cloneSpaceCommandLineOptions,
        $sourceData,
        $environmentsToExclude
    )

    Write-OctopusSuccess "Adding environments based on project lifecycles"
    foreach ($lifeCycleName in $cloneSpaceCommandLineOptions.LifeCyclesToClone)
    {
        $lifeCycle = Get-OctopusItemByName -ItemName $lifeCycleName -ItemList $sourceData.LifeCycleList
        foreach ($phase in $lifeCycle)
        {    
            foreach ($environment in $phase.AutomaticDeploymentTargets)
            {
                Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionFilter $EnvironmentsToExclude
            }

            foreach ($environment in $phase.OptionalDeploymentTargets)
            {
                Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionFilter $EnvironmentsToExclude
            }
        }
    }
}

function Add-OctopusTargetsToCloneList
{
    param (
        $cloneSpaceCommandLineOptions,
        $sourceData,
        $TargetsToExclude
    )

    Write-OctopusSuccess "Adding targets based on project roles"
    $targetExclusionList = Get-OctopusExclusionList -itemList $sourceData.TargetList -itemType $"Targets" -filters $TargetsToExclude
    Foreach ($role in $cloneSpaceCommandLineOptions.RolesToClone)
    {
        foreach ($target in $sourceData.TargetList)
        {
            if ($target.Roles -contains $role -and $cloneSpaceCommandLineOptions.TargetsToClone -notcontains $target.Name -and (Get-OctopusIsInExclusionList -exclusionList $targetExclusionList -itemName $target.Name) -eq $false)
            {       
                $hasMatchingEnvironment = $false     
                foreach ($environmentName in $cloneSpaceCommandLineOptions.EnvironmentsToClone)
                {
                    $environmentId = Get-OctopusItemByName -ItemName $environmentName -ItemList $sourceData.EnvironmentList
                    if ($target.Environments -contains $environmentId)
                    {
                        $hasMatchingEnvironment = $true
                        continue
                    }
                }

                if ($hasMatchingEnvironment -eq $true)
                {
                    $cloneSpaceCommandLineOptions.TargetsToClone += $target.Name

                    $machinePolicy = Get-OctopusItemById -itemId $target.MachinePolicyId -itemList $sourceData.MachinePolicyList
                    if ($cloneSpaceCommandLineOptions.MachinePoliciesToClone -notcontains $machinePolicy.Name)
                    {
                        $cloneSpaceCommandLineOptions.MachinePoliciesToClone += $machinePolicy.Name
                    }
                }            
            }
        }
    }
}

function Add-OctopusWorkersToCloneList
{
    param (
        $cloneSpaceCommandLineOptions,
        $sourceData,
        $workersToExclude
    )

    Write-OctopusSuccess "Adding workers based on project variables and steps"
    $workerExclusionList = Get-OctopusExclusionList -itemList $sourceData.WorkerList -itemType $"Workers" -filters $WorkersToExclude
    Foreach ($workerPoolName in $cloneSpaceCommandLineOptions.WorkerPoolsToClone)
    {
        foreach ($worker in $sourceData.WorkerList)
        {
            $workerPool = Get-OctopusItemByName -ItemName $workerPoolName -ItemList $sourceData.WorkerList

            if ($worker.WorkerPoolIds -contains $WorkerPool.Id -and $cloneSpaceCommandLineOptions.WorkersToClone -notcontains $target.Name -and (Get-OctopusIsInExclusionList -exclusionList $workerExclusionList -itemName $worker.Name) -eq $false)
            {            
                $cloneSpaceCommandLineOptions.WorkersToClone += $worker.Name

                $machinePolicy = Get-OctopusItemById -itemId $worker.MachinePolicyId -itemList $sourceData.MachinePolicyList
                if ($cloneSpaceCommandLineOptions.MachinePoliciesToClone -notcontains $machinePolicy.Name)
                {
                    $cloneSpaceCommandLineOptions.MachinePoliciesToClone += $machinePolicy.Name
                }
            }
        }
    }
}

function Add-OctopusTenantsToCloneList
{
    param (
        $cloneSpaceCommandLineOptions,
        $sourceData,
        $tenantExclusionList,
        $project
    )

    foreach ($tenant in $sourceData.TenantList)
    {
        if ((Test-OctopusObjectHasProperty -objectToTest $tenant.ProjectEnvironments -propertyName $project.Id) -and $cloneSpaceCommandLineOptions.TenantList -notcontains $tenant.Name -and (Get-OctopusIsInExclusionList -exclusionList $tenantListToExclude -itemName $tenant.Name) -eq $false)
        {
            $cloneSpaceCommandLineOptions.TenantsToClone += $tenant.Name    

            foreach ($tag in $tenant.TenantTags)
            {
                $tagDetails = $tag -split "/"

                if ($cloneSpaceCommandLineOptions.TenantTagsToClone -notcontains $tagDetails[0])
                {
                    $cloneSpaceCommandLineOptions.TenantsToClone += $tagDetails[0]
                }
            }
        }
    }
}

$projectListToClone = Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $ProjectsToClone
$tenantListToExclude = Get-OctopusExclusionList -itemList $sourceData.TenantList -itemType "Tenants" -filters $TenantsToExclude

foreach ($project in $projectListToClone)
{
    Write-OctopusSuccess "Adding variable sets for ${$project.Name}"
    foreach ($variableSetId in $project.IncludedLibraryVaraibleSetIds)
    {        
        $variableSet = Get-OctopusItemById -itemId $variableSetId -itemList $sourceData.VariableSetList

        if ($variableSet.ContentType -eq "ScriptModule")
        {
            Add-OctopusIdToCloneList -itemId $variableSetId -itemType "Script Module" -destinationList $cloneSpaceCommandLineOptions.ScriptModulesToClone -sourceList $sourceData.ScriptModuleList -exclusionFilter $null
        }
        else
        {
            Add-OctopusIdToCloneList -itemId $variableSetId -itemType "Library Variable Set" -destinationList $cloneSpaceCommandLineOptions.LibraryVariableSetsToClone -sourceList $sourceData.VariableSetList -exclusionFilter $null
            $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $variableSet -OctopusData $sourceData
            Add-OctopusVariableSetItemsToCloneList -variableSet $sourceVariableSetVariables -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -environmentsToExclude $environmentsToExclude
        }        
    }

    Write-OctopusSuccess "Adding project group ${$project.Name}"
    Add-OctopusIdToCloneList -itemId $project.ProjectGroupId -itemType "Project Group" -destinationList $cloneSpaceCommandLineOptions.ProjectGroupsToClone -sourceList $sourceData.ProjectGroupList -exclusionFilter $null

    Write-OctopusSuccess "Adding default lifecycle for ${$project.Name}"
    Add-OctopusIdToCloneList -itemId $project.LifeCycleId -itemType "Lifecycle" -destinationList $cloneSpaceCommandLineOptions.LifeCyclesToClone -sourceList $sourceData.LifeCycleList -exclusionFilter $null

    Write-OctopusSuccess "Getting deployment process for ${$project.Name}"
    $sourceDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $project -OctopusData $sourceData

    Write-OctopusSuccess "Cloning the deployment process for ${$project.Name}"
    Add-OctopusDeploymentProcessToCloneList -sourceData $sourceData -sourceDeploymentProcess $sourceDeploymentProcess -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions

    if ($sourceData.HasRunbooks -eq $true)
    {
        Write-OctopusSuccess "Getting Runbooks for ${$Project.Name}"
        $sourceRunbooks = Get-OctopusProjectRunbookList -project $project -OctopusData $sourceData

        foreach ($runbook in $sourceRunbooks)
        {
            Write-OctopusSuccess "Getting the deployment process for ${$runbook.Name}"
            $sourceRunbookProcess = Get-OctopusRunbookProcess -runbook $runbook -OctopusData $sourceData
            Add-OctopusDeploymentProcessToCloneList -sourceData $sourceData $sourceDeploymentProcess $sourceRunbookProcess -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
        }
    }

    $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $project -OctopusData $sourceData
    Add-OctopusVariableSetItemsToCloneList -variableSet $sourceVariableSetVariables -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -environmentsToExclude $environmentsToExclude

    $sourceChannels = Get-OctopusProjectChannelList -project $project -octopusData $sourceData
    foreach ($channel in $sourceChannels)
    {
        if ($null -ne $channel.LifeCycleId)
        {
            Write-OctopusSuccess "Adding lifecycle for channel name ${$channel.Name} in ${$project.Name}"
            Add-OctopusIdToCloneList -itemId $channel.LifeCycleId -itemType "Lifecycle" -destinationList $cloneSpaceCommandLineOptions.LifeCyclesToClone -sourceList $sourceData.LifeCycleList -exclusionFilter $null
        }
    }

    Add-OctopusTenantsToCloneList -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -sourceData $sourceData -tenantExclusionList $tenantExclusionList -project $project
}

Add-OctopusLifeCycleEnvironmentsToCloneList -environmentsToExclude $environmentsToExclude -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
Add-OctopusTargetsToCloneList -TargetsToExclude $TargetsToExclude -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
Add-OctopusWorkersToCloneList -workersToExclude $WorkersToExclude -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
