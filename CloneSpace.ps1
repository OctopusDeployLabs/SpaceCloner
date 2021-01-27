param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,    
    $EnvironmentsToClone,
    $WorkerPoolsToClone,
    $ProjectGroupsToClone, 
    $TenantTagsToClone,
    $ExternalFeedsToClone,
    $StepTemplatesToClone,
    $InfrastructureAccountsToClone,
    $LibraryVariableSetsToClone,
    $LifeCyclesToClone,
    $ScriptModulesToClone,    
    $MachinePoliciesToClone,
    $WorkersToClone,
    $TargetsToClone,
    $ProjectsToClone,
    $ParentProjectName,
    $ChildProjectsToSync,
    $TenantsToClone,
    $SpaceTeamsToClone, 
    $PackagesToClone,   
    $RunbooksToClone,
    $OverwriteExistingVariables,    
    $OverwriteExistingCustomStepTemplates,
    $OverwriteExistingLifecyclesPhases,
    $CloneProjectRunbooks,
    $CloneTeamUserRoleScoping,
    $CloneProjectChannelRules,
    $CloneProjectVersioningReleaseCreationSettings,
    $CloneProjectDeploymentProcess,
    $IgnoreVersionCheckResult,
    $SkipPausingWhenIgnoringVersionCheckResult
)

. ($PSScriptRoot + ".\src\Core\Logging.ps1")
. ($PSScriptRoot + ".\src\Core\Util.ps1")

. ($PSScriptRoot + ".\src\DataAccess\OctopusDataAdapter.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusDataFactory.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusRepository.ps1")

. ($PSScriptRoot + ".\src\Cloners\AccountCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ActionCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\EnvironmentCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ExternalFeedCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\LibraryVariableSetCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\LifecycleCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\LogoCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\MachinePolicyCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\PackageCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ParentProjectTemplateSyncer.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProcessCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectChannelCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectChannelRuleCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectDeploymentProcessCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectGroupCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectRunbookCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ProjectVariableCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\ScriptModuleCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\StepTemplateCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\TargetCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\TeamCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\TeamUserRoleCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\TenantCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\TenantTagSetCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\VariableSetValuesCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\WorkerCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\WorkerPoolCloner.ps1")

$ErrorActionPreference = "Stop"

if ($null -eq $OverwriteExistingVariables)
{
    $OverwriteExistingVariables = $false
}

if ($null -eq $OverwriteExistingCustomStepTemplates)
{
    $OverwriteExistingCustomStepTemplates = $false
}

if ($null -eq $OverwriteExistingLifecyclesPhases)
{
    $OverwriteExistingLifecyclesPhases = $false
}

if ($null -eq $CloneProjectRunbooks)
{
    $CloneProjectRunbooks = $true
}

if ($null -eq $CloneTeamUserRoleScoping)
{
    $CloneTeamUserRoleScoping = $false
}

if ($null -eq $CloneProjectChannelRules)
{
    $CloneProjectChannelRules = $false
}

if ($null -eq $CloneProjectVersioningReleaseCreationSettings)
{
    $CloneProjectVersioningReleaseCreationSettings = $false
}

if ($null -eq $CloneProjectDeploymentProcess)
{
    $CloneProjectDeploymentProcess = $true
}

if ($null -eq $RunbooksToClone)
{
    $RunbooksToClone = "all"
}

if ($null -eq $IgnoreVersionCheckResult)
{
    $IgnoreVersionCheckResult = $false
}

if ($null -eq $SkipPausingWhenIgnoringVersionCheckResult)
{
    $SkipPausingWhenIgnoringVersionCheckResult = $false
}

