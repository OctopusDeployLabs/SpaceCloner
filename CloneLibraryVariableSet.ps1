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
    $SkipPausingWhenIgnoringVersionCheckResult        
)

. ($PSScriptRoot + ".\src\Core\Logging.ps1")
. ($PSScriptRoot + ".\src\Core\Util.ps1")

. ($PSScriptRoot + ".\src\DataAccess\OctopusDataAdapter.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusDataFactory.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusRepository.ps1")

. ($PSScriptRoot + ".\src\Cloners\LibraryVariableSetCloner.ps1")
. ($PSScriptRoot + ".\src\Cloners\VariableSetValuesCloner.ps1")

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

$CloneScriptOptions = @{
    OverwriteExistingVariables = $OverwriteExistingVariables;     
    LibraryVariableSetsToClone = $SourceVariableSetName;
    DestinationVariableSetName = $DestinationVariableSetName;   
}

Write-OctopusVerbose "The clone parameters sent in are:"
Write-OctopusVerbose $($CloneScriptOptions | ConvertTo-Json -Depth 10)

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName
$destinationData = Get-OctopusData -octopusUrl $DestinationOctopusUrl -octopusApiKey $DestinationOctopusApiKey -spaceName $DestinationSpaceName

Compare-OctopusVersions -SourceData $sourceData -DestinationData $destinationData -IgnoreVersionCheckResult $IgnoreVersionCheckResult -SkipPausingWhenIgnoringVersionCheckResult $SkipPausingWhenIgnoringVersionCheckResult

Copy-OctopusLibraryVariableSets -SourceData $sourceData -DestinationData $destinationData  -cloneScriptOptions $CloneScriptOptions

$logPath = Get-OctopusLogPath
$cleanupLogPath = Get-OctopusCleanUpLogPath

Write-OctopusSuccess "The script to clone the variable set $SourceVariableSetName on the space $SourceSpaceName on $SourceOctopusUrl to the variable set $DestinationVariableSetName on the space $DestinationSpaceName on $DestinationOctopusUrl.  Please see $logPath for more details."
Write-OctopusWarning "You might have post clean-up tasks to finish.  Any sensitive variables or encrypted values were created with dummy values which you must replace.  Please see $cleanUpLogPath for a list of items to fix."