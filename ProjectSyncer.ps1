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
    $CloneProjectDeploymentProcess,
    $ProcessEnvironmentScopingMatch,
    $ProcessChannelScopingMatch,
    $VariableChannelScopingMatch,
    $VariableEnvironmentScopingMatch,
    $VariableProcessOwnerScopingMatch,
    $VariableActionScopingMatch,
    $VariableMachineScopingMatch,
    $VariableAccountScopingMatch,
    $VariableCertificateScopingMatch,    
    $ProcessCloningOption,
    $WhatIf  
)

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Logging.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Util.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataAdapter.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataFactory.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusRepository.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusFakeFactory.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ActionCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "LibraryVariableSetCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "LogoCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ParentProjectTemplateSyncer.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProcessCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectChannelCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectChannelRuleCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectDeploymentProcessCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectGroupCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectRunbookCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "ProjectVariableCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "VariableSetValuesCloner.ps1"))

$ErrorActionPreference = "Stop"

$OverwriteExistingVariables = Test-OctopusTrueFalseParameter -parameterValue $OverwriteExistingVariables -parameterName "OverwriteExistingVariables" -defaultValue $false
$CloneProjectRunbooks = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectRunbooks -parameterName "CloneProjectRunbooks" -defaultValue $true
$CloneProjectChannelRules = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectChannelRules -parameterName "CloneProjectChannelRules" -defaultValue $false
$CloneProjectVersioningReleaseCreationSettings = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectVersioningReleaseCreationSettings -parameterName "CloneProjectVersioningReleaseCreationSettings" -defaultValue $false
$CloneProjectDeploymentProcess = Test-OctopusTrueFalseParameter -parameterValue $CloneProjectDeploymentProcess -parameterName "CloneProjectDeploymentProcess" -defaultValue $false

$ProcessCloningOption = Test-OctopusProcessCloningParameter -ParameterValue $ProcessCloningOption
$ProcessEnvironmentScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "ProcessEnvironmentScopingMatch" -ParameterValue $ProcessEnvironmentScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$ProcessChannelScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "ProcessChannelScopingMatch" -ParameterValue $ProcessChannelScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false

$VariableChannelScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableChannelScopingMatch" -ParameterValue $VariableChannelScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableEnvironmentScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableEnvironmentScopingMatch" -ParameterValue $VariableEnvironmentScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableProcessOwnerScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableProcessOwnerScopingMatch" -ParameterValue $VariableProcessOwnerScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableActionScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableActionScopingMatch" -ParameterValue $VariableActionScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableMachineScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableMachineScopingMatch" -ParameterValue $VariableMachineScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableAccountScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableAccountScopingMatch" -ParameterValue $VariableAccountScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true
$VariableCertificateScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableCertificateScopingMatch" -ParameterValue $VariableCertificateScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true

$WhatIf = Test-OctopusTrueFalseParameter -parameterValue $WhatIf -parameterName "WhatIf" -defaultValue $false

$CloneScriptOptions = @{
    OverwriteExistingVariables = $OverwriteExistingVariables;    
    CloneProjectRunbooks = $CloneProjectRunbooks;
    ChildProjectsToSync = $ChildProjectsToSync;
    ParentProjectName = $ParentProjectName;
    RunbooksToClone = $RunbooksToClone;
    CloneProjectChannelRules = $CloneProjectChannelRules;
    CloneProjectVersioningReleaseCreationSettings = $CloneProjectVersioningReleaseCreationSettings;
    CloneProjectDeploymentProcess = $CloneProjectDeploymentProcess;
    ProcessEnvironmentScopingMatch = $ProcessEnvironmentScopingMatch;
    ProcessChannelScopingMatch = $ProcessChannelScopingMatch; 
    VariableChannelScopingMatch = $VariableChannelScopingMatch;
    VariableEnvironmentScopingMatch = $VariableEnvironmentScopingMatch;
    VariableProcessOwnerScopingMatch = $VariableProcessOwnerScopingMatch;
    VariableActionScopingMatch = $VariableActionScopingMatch;
    VariableMachineScopingMatch = $VariableMachineScopingMatch;
    VariableAccountScopingMatch = $VariableAccountScopingMatch;
    VariableCertificateScopingMatch = $VariableCertificateScopingMatch;    
    ProcessCloningOption = $ProcessCloningOption;
}

Write-OctopusVerbose "The clone parameters sent in are:"
Write-OctopusVerbose $($CloneScriptOptions | ConvertTo-Json -Depth 10)

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName -whatif $whatIf
$destinationData = $sourceData

Sync-OctopusMasterOctopusProjectWithChildProjects -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions

$logPath = Get-OctopusLogPath
$cleanupLogPath = Get-OctopusCleanUpLogPath

Write-OctopusSuccess "The script to sync $ChildProjectsToSync from $ParentProjectName on $SourceUrl has completed.  Please see $logPath for more details."
Write-OctopusWarning "You might have post clean-up tasks to finish.  Any sensitive variables or encrypted values were created with dummy values which you must replace.  Please see $cleanUpLogPath for a list of items to fix."