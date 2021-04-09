param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,  
    $SourceVariableSetName,
    $DestinationVariableSetName,
    $OverwriteExistingVariables,    
    $IgnoreVersionCheckResult,
    $SkipPausingWhenIgnoringVersionCheckResult,
    $WhatIf     
)

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Logging.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Util.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataAdapter.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataFactory.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusRepository.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusFakeFactory.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "LibraryVariableSetCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "VariableSetValuesCloner.ps1"))

$ErrorActionPreference = "Stop"

if ($null -eq $OverwriteExistingVariables)
{
    $OverwriteExistingVariables = $false
}

if ($null -eq $IgnoreVersionCheckResult)
{
    $IgnoreVersionCheckResult = $false
}

if ($null -eq $SkipPausingWhenIgnoringVersionCheckResult)
{
    $SkipPausingWhenIgnoringVersionCheckResult = $false
}

if ($null -eq $WhatIf)
{
    $WhatIf = $false
}


$CloneScriptOptions = @{
    OverwriteExistingVariables = $OverwriteExistingVariables;     
    LibraryVariableSetsToClone = $SourceVariableSetName;
    DestinationVariableSetName = $DestinationVariableSetName;   
}

Write-OctopusVerbose "The clone parameters sent in are:"
Write-OctopusVerbose $($CloneScriptOptions | ConvertTo-Json -Depth 10)

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName -whatIf $whatIf
$destinationData = Get-OctopusData -octopusUrl $DestinationOctopusUrl -octopusApiKey $DestinationOctopusApiKey -spaceName $DestinationSpaceName -whatIf $whatIf

Compare-OctopusVersions -SourceData $sourceData -DestinationData $destinationData -IgnoreVersionCheckResult $IgnoreVersionCheckResult -SkipPausingWhenIgnoringVersionCheckResult $SkipPausingWhenIgnoringVersionCheckResult

Copy-OctopusLibraryVariableSets -SourceData $sourceData -DestinationData $destinationData  -cloneScriptOptions $CloneScriptOptions

$logPath = Get-OctopusLogPath
$cleanupLogPath = Get-OctopusCleanUpLogPath

Write-OctopusSuccess "The script to clone the variable set $SourceVariableSetName on the space $SourceSpaceName on $SourceOctopusUrl to the variable set $DestinationVariableSetName on the space $DestinationSpaceName on $DestinationOctopusUrl.  Please see $logPath for more details."
Write-OctopusWarning "You might have post clean-up tasks to finish.  Any sensitive variables or encrypted values were created with dummy values which you must replace.  Please see $cleanUpLogPath for a list of items to fix."
