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

    Write-OctopusChangeLog "Projects"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No Projects found to clone matching the filters"
        return
    }
    
    Write-OctopusPostCloneCleanUpHeader "*****************Starting clone for all projects***************"
    
    foreach($project in $filteredList)
    {
        if ((Test-OctopusObjectHasProperty -objectToTest $project -propertyName "IsVersionControlled"))
        {
            if ($project.IsVersionControlled -eq $true)
            {
                Write-OctopusError "Unable to clone $($project.Name) because has been configured for version control.  At this time, the space cloner does not support version control."
                continue
            }
        }
        
        $destinationProject = Copy-OctopusProjectSettings -sourceData $SourceData -destinationData $DestinationData -sourceProject $project                       

        $sourceChannels = Get-OctopusProjectChannelList -project $project -octopusData $sourceData
        $destinationChannels = Get-OctopusProjectChannelList -project $destinationProject -OctopusData $DestinationData
        $destinationChannels = Copy-OctopusProjectChannels -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData
        
        if ($CloneScriptOptions.CloneProjectDeploymentProcess -eq $true)
        {
            Copy-OctopusProjectDeploymentProcess -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -sourceProject $project -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $cloneScriptOptions
        }

        if ($CloneScriptOptions.CloneProjectRunbooks -eq $true)
        {
            Copy-OctopusProjectRunbooks -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $project -destinationData $DestinationData -sourceData $SourceData -cloneScriptOptions $CloneScriptOptions      
        }

        Copy-OctopusProjectVariables -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceProject $project -destinationData $DestinationData -sourceData $SourceData -cloneScriptOptions $CloneScriptOptions        
        Copy-OctopusProjectChannelRules -sourceChannelList $sourceChannels -destinationChannelList $destinationChannels -destinationProject $destinationProject -sourceData $SourceData -destinationData $DestinationData -cloneScriptOptions $CloneScriptOptions
        $destinationProject = Copy-OctopusProjectReleaseVersioningSettings -sourceData $sourceData -sourceProject $project -sourceChannels $sourceChannels -destinationData $destinationData -destinationProject $destinationProject -destinationChannels $destinationChannels -CloneScriptOptions $CloneScriptOptions
        Copy-OctopusItemLogo -sourceItem $project -destinationItem $destinationProject -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions
    }

    Write-OctopusPostCloneCleanUpHeader "*****************Ending Clone for all projects***************"
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
        Write-OctopusChangeLog " - Add $($sourceProject.Name)"
        
        $copyOfProject.DeploymentProcessId = $null
        $copyOfProject.VariableSetId = $null
        $copyOfProject.ClonedFromProjectId = $null        

        $newVariableSetIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.VariableSetList -DestinationList $DestinationData.VariableSetList -IdList $copyOfProject.IncludedLibraryVariableSetIds -MatchingOption "ErrorUnlessExactMatch" -IdListName "$($sourceProject.Name) Library Variable Sets"
        $VariableSetIds = @($newVariableSetIds.NewIdList)

        $newScriptModuleIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.ScriptModuleList -DestinationList $DestinationData.ScriptModuleList -IdList $copyOfProject.IncludedLibraryVariableSetIds -MatchingOption "ErrorUnlessExactMatch" -IdListName "$($sourceProject.Name) Script Modules"
        $scriptModuleIds = @($newScriptModuleIds.NewIdList)

        $copyOfProject.IncludedLibraryVariableSetIds = @($VariableSetIds)

        if ($scriptModuleIds.Count -gt 0)
        {
            foreach ($scriptModuleId in $scriptModuleIds)
            {
                $copyOfProject.IncludedLibraryVariableSetIds += $scriptModuleId
            }
        }        

        $copyOfProject.ProjectGroupId = Convert-SourceIdToDestinationId -SourceList $SourceData.ProjectGroupList -DestinationList $DestinationData.ProjectGroupList -IdValue $copyOfProject.ProjectGroupId -ItemName "$($copyOfProject.Name) Project Group" -MatchingOption "ErrorUnlessExactMatch"
        $copyOfProject.LifeCycleId = Convert-SourceIdToDestinationId -SourceList $SourceData.LifeCycleList -DestinationList $DestinationData.LifeCycleList -IdValue $copyOfProject.LifeCycleId -ItemName "$($copyOfProject.Name) Default Lifecycle" -MatchingOption "ErrorUnlessExactMatch"

        Write-OctopusPostCloneCleanUp "New project $($sourceProject.Name), resetting the versioning template to the default, removing the automatic release creation"
        $copyOfProject.VersioningStrategy.Template = "#{Octopus.Version.LastMajor}.#{Octopus.Version.LastMinor}.#{Octopus.Version.NextPatch}"
        $copyOfProject.VersioningStrategy.DonorPackage = $null
        $copyOfProject.VersioningStrategy.DonorPackageStepId = $null
        $copyOfProject.ReleaseCreationStrategy.ChannelId = $null
        $copyOfProject.ReleaseCreationStrategy.ReleaseCreationPackage = $null
        $copyOfProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId = $null
        $copyOfProject.AutoCreateRelease = $false
        
        $returnProject = Save-OctopusProject -Project $copyOfProject -DestinationData $destinationData        
        $destinationData.ProjectList = Update-OctopusList -itemList $destinationData.ProjectList -itemToReplace $returnProject

        return $returnProject
    }
    else
    {            
        $matchingProject.Description = $sourceProject.Description    
        
        Write-OctopusChangeLog " - Update $($sourceProject.Name)"
        
        $newVariableSetIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.VariableSetList -DestinationList $DestinationData.VariableSetList -IdList $copyOfProject.IncludedLibraryVariableSetIds -MatchingOption "IgnoreMismatch" -IdListName "$($SourceProject.Name) Library Variable Sets"
        $VariableSetIds = @($newVariableSetIds.NewIdList)

        $newScriptModuleIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.ScriptModuleList -DestinationList $DestinationData.ScriptModuleList -IdList $copyOfProject.IncludedLibraryVariableSetIds -MatchingOption "IgnoreMismatch" -IdListName "$($SourceProject.Name) Script Modules"
        $scriptModuleIds = @($newScriptModuleIds.NewIdList)

        $matchingProject.IncludedLibraryVariableSetIds = @($VariableSetIds)

        if ($scriptModuleIds.Count -gt 0)
        {
            foreach ($scriptModuleId in $scriptModuleIds)
            {
                $matchingProject.IncludedLibraryVariableSetIds += $scriptModuleId
            }
        } 

        $updatedProject = Save-OctopusProject -Project $matchingProject -DestinationData $destinationData               
        $destinationData.ProjectList = Update-OctopusList -itemList $destinationData.ProjectList -itemToReplace $updatedProject

        return $updatedProject
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
        Write-OctopusChangeLog "    - Set versioning strategy to a package"
    }
    else
    {
        $destinationProject.VersioningStrategy.Template = $sourceProject.VersioningStrategy.Template
        $destinationProject.VersioningStrategy.DonorPackage = $null
        $destinationProject.VersioningStrategy.DonorPackageStepId = $null
        Write-OctopusChangeLog "    - Set versioning strategy to template $($destinationProject.VersioningStrategy.Template)"
    }

    if ($null -ne $sourceProject.ReleaseCreationStrategy.ChannelId)
    {
        Write-OctopusVerbose "The project $($project.Name) has automatic release creation set."
        Write-OctopusChangeLog "    - Turn On Automatic Release Creation"
        $destinationProject.ReleaseCreationStrategy = Copy-OctopusObject -ItemToCopy $sourceProject.ReleaseCreationStrategy -ClearIdValue $false -SpaceId $null
        $destinationProject.ReleaseCreationStrategy.ChannelId = Convert-SourceIdToDestinationId -SourceList $sourceChannels -DestinationList $destinationChannels -IdValue $sourceProject.ReleaseCreationStrategy.ChannelId -ItemName "$($copyOfProject.Name) Automatic Release Creation Channel" -MatchingOption "ErrorUnlessExactMatch"
        $destinationProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId = Convert-OctopusProcessDeploymentStepId -sourceProcess $sourceDeploymentProcess -destinationProcess $destinationDeploymentProcess -sourceId $sourceProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId
        $destinationProject.AutoCreateRelease = $true
    }
    else 
    {
        $destinationProject.ReleaseCreationStrategy.ChannelId = $null
        $destinationProject.ReleaseCreationStrategy.ReleaseCreationPackage = $null
        $destinationProject.ReleaseCreationStrategy.ReleaseCreationPackageStepId = $null
        $destinationProject.AutoCreateRelease = $false    
        Write-OctopusChangeLog "    - Turn Off Automatic Release Creation"
    }
    
    $updatedProject = Save-OctopusProject -Project $destinationProject -DestinationData $destinationData
    $destinationData.ProjectList = Update-OctopusList -itemList $destinationData.ProjectList -itemToReplace $updatedProject

    Write-OctopusSuccess "Finished cloning release versioning settings for project $($project.Name)"

    return $updatedProject
}
