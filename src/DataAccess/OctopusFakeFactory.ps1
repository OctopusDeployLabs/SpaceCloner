function New-OctopusFakeLibraryVariableSetValues
{
    param (
        $owner,
        $octopusData,
        $isProject)
    
    $variableSetVariables = @{
        Id = (New-Guid).ToString()
        OwnerId = $owner.Id
        Version = 1
        Variables = @()
        ScopeValues = @{
            Environments = New-OctopusFakeListForVariableScoping -itemList $octopusData.EnvironmentList
            Machines = New-OctopusFakeListForVariableScoping -itemList $octopusData.TargetList
            TenantTags = New-OctopusFakeTagSetForVariableScoping -itemList $octopusData.TenantTagList
            Roles = New-OctopusFakeRoleListForVariableScoping -targetList $octopusData.TargetList
        }
    }

    if ($isProject -eq $true)
    {
        $projectId = $owner.Id

        $variableSetVariables.ScopeValues.Channels = New-OctopusFakeListForVariableScoping -itemList $octopusData.ProjectChannels.$projectId
        $variableSetVariables.ScopeValues.Processes = New-OctopusFakeProcessListForVariableScoping -runbookList $octopusData.ProjectRunbooks.$projectId -project $owner
        $variableSetVariables.ScopeValues.Actions = New-OctopusFakeStepListForVariableScoping -deploymentProcess $octopusData.ProjectProcesses.$projectId
    }

    return $variableSetVariables
}

function New-OctopusFakeTenantVariables
{
    param (
        $tenant
    )

    return @{
        TenantId = $tenant.Id
        TenantName = $tenant.Name
        ProjectVariables = @{}
        LibraryVariables = @{}
        SpaceId = $null
    }
}

function New-FakeUserRoleScoping
{
    return @{
        ItemType = "ScopedUserRole"
        TotalResults = 0
        ItemsPerPage = 30
        NumberOfPages = 1
        LastPageNumber = 0
        Items = @()
    }
}

function New-OctopusFakeProjectDeploymentOrRunbookProcess
{
    param (
        $project
    )

    return @{
        Id = (New-Guid).ToString()
        OwnerId = $project.Id
        Steps = @()
        Version = 1
        LastSnapshotId = $null
        SpaceId = $null
    }
}

function New-OctopusFakeProjectChannelList
{
    param (
        $project
    )

    $channelList = @()

    $channelList += @{
        Id = $null
        Name = "Default"
        Description = $null
        ProjectId = $project.Id
        LifeCycleId = $null
        IsDefault = $true
        Rules = @()
        TenantTags = @()
        SpaceId = $null
    }

    return $channelList
}

function New-OctopusFakeListForVariableScoping
{
    param (
        $itemList
    )

    $returnList = @()

    foreach ($item in $itemList)
    {
        $returnList += @{
            Id = $item.Id
            Name = $item.Name
        }
    }

    return $returnList
}

function New-OctopusFakeRoleListForVariableScoping
{
    param (
        $targetList
    )

    $returnList = @()
    $rolesAdded = @()

    foreach ($target in $targetList)
    {
        foreach ($role in $target.Roles)
        {
            if ($rolesAdded -notcontains $role)
            {
                $returnList += @{
                    Id = $role
                    Name = $role
                }

                $rolesAdded += $role
            }
        }
    }

    return $returnList
}

function New-OctopusFakeTagSetForVariableScoping
{
    param (
        $tenantTagList
    )

    $returnList = @()

    foreach ($tenantTag in $tenantTagList)
    {
        foreach ($tag in $tenantTag.Tags)
        {
            $returnList += @{
                Id = $tag.CanonicalTagName
                Name = $tag.Name
            }
        }
    }

    return $returnList
}

function New-OctopusFakeProcessListForVariableScoping
{
    param (
        $runbookList,
        $project
    )

    $returnList = @()

    $returnList += @{
        ProcessType = "Deployment"
        Id = $project.Id
        Name = "Deployment Process"
    }

    foreach ($runbook in $runbookList)
    {
        $returnList += @{
            ProcessType = "Runbook"
            Id = $runbook.Id
            Name = $runbook.Name
        }
    }

    return $returnList
}

function New-OctopusFakeStepListForVariableScoping
{
    param (
        $deploymentProcess
    )

    $returnList = @()
    
    $stepCounter = 1
    foreach ($step in $deploymentProcess.Steps)
    {
        if ($step.Actions.Count -eq 1)
        {
            $returnList += @{
                Id = $step.Actions[0].Id
                Name = "$stepCounter. $($step.Actions[0].Name)"
            }
        }
        else 
        {
            $actionCounter = 1
            foreach ($action in $step.Actions)    
            {
                $returnList += @{
                    Id = $action.Id
                    Name = "$stepCounter.$ActionCounter. $($action.Name)"
                }
            }
        }

        $stepCounter += 1
    }
    
    return $returnList
}

function New-OctopusFakeCommunityStep 
{
    param (
        $communityStepTemplate
    )

    return 
    {
        Id = (New-Guid).ToString(),
        ActionType = $communityStepTemplate.Type,
        Description = $communityStepTemplate.Description,
        Name = $communityStepTemplate.Name,
        Version = $communityStepTemplate.Version,
        Properties = $communityStepTemplate.Properties,
        Parameters = $communityStepTemplate.Parameters,
        Packages = @(),
        StepPackageId = $communityStepTemplate.StepPackageId,
        SpaceId = $null
        LastModifiedBy = $communityStepTemplate.Author,
        LastModifiedOn = $null
    }
}