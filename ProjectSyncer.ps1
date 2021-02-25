param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,  
    $ParentProjectName,
    $ChildProjectsToSync,
    $RunbooksToClone,
    $OverwriteExistingVariables,        
    $CloneProjectRunbooks,
    $CloneProjectChannelRules,
    $CloneProjectVersioningReleaseCreationSettings,
    $CloneProjectDeploymentProcess    
)

. ([IO.Path]::Combine('src', 'Core', 'Logging.ps1'))
. ([IO.Path]::Combine('src', 'Core', 'Util.ps1'))

. ([IO.Path]::Combine('src', 'DataAccess', 'OctopusDataAdapter.ps1'))
. ([IO.Path]::Combine('src', 'DataAccess', 'OctopusDataFactory.ps1'))
. ([IO.Path]::Combine('src', 'DataAccess', 'OctopusRepository.ps1'))

. ([IO.Path]::Combine('src', 'Cloners', 'AccountCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'LibraryVariableSetCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'LogoCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ParentProjectTemplateSyncer.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProcessCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectChannelCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectChannelRuleCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectDeploymentProcessCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectGroupCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectRunbookCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'ProjectVariableCloner.ps1'))
. ([IO.Path]::Combine('src', 'Cloners', 'VariableSetValuesCloner.ps1'))

$ErrorActionPreference = "Stop"

if ($null -eq $OverwriteExistingVariables)
{
    $OverwriteExistingVariables = $false
}

if ($null -eq $CloneProjectRunbooks)
{
    $CloneProjectRunbooks = $true
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

$CloneScriptOptions = @{
    OverwriteExistingVariables = $OverwriteExistingVariables;    
    CloneProjectRunbooks = $CloneProjectRunbooks;
    ChildProjectsToSync = $ChildProjectsToSync;
    ParentProjectName = $ParentProjectName;
    RunbooksToClone = $RunbooksToClone;
    CloneProjectChannelRules = $CloneProjectChannelRules;
    CloneProjectVersioningReleaseCreationSettings = $CloneProjectVersioningReleaseCreationSettings;
    CloneProjectDeploymentProcess = $CloneProjectDeploymentProcess;
}

Write-OctopusVerbose "The clone parameters sent in are:"
Write-OctopusVerbose $($CloneScriptOptions | ConvertTo-Json -Depth 10)

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName
$destinationData = $sourceData

Sync-OctopusMasterOctopusProjectWithChildProjects -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions

$logPath = Get-OctopusLogPath
$cleanupLogPath = Get-OctopusCleanUpLogPath

Write-OctopusSuccess "The script to sync $ChildProjectsToSync from $ParentProjectName on $SourceUrl has completed.  Please see $logPath for more details."
Write-OctopusWarning "You might have post clean-up tasks to finish.  Any sensitive variables or encrypted values were created with dummy values which you must replace.  Please see $cleanUpLogPath for a list of items to fix."