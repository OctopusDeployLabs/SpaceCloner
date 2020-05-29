function Copy-OctopusProjects
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )  
    
    if ([string]::IsNullOrWhiteSpace($CloneScriptOptions.ParentProjectName) -eq $false -or [string]::IsNullOrWhiteSpace($CloneScriptOptions.ChildProjectsToSync) -eq $false)
    {
        Write-OctopusWarning "You have elected to sync child projects with a parent project, skipping the normal project cloner"
        return
    }

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ProjectsToClone

    if ($filteredList.length -eq 0)
    {
        return
    }
    
    Write-OctopusPostCloneCleanUp "*****************Starting clone for all projects***************"
    
    foreach($project in $filteredList)
    {
        $createdNewProject = Copy-OctopusProjectSettings -sourceData $SourceData -destinationData $DestinationData -sourceProject $project               
        
        Write-OctopusSuccess "Reloading destination projects"        
        
        $destinationData.ProjectList = Get-OctopusProjectList -OctopusData $DestinationData

        $destinationProject = Get-OctopusItemByName -ItemList $DestinationData.ProjectList -ItemName $project.Name

        $sourceChannels = Get-OctopusProjectChannelList -project $project -octopusData $sourceData
        $destinationChannels = Get-OctopusProjectChannelList -project $destinationProject -OctopusData $DestinationData
        Copy-OctopusProjectChannels -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData
        $destinationChannels = Get-OctopusProjectChannelList -project $destinationProject -OctopusData $DestinationData

        Copy-OctopusProjectDeploymentProcess -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -sourceProject $project -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData 

        if ($CloneScriptOptions.CloneProjectRunbooks -eq $true)
        {
            Copy-OctopusProjectRunbooks -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $project -destinationData $DestinationData -sourceData $SourceData            
        }

        Copy-OctopusProjectVariables -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $project -destinationData $DestinationData -sourceData $SourceData -cloneScriptOptions $CloneScriptOptions -createdNewProject $createdNewProject        
        Copy-OctopusProjectChannelRules -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData -cloneScriptOptions $CloneScriptOptions
        Copy-OctopusProjectReleaseVersioningSettings -sourceData $sourceData -sourceProject $project -sourceChannels $sourceChannels -destinationData $destinationData -destinationProject $destinationProject -destinationChannels $destinationChannels -CloneScriptOptions $CloneScriptOptions
        Copy-OctopusItemLogo -sourceItem $project -destinationItem $destinationProject -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions
    }

    Write-OctopusPostCloneCleanUp "*****************Ending Clone for all projects***************"
}

function Copy-OctopusProjectSettings
{
    param(
        $sourceData,
        $destinationData,
        $sourceProject
    )

    $matchingProject = Get-OctopusItemByName -ItemList $DestinationData.ProjectList -ItemName $sourceProject.Name               

    if ($null -eq $matchingProject)
    {            
        $copyOfProject = Copy-OctopusObject -ItemToCopy $sourceProject -ClearIdValue $true -SpaceId $destinationData.SpaceId
        
        $copyOfProject.DeploymentProcessId = $null
        $copyOfProject.VariableSetId = $null
        $copyOfProject.ClonedFromProjectId = $null        

        $VariableSetIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.VariableSetList -DestinationList $DestinationData.VariableSetList -IdList $copyOfProject.IncludedLibraryVariableSetIds)
        $copyOfProject.IncludedLibraryVariableSetIds = @($VariableSetIds)
        $copyOfProject.ProjectGroupId = Convert-SourceIdToDestinationId -SourceList $SourceData.ProjectGroupList -DestinationList $DestinationData.ProjectGroupList -IdValue $copyOfProject.ProjectGroupId
        $copyOfProject.LifeCycleId = Convert-SourceIdToDestinationId -SourceList $SourceData.LifeCycleList -DestinationList $DestinationData.LifeCycleList -IdValue $copyOfProject.LifeCycleId        

        Write-OctopusPostCloneCleanUp "New project $($sourceProject.Name), resetting the versioning template to the default, removing the automatic release creation"
        $copyOfProject.VersioningStrategy.Template = "#{Octopus.Version.LastMajor}.#{Octopus.Version.LastMinor}.#{Octopus.Version.NextPatch}"
        $copyOfProject.VersioningStrategy.DonorPackage = $null
        $copyOfProject.VersioningStrategy.DonorPackageStepId = $null
        $copyOfProject.ReleaseCreationStrategy.ChannelId = $null
        $copyOfProject.ReleaseCreationStrategy.ReleaseCreationPackage = $null
        $copyOfProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId = $null
        $copyOfProject.AutoCreateRelease = $false
        
        Save-OctopusProject -Project $copyOfProject -DestinationData $destinationData        

        return $true
    }
    else
    {            
        $matchingProject.Description = $sourceProject.Description                   

        Save-OctopusProject -Project $matchingProject -DestinationData $destinationData        

        return $false
    }    
}

