function Copy-OctopusProjectDeploymentProcess
{
    param(
        $sourceChannelList,
        $destinationChannelList,
        $sourceProject,
        $destinationProject,        
        $sourceData,
        $destinationData
    )

    Write-OctopusSuccess "Syncing deployment process for $($destinationProject.Name)"
    $sourceDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $sourceProject -OctopusData $sourceData
    $destinationDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $destinationProject -OctopusData $DestinationData
    
    Write-OctopusPostCloneCleanUp "*****************Starting sync of deployment process for $($destinationProject.Name)***************"
    $destinationDeploymentProcess.Steps = @(Copy-OctopusDeploymentProcess -sourceChannelList $sourceChannelList -destinationChannelList $destinationChannelList -sourceData $sourceData -destinationData $destinationData -sourceDeploymentProcessSteps $sourceDeploymentProcess.Steps -destinationDeploymentProcessSteps $destinationDeploymentProcess.Steps)
    Write-OctopusPostCloneCleanUp "*****************Ending sync of deployment process for $($destinationProject.Name)*****************"

    Save-OctopusProjectDeploymentProcess -DeploymentProcess $destinationDeploymentProcess -DestinationData $destinationData    
}