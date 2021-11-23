param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,
    $ProjectsToClone,    
    $CertificatesToClone,
    $EnvironmentsToExclude,
    $EnvironmentsToInclude,                                      
    $WorkersToExclude,
    $WorkersToInclude,
    $TargetsToExclude,    
    $TargetsToInclude,
    $TenantsToExclude,
    $TenantsToInclude,
    $ChannelsToInclude,
    $ChannelsToExclude,    
    $LibraryVariableSetsToInclude,
    $LibraryVariableSetsToExclude,
    $OverwriteExistingVariables,    
    $OverwriteExistingCustomStepTemplates,
    $OverwriteExistingLifecyclesPhases,
    $CloneProjectRunbooks,
    $CloneTeamUserRoleScoping,
    $CloneProjectChannelRules,
    $CloneProjectVersioningReleaseCreationSettings,
    $CloneProjectDeploymentProcess, 
    $CloneProjectLogos,
    $CloneTenantLogos,    
    $CloneTenantVariables,
    $CloneStepTemplateLogos,
    $ClonePackages,    
    $ProcessEnvironmentScopingMatch,
    $ProcessChannelScopingMatch,
    $ProcessTenantTagScopingMatch,
    $VariableChannelScopingMatch,
    $VariableEnvironmentScopingMatch,
    $VariableProcessOwnerScopingMatch,
    $VariableActionScopingMatch,
    $VariableMachineScopingMatch,
    $VariableAccountScopingMatch,
    $VariableCertificateScopingMatch,
    $VariableTenantTagScopingMatch,
    $VariableWorkerPoolScopingMatch,
    $InfrastructureEnvironmentScopingMatch,
    $InfrastructureTenantScopingMatch,
    $InfrastructureTenantTagScopingMatch,
    $ProcessCloningOption,
    $IgnoreVersionCheckResult,
    $SkipPausingWhenIgnoringVersionCheckResult,
    $WhatIf  
)

$ErrorActionPreference = "Stop"

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Logging.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Util.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "FilteredLists.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "ParameterVerification.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataAdapter.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataFactory.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusRepository.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusFakeFactory.ps1"))

$OverwriteExistingVariables = Test-OctopusOverwriteExistingVariablesParameter -parameterValue $OverwriteExistingVariables -parameterName "OverwriteExistingVariables" -defaultValue $false
$OverwriteExistingCustomStepTemplates = Test-OctopusTrueFalseParameter -parameterValue $OverwriteExistingCustomStepTemplates -parameterName "OverwriteExistingCustomStepTemplates" -defaultValue $false
$OverwriteExistingLifecyclesPhases = Test-OctopusOverwriteExistingLifecyclesPhasesParameter -parameterValue $OverwriteExistingLifecyclesPhases

$CloneProjectRunbooks = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectRunbooks -parameterName "CloneProjectRunbooks" -defaultValue $true
$CloneTeamUserRoleScoping = Test-OctopusTrueFalseParameter -parameterValue $CloneTeamUserRoleScoping -parameterName "CloneTeamUserRoleScoping" -defaultValue $false
$CloneProjectChannelRules = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectChannelRules -parameterName "CloneProjectChannelRules" -defaultValue $false
$CloneProjectVersioningReleaseCreationSettings = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectVersioningReleaseCreationSettings -parameterName "CloneProjectVersioningReleaseCreationSettings" -defaultValue $false
$CloneProjectDeploymentProcess = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectDeploymentProcess -parameterName "CloneProjectDeploymentProcess" -defaultValue $true
$CloneProjectLogos = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectLogos -parameterName "CloneProjectLogos" -defaultValue $true
$CloneTenantLogos = Test-OctopusTrueFalseParameter -parameterValue $CloneTenantLogos -parameterName "CloneTenantLogos" -defaultValue $true
$CloneStepTemplateLogos = Test-OctopusTrueFalseParameter -parameterValue $CloneStepTemplateLogos -parameterName "CloneStepTemplateLogos" -defaultValue $true
$CloneTenantVariables = Test-OctopusTrueFalseParameter -parameterValue $CloneTenantVariables -parameterName "CloneTenantVariables" -defaultValue $false
$ClonePackages = Test-OctopusTrueFalseParameter -parameterValue $ClonePackages -parameterName "ClonePackages" -defaultValue $false

$ProcessEnvironmentScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "ProcessEnvironmentScopingMatch" -ParameterValue $ProcessEnvironmentScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$ProcessChannelScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "ProcessChannelScopingMatch" -ParameterValue $ProcessChannelScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$ProcessTenantTagScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "ProcessTenantTagScopingMatch" -ParameterValue $ProcessTenantTagScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false

$VariableChannelScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableChannelScopingMatch" -ParameterValue $VariableChannelScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableEnvironmentScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableEnvironmentScopingMatch" -ParameterValue $VariableEnvironmentScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableProcessOwnerScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableProcessOwnerScopingMatch" -ParameterValue $VariableProcessOwnerScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableActionScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableActionScopingMatch" -ParameterValue $VariableActionScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableMachineScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableMachineScopingMatch" -ParameterValue $VariableMachineScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableAccountScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableAccountScopingMatch" -ParameterValue $VariableAccountScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true
$VariableCertificateScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableCertificateScopingMatch" -ParameterValue $VariableCertificateScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true
$VariableTenantTagScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableTenantTagScopingMatch" -ParameterValue $VariableTenantTagScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableWorkerPoolScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableWorkerPoolScopingMatch" -ParameterValue $VariableWorkerPoolScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true

$InfrastructureEnvironmentScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "InfrastructureEnvironmentScopingMatch" -ParameterValue $InfrastructureEnvironmentScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$InfrastructureTenantScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "InfrastructureTenantScopingMatch" -ParameterValue $InfrastructureTenantScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$InfrastructureTenantTagScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "InfrastructureTenantTagScopingMatch" -ParameterValue $InfrastructureTenantTagScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false

$IgnoreVersionCheckResult = Test-OctopusTrueFalseParameter -parameterValue $IgnoreVersionCheckResult -parameterName "IgnoreVersionCheckResult" -defaultValue $false
$SkipPausingWhenIgnoringVersionCheckResult = Test-OctopusTrueFalseParameter -parameterValue $SkipPausingWhenIgnoringVersionCheckResult -parameterName "SkipPausingWhenIgnoringVersionCheckResult" -defaultValue $false
$WhatIf = Test-OctopusTrueFalseParameter -parameterValue $WhatIf -parameterName "WhatIf" -defaultValue $false

$EnvironmentsToInclude = Test-OctopusIncludeExcludeFilterParameter -includeFilters $EnvironmentsToInclude -excludeFilters $EnvironmentsToExclude -parameterName "Environments" -DefaultIncludeFilter "all"
$WorkersToInclude = Test-OctopusIncludeExcludeFilterParameter -includeFilters $WorkersToInclude -excludeFilters $WorkersToExclude -parameterName "Worker" -DefaultIncludeFilter "$null"
$TargetsToInclude = Test-OctopusIncludeExcludeFilterParameter -includeFilters $TargetsToInclude -excludeFilters $TargetsToExclude -parameterName "Target" -DefaultIncludeFilter "$null"
$TenantsToInclude = Test-OctopusIncludeExcludeFilterParameter -includeFilters $TenantsToInclude -excludeFilters $TenantsToExclude -parameterName "Tenants" -DefaultIncludeFilter "all"
$ChannelsToInclude = Test-OctopusIncludeExcludeFilterParameter -includeFilters $ChannelsToInclude -excludeFilters $ChannelsToExclude -parameterName "Channels" -DefaultIncludeFilter "all"
$LibraryVariableSetsToInclude = Test-OctopusIncludeExcludeFilterParameter -includeFilters $LibraryVariableSetsToInclude -excludeFilters $LibraryVariableSetsToExclude -parameterName "Library Variable Sets" -DefaultIncludeFilter "all"

$cloneSpaceCommandLineOptions = @{
    EnvironmentsToClone = $null;
    WorkerPoolsToClone = $null;
    ProjectGroupsToClone = $null;
    TenantTagsToClone = "all";
    ExternalFeedsToClone = "all";
    StepTemplatesToClone = $null;
    InfrastructureAccountsToClone = $null; 
    LibraryVariableSetsToClone = $null; 
    LifeCyclesToClone = $null;
    ScriptModulesToClone = $null;
    MachinePoliciesToClone = $null;
    WorkersToClone = $null;
    TargetsToClone = $null;
    TenantsToClone = $null;
    SpaceTeamsToClone = $null;    
    RolesToClone = $null;
    PackagesToClone = $null;
    ChannelsToClone = $null;
    CertificatesToClone = $CertificatesToClone;
    ClonePackages = $clonePackages;
    ProjectsToClone = $null;
}

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName -whatIf $whatIf

function Get-OctopusIsInExclusionList
{
    param(
        $exclusionList, 
        $itemName)

    foreach ($item in $exclusionList)
    {
        Write-OctopusVerbose "Checking to see if $($item.Name) is equal to $itemName for exclusion list"
        if ($item.Name.ToLower().Trim() -eq $itemName.ToLower().Trim())
        {
            Write-OctopusVerbose "  The items match"
            return $true
        }
    }

    Write-OctopusVerbose "The item $itemName was not found in the exclusion list"
    return $false
}

function Get-OctopusInExistingList
{
    param(
        $existingList,
        $itemName
    )

    foreach ($existingItem in $existingList)
    {
        Write-OctopusVerbose "Checking to see if $existingItem is equal to $itemName for existing list"
        if ($existingItem -eq $itemName)
        {
            Write-OctopusVerbose "  The items match"
            return $true
        }        
    }

    Write-OctopusVerbose "The item $itemName was not found in the existing list"
    return $false
}

function Add-OctopusIdToCloneList
{
    param(
        $itemId,
        $destinationList,
        $sourceList,        
        $exclusionList
    )
    
    $matchingItem = Get-OctopusItemById -ItemList $sourceList -ItemId $itemId
    
    if ($null -eq $matchingItem)
    {
        Write-OctopusVerbose "The matching item for $itemId could not be found"
        return $destinationList
    }

    $matchingItemName = $matchingItem.Name

    if (Get-OctopusIsInExclusionList -exclusionList $exclusionList -itemName $matchingItemName)
    {
        Write-OctopusVerbose "The item $matchingItemName is in the exclusion list, skipping"
        return $destinationList
    }

    return Add-OctopusNameToCloneList -itemName $matchingItemName -destinationList $destinationList    
}