$CloneScriptOptions = @{
    EnvironmentsToClone = $EnvironmentsToClone; 
    WorkerPoolsToClone = $WorkerPoolsToClone; 
    ProjectGroupsToClone = $ProjectGroupsToClone;
    TenantTagsToClone = $TenantTagsToClone;
    ExternalFeedsToClone = $ExternalFeedsToClone;
    StepTemplatesToClone = $StepTemplatesToClone;
    InfrastructureAccountsToClone = $InfrastructureAccountsToClone;
    LibraryVariableSetsToClone = $LibraryVariableSetsToClone;
    LifeCyclesToClone = $LifeCyclesToClone;
    ProjectsToClone = $ProjectsToClone;
    OverwriteExistingVariables = $OverwriteExistingVariables;    
    OverwriteExistingCustomStepTemplates = $OverwriteExistingCustomStepTemplates;
    OverwriteExistingLifecyclesPhases = $OverwriteExistingLifecyclesPhases;
    TenantsToClone = $TenantsToClone;
    ScriptModulesToClone = $ScriptModulesToClone;
    TargetsToClone = $TargetsToClone;
    MachinePoliciesToClone = $MachinePoliciesToClone;
    WorkersToClone = $WorkersToClone;
    CloneProjectRunbooks = $CloneProjectRunbooks;
    ChildProjectsToSync = $ChildProjectsToSync;
    ParentProjectName = $ParentProjectName;
    SpaceTeamsToClone = $SpaceTeamsToClone;
    PackagesToClone = $PackagesToClone;
    RunbooksToClone = $RunbooksToClone;
    CloneTeamUserRoleScoping = $CloneTeamUserRoleScoping;
    CloneProjectChannelRules = $CloneProjectChannelRules;
    CloneProjectVersioningReleaseCreationSettings = $CloneProjectVersioningReleaseCreationSettings;
    CloneProjectDeploymentProcess = $CloneProjectDeploymentProcess;
}

Write-OctopusVerbose "The clone parameters sent in are:"
Write-OctopusVerbose $($CloneScriptOptions | ConvertTo-Json -Depth 10)

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName
$destinationData = Get-OctopusData -octopusUrl $DestinationOctopusUrl -octopusApiKey $DestinationOctopusApiKey -spaceName $DestinationSpaceName

Compare-OctopusVersions -SourceData $sourceData -DestinationData $destinationData -IgnoreVersionCheckResult $IgnoreVersionCheckResult -SkipPausingWhenIgnoringVersionCheckResult $SkipPausingWhenIgnoringVersionCheckResult

if ($sourceData.OctopusUrl -eq $destinationData.OctopusUrl -and $SourceSpaceName -eq $DestinationSpaceName)
{
    $canProceed = $true

    $CloneScriptOptions.PSObject.Properties | ForEach-Object {
        $optionName = $_.Name

        if ($optionName -like "*ToClone" -and [string]::IsNullOrWhiteSpace($_.Value) -eq $false)
        {
            Write-OctopusCritical "You are cloning to the same space on the same instance, but have a value for $optionName.  This is not allowed.  Please remove that parameter."
            $canProceed = $false
        }
    }

    if ($canProceed -eq $false)
    {
        Write-OctopusCritical "Invalid parameters detected.  Please check log and correct them."
        Exit 1
    }
}

Copy-OctopusBuiltInPackages -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Copy-OctopusEnvironments -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusWorkerPools -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusProjectGroups -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusExternalFeeds -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusTenantTags -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusSpaceTeams -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusStepTemplates -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusInfrastructureAccounts -SourceData $sourceData -DestinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Copy-OctopusScriptModules -SourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusMachinePolicies -SourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusLifecycles -sourceData $sourceData -destinationData $destinationData -cloneScriptOptions $CloneScriptOptions
Copy-OctopusLibraryVariableSets -SourceData $sourceData -DestinationData $destinationData  -cloneScriptOptions $CloneScriptOptions
Copy-OctopusProjects -SourceData $sourceData -DestinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Copy-OctopusTenants -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Copy-OctopusWorkers -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Copy-OctopusTargets -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Sync-OctopusMasterOctopusProjectWithChildProjects -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions
Copy-OctopusSpaceTeamUserRoles -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions

$logPath = Get-OctopusLogPath
$cleanupLogPath = Get-OctopusCleanUpLogPath

Write-OctopusSuccess "The script to clone $SourceSpaceName from $SourceOctopusUrl to $DestinationSpaceName in $DestinationOctopusUrl has completed.  Please see $logPath for more details."
Write-OctopusWarning "You have post clean-up tasks to finish.  Any sensitive variables or encrypted values were created with dummy values which you must replace.  Please see $cleanUpLogPath for a list of items to fix."