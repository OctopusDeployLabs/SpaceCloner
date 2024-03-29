function Copy-OctopusProjectDeploymentProcess
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $sourceProject,
        $destinationProject,        
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    Write-OctopusSuccess "Syncing deployment process for $($destinationProject.Name)"
    $sourceDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $sourceProject -OctopusData $sourceData
    $destinationDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $destinationProject -OctopusData $DestinationData
    
    Write-OctopusChangeLog "    - Deployment Process"
    Write-OctopusPostCloneCleanUp "*****************Starting sync of deployment process for $($destinationProject.Name)***************"
    $destinationDeploymentProcess.Steps = @(Copy-OctopusDeploymentProcess -sourceChannelList $sourceChannelList -destinationChannelList $destinationChannelList -sourceData $sourceData -destinationData $destinationData -sourceDeploymentProcessSteps $sourceDeploymentProcess.Steps -destinationDeploymentProcessSteps $destinationDeploymentProcess.Steps -cloneScriptOptions $cloneScriptOptions)
    Write-OctopusPostCloneCleanUp "*****************Ending sync of deployment process for $($destinationProject.Name)*****************"

    $destinationDeploymentProcess = Save-OctopusProjectDeploymentProcess -DeploymentProcess $destinationDeploymentProcess -DestinationData $destinationData    

    $projectId = $destinationProject.Id
    $destinationData.ProjectProcesses.$projectId = $destinationDeploymentProcess
}