function Add-OctopusPackageIdToCloneList
{
    param(
        $itemId,
        $destinationList,
        $sourceList,        
        $exclusionList
    )
    
    $matchingItem = Get-OctopusItemByPackageId -ItemList $sourceList -ItemPackageId $itemId
    
    if ($null -eq $matchingItem)
    {
        Write-OctopusVerbose "The matching item for $itemId could not be found"
        return $destinationList
    }

    $matchingItemName = $matchingItem.PackageId

    if (Get-OctopusIsInExclusionList -exclusionList $exclusionList -itemName $matchingItemName)
    {
        Write-OctopusVerbose "The item $matchingItemName is in the exclusion list, skipping"
        return $destinationList
    }

    return Add-OctopusNameToCloneList -itemName $matchingItemName -destinationList $destinationList    
}

function Add-OctopusNameToCloneList
{
    param(
        $itemName,
        $destinationList        
    )

    $newDestinationList = $destinationList -split ","
    if (Get-OctopusInExistingList -existingList $newDestinationList -itemName $itemName)
    {
        Write-OctopusVerbose "      The item $itemName was already in the destination list, skipping"
        return $destinationList
    }

    Write-OctopusVerbose "      The item $itemName was not found in exclusion or destination list, adding."
    if ($null -eq $destinationList)
    {
        return $itemName
    }

    $newDestinationList += $itemName            

    return $newDestinationList -join ","
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
            Write-OctopusSuccess "Adding workerpool $($action.Name)"
            $cloneSpaceCommandLineOptions.WorkerPoolsToClone = Add-OctopusIdToCloneList -itemId $action.WorkerPoolId -itemType "Worker Pool" -destinationList $cloneSpaceCommandLineOptions.WorkerPoolsToClone -sourceList $sourceData.WorkerPoolList -exclusionList @()
        }
    }
}

function Add-OctopusActionEnvironmentsToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions,
        $envrionmentListToExclude
    )

    Write-OctopusVerbose "Getting Environments for $($step.Name)"
    foreach ($environment in $action.Environments)
    {
        $cloneSpaceCommandLineOptions.EnvironmentsToClone = Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionList $envrionmentListToExclude
    }

    foreach ($environment in $action.ExcludedEnvironments)
    {
        $cloneSpaceCommandLineOptions.EnvironmentsToClone = Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionList $envrionmentListToExclude
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
        Write-OctopusVerbose "$($action.Name) is a step template adding the step template to the list"
        $cloneSpaceCommandLineOptions.StepTemplatesToClone = Add-OctopusIdToCloneList -itemId $action.Properties.'Octopus.Action.Template.Id' -itemType "Step Template" -destinationList $cloneSpaceCommandLineOptions.StepTemplatesToClone -sourceList $sourceData.StepTemplates -exclusionList @()        
    }
}

function Add-OctopusPackagesToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandLineOptions
    )

    if ($cloneSpaceCommandLineOptions.ClonePackages -eq $false)
    {
        return
    }

    foreach ($package in $action.Packages)
    {        
        $feed = Get-OctopusItemById -itemId $package.FeedId -ItemList $sourceData.FeedList               

        if ($feed.FeedType -eq "BuiltIn")
        {
            Write-OctopusVerbose "Adding the package $($package.PackageId) to the clone list"
            $cloneSpaceCommandLineOptions.PackagesToClone = Add-OctopusPackageIdToCloneList -itemId $package.PackageId -itemType "Package" -destinationList $cloneSpaceCommandLineOptions.PackagesToClone -sourceList $sourceData.PackageList -exclusionList @()            
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
            Write-OctopusSuccess "The step $($step.Name) is associated with role $role.  Adding that to list to use for determining which machines to clone."
            $cloneSpaceCommandLineOptions.RolesToClone = Add-OctopusNameToCloneList -ItemName $role -destinationList $cloneSpaceCommandLineOptions.RolesToCLone            
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
            $teamDetails = Get-OctopusItemById -ItemList $sourceData.TeamList -ItemId $team
            if ($null -eq $teamDetails.SpaceId)
            {
                Write-OctopusVerbose "The team $($teamDetails.Name) is a system team, skipping"
                continue
            }

            Write-OctopusVerbose "Adding $team to clone list"
            $cloneSpaceCommandLineOptions.SpaceTeamsToClone = Add-OctopusIdToCloneList -itemId $team -itemType "Space Team" -destinationList $cloneSpaceCommandLineOptions.SpaceTeamsToClone -sourceList $sourceData.TeamList -exclusionList @()
        }        
    }
}

function Add-OctopusActionSubProjectsToCloneList
{
    param (
        $action,
        $sourceData,
        $cloneSpaceCommandlineOptions
    )

    if ($action.ActionType -ne "Octopus.DeployRelease")
    {
        return
    }

    Write-OctopusVerbose "Adding the sub projects from the deploy a release step to the clone list."
    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.DeployRelease.ProjectId")
    {
        $projectToAdd = Get-OctopusItemById -ItemList $sourceData.ProjectList  -ItemId $action.Properties.'Octopus.Action.DeployRelease.ProjectId'
        if ($null -eq $projectToAdd)
        {
            Write-OctopusVerbose "Unable to find $($action.Properties.'Octopus.Action.DeployRelease.ProjectId')"
            return
        }

        Write-OctopusVerbose "Adding $($projectToAdd.Name) to the clone list"
        $cloneSpaceCommandLineOptions.ProjectsToClone = Add-OctopusNameToCloneList -ItemName $projectToAdd.Name -destinationList $cloneSpaceCommandLineOptions.ProjectsToClone
    }
}

