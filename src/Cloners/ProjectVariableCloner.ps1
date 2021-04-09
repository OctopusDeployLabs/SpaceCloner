function Copy-OctopusProjectVariables
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $destinationProject,        
        $sourceProject,
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )    

    $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $sourceProject -OctopusData $sourceData 
    $destinationVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $destinationProject -OctopusData $destinationData 

    Write-OctopusPostCloneCleanUp "*****************Starting variable clone for $($destinationProject.Name)*******************"

    $projectVariables = Copy-OctopusVariableSetValues -SourceVariableSetVariables $sourceVariableSetVariables -DestinationVariableSetVariables $destinationVariableSetVariables -SourceData $SourceData -DestinationData $DestinationData -CloneScriptOptions $cloneScriptOptions

    Write-OctopusPostCloneCleanUp "*****************Ended variable clone for $($destinationProject.Name)**********************"

    $projectId = $destinationProject.Id
    $destinationData.ProjectVariableSets.$projectId = $projectVariables
}