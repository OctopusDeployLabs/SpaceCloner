function Copy-OctopusProjectVariables
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $destinationProject,        
        $sourceProject,
        $sourceData,
        $destinationData,
        $cloneScriptOptions,
        $createdNewProject
    )    

    if ($createdNewProject -eq $true -or $cloneScriptOptions.OverwriteExistingVariables -eq $true)
    {
        $sourceVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $sourceProject -OctopusData $sourceData 
        $destinationVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $destinationProject -OctopusData $destinationData 

        $SourceProjectData = @{
            ChannelList = $sourceChannelList;
            RunbookList = @()
            Project = $sourceProject    
        }

        if ($sourceData.HasRunBooks -eq $true)
        {
            $SourceProjectData.RunbookList = Get-OctopusProjectRunbookList -project $sourceProject -OctopusData $sourceData
        }

        $DestinationProjectData = @{
            ChannelList = $destinationChannelList;
            RunbookList = @();
            Project = $destinationProject
        }

        if ($destinationData.HasRunBooks -eq $true)
        {
            $DestinationProjectData.RunbookList = Get-OctopusProjectRunbookList -project $destinationProject -OctopusData $DestinationData
        }

        Write-OctopusPostCloneCleanUp "*****************Starting variable clone for $($destinationProject.Name)*******************"

        Copy-OctopusVariableSetValues -SourceVariableSetVariables $sourceVariableSetVariables -DestinationVariableSetVariables $destinationVariableSetVariables -SourceData $SourceData -DestinationData $DestinationData -SourceProjectData $SourceProjectData -DestinationProjectData $DestinationProjectData -CloneScriptOptions $cloneScriptOptions

        Write-OctopusPostCloneCleanUp "*****************Ended variable clone for $($destinationProject.Name)**********************"
    }
}