function Add-OctopusDeploymentProcessToCloneList
{
    param (
        $sourceDeploymentProcess,
        $sourceData,
        $cloneSpaceCommandLineOptions,
        $envrionmentListToExclude        
    )

    foreach ($step in $sourceDeploymentProcess.Steps)
    {        
        Write-OctopusSuccess "      Pulling data for $($step.Name)"
        Add-OctopusStepRolesToCloneList -step $step -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions

        foreach ($action in $step.Actions)
        {
            Add-OctopusActionSpaceTeamToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusPackagesToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionStepTemplateToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionEnvironmentsToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -envrionmentListToExclude $envrionmentListToExclude
            Add-OctopusActionWorkerPoolIdToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
            Add-OctopusActionSubProjectsToCloneList -action $action -sourceData $sourceData -cloneSpaceCommandlineOptions $cloneSpaceCommandLineOptions
        }
    }
}

function Add-OctopusVariableSetItemsToCloneList
{
    param (
        $variableSet,
        $sourceData,
        $cloneSpaceCommandLineOptions,
        $envrionmentListToExclude,
        $sourceChannelList,
        $channelListToExclude
    )

    foreach ($octopusVariable in $sourceVariableSetVariables.Variables)
    {                             
        $variableName = $octopusVariable.Name        
        
        if (Get-Member -InputObject $octopusVariable.Scope -Name "Environment" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has environment scoping, adding each item to the clone list"
            foreach ($environment in $octopusVariable.Scope.Environment)
            {
                $cloneSpaceCommandLineOptions.EnvironmentsToClone = Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionList $envrionmentListToExclude
            }            
        }
        
        if (Get-Member -InputObject $octopusVariable.Scope -Name "Channel" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has channel scoping, adding each item to the clone list"
            foreach ($channel in $octopusVariable.Scope.Channel)
            {
                $cloneSpaceCommandLineOptions.ChannelsToClone = Add-OctopusIdToCloneList -itemId $channel -itemType "Channel" -destinationList $cloneSpaceCommandLineOptions.ChannelsToClone -sourceList $sourceChannelList -exclusionList $channelListToExclude
            }
        }

        if ($octopusVariable.Type -match ".*Account")
        {
            Write-OctopusVerbose "$variableName is an account, adding each item to the clone list"
            $cloneSpaceCommandLineOptions.InfrastructureAccountsToClone = Add-OctopusIdToCloneList -itemId $octopusVariable.Value -itemType "Infrastructure Account" -destinationList $cloneSpaceCommandLineOptions.InfrastructureAccountsToClone -sourceList $sourceData.InfrastructureAccounts -exclusionList @()
        }

        if ($octopusVariable.Type -match "WorkerPool")
        {
            Write-OctopusVerbose "$variableName is a workerpool, adding each item to the clone list"
            $cloneSpaceCommandLineOptions.WorkerPoolsToClone = Add-OctopusIdToCloneList -itemId $octopusVariable.Value -itemType "Worker Pool" -destinationList $cloneSpaceCommandLineOptions.WorkerPoolsToClone -sourceList $sourceData.WorkerPoolList -exclusionList @()
        }        
    }
}

function Add-OctopusLifeCycleEnvironmentsToCloneList
{
    param (
        $cloneSpaceCommandLineOptions,
        $sourceData,
        $envrionmentListToExclude
    )

    Write-OctopusSuccess "Adding environments based on project lifecycles"
    $lifeCycleList = $cloneSpaceCommandLineOptions.LifeCyclesToClone -split ","

    foreach ($lifeCycleName in $lifeCycleList)
    {
        $lifeCycle = Get-OctopusItemByName -ItemName $lifeCycleName -ItemList $sourceData.LifeCycleList
        foreach ($phase in $lifeCycle)
        {    
            foreach ($environment in $phase.AutomaticDeploymentTargets)
            {
                $cloneSpaceCommandLineOptions.EnvironmentsToClone = Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionList $envrionmentListToExclude
            }

            foreach ($environment in $phase.OptionalDeploymentTargets)
            {
                $cloneSpaceCommandLineOptions.EnvironmentsToClone = Add-OctopusIdToCloneList -itemId $environment -itemType "Environment" -destinationList $cloneSpaceCommandLineOptions.EnvironmentsToClone -sourceList $sourceData.EnvironmentList -exclusionList $envrionmentListToExclude
            }
        }
    }
}