function Copy-OctopusProjectReleaseVersioningSettings
{
    param(
        $sourceData,
        $sourceProject,
        $sourceChannels,
        $destinationData,
        $destinationProject,
        $destinationChannels,
        $CloneScriptOptions
    )

    if ($CloneScriptOptions.CloneProjectVersioningReleaseCreationSettings -eq $false)
    {
        Write-OctopusWarning "The option CloneProjectVersioningReleaseCreationSettings was set to false, skipping the release versioning settings clone."
        return
    }

    Write-OctopusSuccess "Cloning release versioning settings for project $($project.Name)"
    $sourceDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $sourceProject -OctopusData $sourceData
    $destinationDeploymentProcess = Get-OctopusProjectDeploymentProcess -project $destinationProject -OctopusData $DestinationData

    if ($null -eq $sourceProject.VersioningStrategy.DonorPackage.Template)
    {
        Write-OctopusVerbose "The project $($project.Name) has the release versioning based on a package."
        $destinationProject.VersioningStrategy = Copy-OctopusObject -ItemToCopy $sourceProject.VersioningStrategy -ClearIdValue $false -SpaceId $null
        $destinationProject.VersioningStrategy.DonorPackageStepId = Convert-OctopusProcessDeploymentStepId -sourceProcess $sourceDeploymentProcess -destinationProcess $destinationDeploymentProcess -sourceId $sourceProject.VersioningStrategy.DonorPackageStepId
    }
    else
    {
        $destinationProject.VersioningStrategy.Template = "#{Octopus.Version.LastMajor}.#{Octopus.Version.LastMinor}.#{Octopus.Version.NextPatch}"
        $destinationProject.VersioningStrategy.DonorPackage = $null
        $destinationProject.VersioningStrategy.DonorPackageStepId = $null
    }

    if ($null -ne $sourceProject.ReleaseCreationStrategy.ChannelId)
    {
        Write-OctopusVerbose "The project $($project.Name) has automatic release creation set."
        $destinationProject.ReleaseCreationStrategy = Copy-OctopusObject -ItemToCopy $sourceProject.ReleaseCreationStrategy -ClearIdValue $false -SpaceId $null
        $destinationProject.ReleaseCreationStrategy.ChannelId = Convert-SourceIdToDestinationId -SourceList $sourceChannels -DestinationList $destinationChannels -IdValue $sourceProject.ReleaseCreationStrategy.ChannelId
        $destinationProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId = Convert-OctopusProcessDeploymentStepId -sourceProcess $sourceDeploymentProcess -destinationProcess $destinationDeploymentProcess -sourceId $sourceProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId
        $destinationProject.AutoCreateRelease = $true
    }
    else 
    {
        $destinationProject.ReleaseCreationStrategy.ChannelId = $null
        $destinationProject.ReleaseCreationStrategy.ReleaseCreationPackage = $null
        $destinationProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId = $null
        $destinationProject.AutoCreateRelease = $false    
    }

    
    Save-OctopusProject -Project $destinationProject -DestinationData $destinationData

    Write-OctopusSuccess "Finished cloning release versioning settings for project $($project.Name)"
}