function Add-OctopusTargetsToCloneList
{
    param (
        $cloneSpaceCommandLineOptions,
        $sourceData,
        $targetExclusionList
    )

    Write-OctopusSuccess "Adding targets based on project roles"
    $roleList = $cloneSpaceCommandLineOptions.RolesToClone -split ","
    Foreach ($role in $roleList)
    {
        foreach ($target in $sourceData.TargetList)
        {
            if ($target.Roles -contains $role -and (Get-OctopusIsInExclusionList -exclusionList $targetExclusionList -itemName $target.Name) -eq $false)
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
                    $cloneSpaceCommandLineOptions.TargetsToClone = Add-OctopusNameToCloneList -ItemName $target.Name -destinationList $cloneSpaceCommandLineOptions.TargetsToClone

                    $machinePolicy = Get-OctopusItemById -itemId $target.MachinePolicyId -itemList $sourceData.MachinePolicyList                    
                    $cloneSpaceCommandLineOptions.MachinePoliciesToClone = Add-OctopusNameToCloneList -ItemName $machinePolicy.Name -destinationList $cloneSpaceCommandLineOptions.MachinePoliciesToClone                                
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
        $workerExclusionList
    )

    if ([string]::IsNullOrWhiteSpace($WorkersToExclude) -eq $false -and $WorkersToExclude.ToLower().Trim() -eq "all")
    {
        return
    }

    Write-OctopusSuccess "Adding workers based on project variables and steps" 
    $workerPoolList = $cloneSpaceCommandLineOptions.WorkerPoolsToClone -split ","

    Foreach ($workerPoolName in $workerPoolList)
    {
        Write-OctopusSuccess "  Getting worker pool information for $workerPoolName"
        $workerPool = Get-OctopusItemByName -ItemName $workerPoolName -ItemList $sourceData.WorkerPoolList

        foreach ($worker in $sourceData.WorkerList)
        {            
            if (@($worker.WorkerPoolIds) -notcontains $WorkerPool.Id)
            {
                Write-OctopusVerbose "      The worker pool $($WorkerPool.Id) does not exist in $($Worker.WorkerPoolIds), skipping"
                continue
            }

            if (Get-OctopusIsInExclusionList -exclusionList $workerExclusionList -itemName $Worker.Name)
            {
                Write-OctopusVerbose "      The worker $($Worker.Name) is present in the exclusion list, skipping"
                continue
            }
            
            $cloneSpaceCommandLineOptions.WorkersToClone = Add-OctopusNameToCloneList -ItemName $worker.Name -destinationList $cloneSpaceCommandLineOptions.WorkersToClone

            $machinePolicy = Get-OctopusItemById -itemId $worker.MachinePolicyId -itemList $sourceData.MachinePolicyList
            $cloneSpaceCommandLineOptions.MachinePoliciesToClone = Add-OctopusNameToCloneList -ItemName $machinePolicy.Name -destinationList $cloneSpaceCommandLineOptions.MachinePoliciesToClone            
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
        if ((Test-OctopusObjectHasProperty -objectToTest $tenant.ProjectEnvironments -propertyName $project.Id) -and (Get-OctopusIsInExclusionList -exclusionList $tenantListToExclude -itemName $tenant.Name) -eq $false)
        {
            $cloneSpaceCommandLineOptions.TenantsToClone = Add-OctopusNameToCloneList -ItemName $tenant.Name -destinationList $cloneSpaceCommandLineOptions.TenantsToClone            
        }
    }
}

Write-OctopusSuccess "Building all the exclusion lists"
$tenantListToExclude = Get-OctopusExclusionList -itemList $sourceData.TenantList -itemType "Tenants" -filters $TenantsToExclude -includeFilters $TenantsToInclude
$envrionmentListToExclude = Get-OctopusExclusionList -itemList $sourceData.EnvironmentList -itemType "Environments" -filters $environmentsToExclude -includeFilters $EnvironmentsToInclude
$workerListToExclude = Get-OctopusExclusionList -itemList $sourceData.WorkerList -itemType "Workers" -filters $WorkersToExclude -includeFilters $WorkersToInclude
$targetListToExclude = Get-OctopusExclusionList -itemList $sourceData.TargetList -itemType "Targets" -filters $TargetsToExclude -includeFilters $TargetsToInclude
$variableSetListToExclude = Get-OctopusExclusionList -itemList $sourceData.VariableSetList -itemType "Library Variable Sets" -filters $LibraryVariableSetsToExclude -includeFilters $LibraryVariableSetsToInclude

Write-OctopusSuccess "Building all project list to clone"
$projectListToClone = @(Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $ProjectsToClone)

for ($i = 0; $i -lt $projectListToClone.Count; $i++) 
{
    $project = $projectListToClone[$i]

    Write-OctopusSuccess "Starting $($project.Name)"
    Write-OctopusSuccess "  Adding variable sets for $($project.Name)"
    foreach ($variableSetId in $project.IncludedLibraryVariableSetIds)
    {        
        Write-OctopusSuccess "      Attempting to find variableSetId $variableSetId in VariableSetList"
        $variableSet = Get-OctopusItemById -itemId $variableSetId -itemList $sourceData.VariableSetList

        Write-OctopusSuccess "      Attempting to find variableSetId $variableSetId in ScriptModuleList"
        $scriptModule = Get-OctopusItemById -itemId $variableSetId -itemList $sourceData.ScriptModuleList

        if ($null -ne $scriptModule)
        {
            Write-OctopusSuccess "      Adding the script module $($scriptModule.Name) to the items script modules to clone"
            $cloneSpaceCommandLineOptions.ScriptModulesToClone = Add-OctopusIdToCloneList -itemId $variableSetId -itemType "Script Module" -destinationList $cloneSpaceCommandLineOptions.ScriptModulesToClone -sourceList $sourceData.ScriptModuleList -exclusionList @()
        }
        elseif ($null -ne $variableSet)
        {
            if (Get-OctopusIsInExclusionList -exclusionList $variableSetListToExclude -itemName $($variableSet.Name))
            {
                Write-OctopusVerbose "      The variable set $($variableSet.Name) was in the exclusion list, skipping."
                continue
            }
            
            Write-OctopusSuccess "      Adding the variable set $($variableSet.Name) to the items variable sets to clone"
            $cloneSpaceCommandLineOptions.LibraryVariableSetsToClone = Add-OctopusIdToCloneList -itemId $variableSetId -itemType "Library Variable Set" -destinationList $cloneSpaceCommandLineOptions.LibraryVariableSetsToClone -sourceList $sourceData.VariableSetList -exclusionList @()
            $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $variableSet -OctopusData $sourceData
            Add-OctopusVariableSetItemsToCloneList -variableSet $sourceVariableSetVariables -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -envrionmentListToExclude $envrionmentListToExclude -channelListToExclude @() -sourceChannelList @()
        }        
    }

    Write-OctopusSuccess "  Adding project group $($project.Name)"
    $cloneSpaceCommandLineOptions.ProjectGroupsToClone = Add-OctopusIdToCloneList -itemId $project.ProjectGroupId -itemType "Project Group" -destinationList $cloneSpaceCommandLineOptions.ProjectGroupsToClone -sourceList $sourceData.ProjectGroupList -exclusionList @()

    Write-OctopusSuccess "  Adding default lifecycle for $($project.Name)"
    $cloneSpaceCommandLineOptions.LifeCyclesToClone = Add-OctopusIdToCloneList -itemId $project.LifeCycleId -itemType "Lifecycle" -destinationList $cloneSpaceCommandLineOptions.LifeCyclesToClone -sourceList $sourceData.LifeCycleList -exclusionList @()        

    Write-OctopusSuccess "  Getting the deployment process for $($project.Name)"
    $sourceDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $project -OctopusData $sourceData
    $beforeProjectCloneList = $cloneSpaceCommandLineOptions.ProjectsToClone
    Add-OctopusDeploymentProcessToCloneList -sourceData $sourceData -sourceDeploymentProcess $sourceDeploymentProcess -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -envrionmentListToExclude $envrionmentListToExclude -clonePackages $ClonePackages

    if ($beforeProjectCloneList -ne $cloneSpaceCommandLineOptions.ProjectsToClone)
    {
        Write-OctopusSuccess "The projects to clone list has changed, updating the array to include additional projects"
        $newProjectList = Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $cloneSpaceCommandLineOptions.ProjectsToClone
        foreach ($newProject in $newProjectList)
        {
            $existingProject = $projectListToClone | Where-Object {$_.Id -eq $newProject.Id}
            if ($null -eq $existingProject)
            {
                $projectListToClone += $newProject
            }
        }
    }

    if ($sourceData.HasRunbooks -eq $true)
    {
        Write-OctopusSuccess "  Getting Runbooks for $($Project.Name)"
        $sourceRunbooks = Get-OctopusProjectRunbookList -project $project -OctopusData $sourceData

        foreach ($runbook in $sourceRunbooks)
        {
            Write-OctopusSuccess "  Getting the deployment process for $($runbook.Name)"
            $sourceRunbookProcess = Get-OctopusRunbookProcess -runbook $runbook -OctopusData $sourceData
            Add-OctopusDeploymentProcessToCloneList -sourceData $sourceData -sourceDeploymentProcess $sourceRunbookProcess -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
        }
    }

    $sourceChannels = Get-OctopusProjectChannelList -project $project -octopusData $sourceData
    $channelExclusionList = Get-OctopusExclusionList -itemList $sourceChannels -itemType "Channels" -filters $ChannelsToExclude -includeFilters $ChannelsToInclude

    $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $project -OctopusData $sourceData
    Add-OctopusVariableSetItemsToCloneList -variableSet $sourceVariableSetVariables -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -envrionmentListToExclude $envrionmentListToExclude -channelListToExclude $channelExclusionList -sourceChannelList $sourceChannels

    foreach ($channel in $sourceChannels)
    {
        if (Get-OctopusIsInExclusionList -exclusionList $channelExclusionList -itemName $channel.Name)
        {
            Write-OctopusVerbose "The channel $($channel.Name) was in the exclusion list, moving onto the next channel"
            continue
        }

        $cloneSpaceCommandLineOptions.ChannelsToClone = Add-OctopusNameToCloneList -ItemName $channel.Name -destinationList $cloneSpaceCommandLineOptions.ChannelsToClone        

        if ($null -ne $channel.LifeCycleId)
        {
            Write-OctopusSuccess "Adding lifecycle for channel name $($channel.Name) in $($project.Name)"
            $cloneSpaceCommandLineOptions.LifeCyclesToClone = Add-OctopusIdToCloneList -itemId $channel.LifeCycleId -itemType "Lifecycle" -destinationList $cloneSpaceCommandLineOptions.LifeCyclesToClone -sourceList $sourceData.LifeCycleList -exclusionList @()
        }
    }

    Add-OctopusTenantsToCloneList -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions -sourceData $sourceData -tenantExclusionList $tenantExclusionList -project $project
    $cloneSpaceCommandLineOptions.ProjectsToClone = Add-OctopusNameToCloneList -ItemName $project.Name -destinationList $cloneSpaceCommandLineOptions.ProjectsToClone
}

Add-OctopusLifeCycleEnvironmentsToCloneList -envrionmentListToExclude $envrionmentListToExclude -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions
Add-OctopusTargetsToCloneList -targetExclusionList $targetListToExclude -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions 
Add-OctopusWorkersToCloneList -workerExclusionList $workerListToExclude -sourceData $sourceData -cloneSpaceCommandLineOptions $cloneSpaceCommandLineOptions

Write-OctopusSuccess "The command line arguments are going to be: "
Write-OctopusSuccess "CloneSpace.ps1"
Write-OctopusSuccess "  -SourceOctopusUrl $SourceOctopusUrl"
Write-OctopusSuccess "  -SourceOctopusApiKey *************"
Write-OctopusSuccess "  -SourceSpaceName $SourceSpaceName"
Write-OctopusSuccess "  -DestinationOctopusUrl $DestinationOctopusUrl"
Write-OctopusSuccess "  -DestinationOctopusApiKey *************"
Write-OctopusSuccess "  -DestinationSpaceName $DestinationSpaceName"
Write-OctopusSuccess "  -ProjectsToClone $($cloneSpaceCommandLineOptions.ProjectsToClone)"
Write-OctopusSuccess "  -EnvironmentsToClone $($cloneSpaceCommandLineOptions.EnvironmentsToClone)"
Write-OctopusSuccess "  -WorkerPoolsToClone $($cloneSpaceCommandLineOptions.WorkerPoolsToClone)"
Write-OctopusSuccess "  -ProjectGroupsToClone $($cloneSpaceCommandLineOptions.ProjectGroupsToClone)"
Write-OctopusSuccess "  -TenantTagsToClone $($cloneSpaceCommandLineOptions.TenantTagsToClone)"
Write-OctopusSuccess "  -ExternalFeedsToClone $($cloneSpaceCommandLineOptions.ExternalFeedsToClone)"
Write-OctopusSuccess "  -StepTemplatesToClone $($cloneSpaceCommandLineOptions.StepTemplatesToClone)"
Write-OctopusSuccess "  -InfrastructureAccountsToClone $($cloneSpaceCommandLineOptions.InfrastructureAccountsToClone)"
Write-OctopusSuccess "  -LibraryVariableSetsToClone $($cloneSpaceCommandLineOptions.LibraryVariableSetsToClone)"
Write-OctopusSuccess "  -LifeCyclesToClone $($cloneSpaceCommandLineOptions.LifeCyclesToClone)"
Write-OctopusSuccess "  -ScriptModulesToClone $($cloneSpaceCommandLineOptions.ScriptModulesToClone)"
Write-OctopusSuccess "  -TenantsToClone $($cloneSpaceCommandLineOptions.TenantsToClone)"
Write-OctopusSuccess "  -MachinePoliciesToClone $($cloneSpaceCommandLineOptions.MachinePoliciesToClone)"
Write-OctopusSuccess "  -WorkersToClone $($cloneSpaceCommandLineOptions.WorkersToClone)"
Write-OctopusSuccess "  -TargetsToClone $($cloneSpaceCommandLineOptions.TargetsToClone)"
Write-OctopusSuccess "  -SpaceTeamsToClone $($cloneSpaceCommandLineOptions.SpaceTeamsToClone)"
Write-OctopusSuccess "  -PackagesToClone $($cloneSpaceCommandLineOptions.PackagesToClone)"
Write-OctopusSuccess "  -CertificatesToClone $($cloneSpaceCommandLineOptions.CertificatesToClone)"
Write-OctopusSuccess "  -ChannelsToClone $($cloneSpaceCommandLineOptions.ChannelsToClone)"
Write-OctopusSuccess "  -OverwriteExistingVariables $OverwriteExistingVariables"
Write-OctopusSuccess "  -OverwriteExistingCustomStepTemplates $OverwriteExistingCustomStepTemplates"
Write-OctopusSuccess "  -OverwriteExistingLifecyclesPhases $OverwriteExistingLifecyclesPhases"
Write-OctopusSuccess "  -CloneProjectChannelRules $CloneProjectChannelRules"
Write-OctopusSuccess "  -CloneProjectRunbooks $CloneProjectRunbooks"
Write-OctopusSuccess "  -CloneProjectVersioningReleaseCreationSettings $CloneProjectVersioningReleaseCreationSettings"
Write-OctopusSuccess "  -CloneProjectDeploymentProcess $CloneProjectDeploymentProcess"
Write-OctopusSuccess "  -CloneProjectLogos $CloneProjectLogos"
Write-OctopusSuccess "  -CloneTenantLogos $CloneTenantLogos"
Write-OctopusSuccess "  -CloneStepTemplateLogos $CloneStepTemplateLogos"
Write-OctopusSuccess "  -IgnoreVersionCheckResult $IgnoreVersionCheckResult"
Write-OctopusSuccess "  -SkipPausingWhenIgnoringVersionCheckResult $SkipPausingWhenIgnoringVersionCheckResult"
Write-OctopusSuccess "  -CloneTenantVariables $CloneTenantVariables"
Write-OctopusSuccess "  -ProcessEnvironmentScopingMatch $ProcessEnvironmentScopingMatch"
Write-OctopusSuccess "  -ProcessChannelScopingMatch $ProcessChannelScopingMatch"
Write-OctopusSuccess "  -ProcessTenantTagScopingMatch $ProcessTenantTagScopingMatch"
Write-OctopusSuccess "  -VariableChannelScopingMatch $VariableChannelScopingMatch"
Write-OctopusSuccess "  -VariableEnvironmentScopingMatch $VariableEnvironmentScopingMatch"
Write-OctopusSuccess "  -VariableProcessOwnerScopingMatch $VariableProcessOwnerScopingMatch"
Write-OctopusSuccess "  -VariableActionScopingMatch $VariableActionScopingMatch"
Write-OctopusSuccess "  -VariableMachineScopingMatch $VariableMachineScopingMatch"
Write-OctopusSuccess "  -VariableAccountScopingMatch $VariableAccountScopingMatch"
Write-OctopusSuccess "  -VariableCertificateScopingMatch $VariableCertificateScopingMatch"
Write-OctopusSuccess "  -VariableTenantTagScopingMatch $VariableTenantTagScopingMatch"
Write-OctopusSuccess "  -VariableWorkerPoolScopingMatch $VariableWorkerPoolScopingMatch"
Write-OctopusSuccess "  -InfrastructureEnvironmentScopingMatch $InfrastructureEnvironmentScopingMatch"
Write-OctopusSuccess "  -InfrastructureTenantScopingMatch $InfrastructureTenantScopingMatch"
Write-OctopusSuccess "  -InfrastructureTenantTagScopingMatch $InfrastructureTenantTagScopingMatch"
Write-OctopusSuccess "  -ProcessCloningOption $ProcessCloningOption"
Write-OctopusSuccess "  -WhatIf $WhatIf"

$cloneSpaceScript = "$PSScriptRoot\CloneSpace.ps1"
& $cloneSpaceScript `
    -SourceOctopusUrl $SourceOctopusUrl `
    -SourceOctopusApiKey "$SourceOctopusApiKey" `
    -SourceSpaceName "$SourceSpaceName" `
    -DestinationOctopusUrl "$DestinationOctopusUrl" `
    -DestinationOctopusApiKey "$DestinationOctopusApiKey" `
    -DestinationSpaceName "$DestinationSpaceName" `
    -ProjectsToClone "$($cloneSpaceCommandLineOptions.ProjectsToClone)" `
    -EnvironmentsToClone "$($cloneSpaceCommandLineOptions.EnvironmentsToClone)" `
    -WorkerPoolsToClone "$($cloneSpaceCommandLineOptions.WorkerPoolsToClone)" `
    -ProjectGroupsToClone "$($cloneSpaceCommandLineOptions.ProjectGroupsToClone)" `
    -TenantTagsToClone "$($cloneSpaceCommandLineOptions.TenantTagsToClone)" `
    -ExternalFeedsToClone "$($cloneSpaceCommandLineOptions.ExternalFeedsToClone)" `
    -StepTemplatesToClone "$($cloneSpaceCommandLineOptions.StepTemplatesToClone)" `
    -InfrastructureAccountsToClone "$($cloneSpaceCommandLineOptions.InfrastructureAccountsToClone)" `
    -LibraryVariableSetsToClone "$($cloneSpaceCommandLineOptions.LibraryVariableSetsToClone)" `
    -LifeCyclesToClone "$($cloneSpaceCommandLineOptions.LifeCyclesToClone)" `
    -ScriptModulesToClone "$($cloneSpaceCommandLineOptions.ScriptModulesToClone)" `
    -TenantsToClone "$($cloneSpaceCommandLineOptions.TenantsToClone)" `
    -MachinePoliciesToClone "$($cloneSpaceCommandLineOptions.MachinePoliciesToClone)" `
    -WorkersToClone "$($cloneSpaceCommandLineOptions.WorkersToClone)" `
    -TargetsToClone "$($cloneSpaceCommandLineOptions.TargetsToClone)" `
    -SpaceTeamsToClone "$($cloneSpaceCommandLineOptions.SpaceTeamsToClone)" `
    -PackagesToClone "$($cloneSpaceCommandLineOptions.PackagesToClone)" `
    -ChannelsToClone "$($cloneSpaceCommandLineOptions.ChannelsToClone)" `
    -OverwriteExistingVariables "$OverwriteExistingVariables" `
    -OverwriteExistingCustomStepTemplates "$OverwriteExistingCustomStepTemplates" `
    -OverwriteExistingLifecyclesPhases "$OverwriteExistingLifecyclesPhases" `
    -CloneProjectChannelRules "$CloneProjectChannelRules" `
    -CloneProjectRunbooks "$CloneProjectRunbooks" `
    -CloneProjectVersioningReleaseCreationSettings "$CloneProjectVersioningReleaseCreationSettings" `
    -CloneProjectDeploymentProcess "$CloneProjectDeploymentProcess" `
    -CloneProjectLogos "$CloneProjectLogos" `
    -CloneTenantLogos "$CloneTenantLogos" `
    -CloneStepTemplateLogos "$CloneStepTemplateLogos" `
    -IgnoreVersionCheckResult "$IgnoreVersionCheckResult" `
    -SkipPausingWhenIgnoringVersionCheckResult "$SkipPausingWhenIgnoringVersionCheckResult" `
    -CloneTenantVariables "$CloneTenantVariables" `
    -EnvironmentScopingMatch "$EnvironmentScopingMatch" `
    -ProcessEnvironmentScopingMatch "$ProcessEnvironmentScopingMatch" `
    -ProcessChannelScopingMatch "$ProcessChannelScopingMatch" `
    -ProcessTenantTagScopingMatch "$ProcessTenantTagScopingMatch" `
    -VariableChannelScopingMatch "$VariableChannelScopingMatch" `
    -VariableEnvironmentScopingMatch "$VariableEnvironmentScopingMatch" `
    -VariableProcessOwnerScopingMatch "$VariableProcessOwnerScopingMatch" `
    -VariableActionScopingMatch "$VariableActionScopingMatch" `
    -VariableMachineScopingMatch "$VariableMachineScopingMatch" `
    -VariableAccountScopingMatch "$VariableAccountScopingMatch" `
    -VariableCertificateScopingMatch "$VariableCertificateScopingMatch" `
    -VariableTenantTagScopingMatch "$VariableTenantTagScopingMatch" `
    -VariableWorkerPoolScopingMatch "$VariableWorkerPoolScopingMatch" `
    -InfrastructureEnvironmentScopingMatch "$InfrastructureEnvironmentScopingMatch" `
    -InfrastructureTenantScopingMatch "$InfrastructureTenantScopingMatch" `
    -InfrastructureTenantTagScopingMatch "$InfrastructureTenantTagScopingMatch" `
    -ProcessCloningOption "$ProcessCloningOption" `
    -WhatIf "$whatIf"

