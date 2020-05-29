function Get-OctopusBaseApiInformation
{
    param(
        $octopusData
    )

    return Get-OctopusApi -EndPoint "/api" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null 
}
function Get-OctopusSpaceList
{
    param (
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "spaces?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

Function Get-OctopusProjectList
{
    param (        
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "Projects?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusEnvironmentList
{
    param (        
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "Environments?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusLibrarySetList
{
    param (
        $octopusData
    )
    
    return Get-OctopusApiItemList -EndPoint "libraryvariablesets?skip=0&take=1000&contentType=Variables" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusVariableSetVariables
{
    param (
        $variableSet,
        $octopusData
    )
    
    return Get-OctopusApi -EndPoint $variableSet.Links.Variables -ApiKey $octopusData.OctopusApiKey -SpaceId $null -OctopusUrl $octopusData.OctopusUrl 
}

Function Get-OctopusScriptModuleList
{
    param (
        $octopusData
    )
    
    return Get-OctopusApiItemList -EndPoint "libraryvariablesets?skip=0&take=1000&contentType=ScriptModule" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusStepTemplateList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "actiontemplates?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusWorkerPoolList
{
    param(
        $octopusData
    )

    if ($null -eq $octopusData.HasWorkers -or $octopusData.HasWorkers -eq $true)
    {
        return Get-OctopusApiItemList -EndPoint "workerpools?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
    }
    
    return @()
}

Function Get-OctopusFeedList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "feeds?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusInfrastructureAccountList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "accounts?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

function Get-OctopusCommunityActionTemplateList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "communityactiontemplates?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

Function Get-OctopusTenantTagSetList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "tagsets?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusLifeCycleList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "lifecycles?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-ProjectGroupList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "projectgroups?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusTenantList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "tenants?skip=0&take=10000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusMachinePolicyList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "machinepolicies?skip=0&take=10000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusWorkerList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "workers?skip=0&take=10000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusTargetList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "machines?skip=0&take=10000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

Function Get-OctopusTeamList
{
    param(
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "teams?spaces=$($octopusData.SpaceId)&includeSystem=true" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

Function Get-OctopusUserList
{
    param(        
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "users?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

Function Get-OctopusUserRoleList
{
    param(        
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "usersroles?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

function Get-OctopusSpaceId
{
    param(
        $octopusData        
    )

    if ($octopusData.hasSpaces -eq $true)
    {                
        Write-OctopusVerbose "Getting Space Information from $octopusUrl"
        $SpaceList = Get-OctopusSpaceList -octopusData $octopusData
        $Space = Get-OctopusItemByName -ItemList $SpaceList -ItemName $spaceName

        if ($null -eq $Space)
        {
            Throw "Unable to find space $spaceName on $octopusUrl please confirm it exists and try again."
        }

        return $Space.Id        
    }
    else
    {
        return $null
    }
}

function Get-OctopusProjectChannelList
{
    param(
        $project,
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "projects/$($project.Id)/channels" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

function Get-OctopusProjectDeploymentProcess
{
    param(
        $project,
        $octopusData
    )

    return Get-OctopusApi -EndPoint $project.Links.DeploymentProcess -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

function Get-OctopusProjectRunbookList
{
    param(
        $project,
        $octopusData
    )

    return Get-OctopusApiItemList -EndPoint "projects/$($project.Id)/runbooks" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $octopusData.SpaceId
}

function Get-OctopusRunbookProcess
{
    param(
        $runbook,
        $octopusData
    )

    return Get-OctopusApi -EndPoint $runbook.Links.RunbookProcesses -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

function Get-OctopusTeamScopedUserRoleList
{
    param(
        $team,
        $octopusData           
    )

    return Get-OctopusApiItemList -EndPoint "teams/$($team.Id)/scopeduserroles?skip=0&take=1000" -ApiKey $octopusData.OctopusApiKey -OctopusUrl $octopusData.OctopusUrl -SpaceId $null
}

function Save-OctopusAccount
{
    param(
        $account,
        $destinationData
    )

    return Save-OctopusApiItem -Item $account -Endpoint "accounts" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusEnvironment
{
    param(
        $environment,
        $destinationData
    )

    return Save-OctopusApiItem -Item $environment -Endpoint "Environments" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusExternalFeed
{
    param(
        $externalFeed,
        $destinationData
    )

    return Save-OctopusApiItem -Item $externalFeed -Endpoint "Feeds" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusLifecycle
{
    param(
        $lifecycle,
        $destinationData
    )

    return Save-OctopusApiItem -Item $lifecycle -Endpoint "lifecycles" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusMachinePolicy
{
    param(
        $machinePolicy,
        $destinationData
    )

    return Save-OctopusApiItem -Item $machinePolicy -Endpoint "machinepolicies" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusProjectChannel
{
    param(
        $projectChannel,
        $destinationData
    )

    return Save-OctopusApiItem -Item $projectChannel -Endpoint "channels" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusProject
{
    param(
        $project,
        $destinationData
    )

    return Save-OctopusApiItem -Item $project -Endpoint "projects" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusProjectDeploymentProcess
{
    param(
        $deploymentProcess,
        $destinationData
    )

    return Save-OctopusApiItem -Item $deploymentProcess -Endpoint "deploymentprocesses" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusProjectGroup
{
    param(
        $projectGroup,
        $destinationData
    )

    return Save-OctopusApiItem -Item $projectGroup -Endpoint "projectgroups" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusProjectRunbook
{
    param(
        $runbook,
        $destinationData
    )

    return Save-OctopusApiItem -Item $runbook -Endpoint "runbooks" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusProjectRunbookProcess
{
    param(
        $runbookProcess,
        $destinationData
    )

    return Save-OctopusApiItem -Item $runbookProcess -Endpoint "runbookProcesses" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusStepTemplate
{
    param(
        $stepTemplate,
        $destinationData
    )

    return Save-OctopusApiItem -Item $stepTemplate -Endpoint "actiontemplates" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusTarget
{
    param(
        $target,
        $destinationData
    )

    return Save-OctopusApiItem -Item $target -Endpoint "machines" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusTeam
{
    param(
        $team,
        $destinationData
    )

    return Save-OctopusApiItem -Item $team -Endpoint "teams" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $null            
}

function Save-OctopusTeamScopedRoles
{
    param(
        $teamScopedUserRoles,
        $destinationData
    )

    return Save-OctopusApiItem -Item $teamScopedUserRoles -Endpoint "scopeduserroles" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $null            
}

function Save-OctopusTenant
{
    param(
        $tenant,
        $destinationData
    )

    return Save-OctopusApiItem -Item $tenant -Endpoint "tenants" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusTenantTagSet
{
    param(
        $tenantTagSet,
        $destinationData
    )

    return Save-OctopusApiItem -Item $tenantTagSet -Endpoint "TagSets" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusWorker
{
    param(
        $worker,
        $destinationData
    )

    return Save-OctopusApiItem -Item $worker -Endpoint "Workers" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusWorkerPool
{
    param(
        $workerPool,
        $destinationData
    )

    return Save-OctopusApiItem -Item $workerPool -Endpoint "workerpools" -ApiKey $DestinationData.OctopusApiKey -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId            
}

function Save-OctopusVariableSet
{
    param(
        $libraryVariableSet,
        $destinationData
    )

    return Save-OctopusApi -EndPoint "libraryvariablesets" -ApiKey $destinationData.OctopusApiKey -Method POST -Item $libraryVariableSet -OctopusUrl $DestinationData.OctopusUrl -SpaceId $DestinationData.SpaceId
}

function Save-OctopusVariableSetVariables
{
    param(
        $libraryVariableSetVariables,
        $destinationData
    )

    return Save-OctopusApi -EndPoint $libraryVariableSetVariables.Links.Self -ApiKey $destinationData.OctopusApiKey -Method "PUT" -Item $DestinationVariableSetVariables -OctopusUrl $DestinationData.OctopusUrl -SpaceId $null
}

function Save-OctopusCommunityStepTemplate
{
    param(
        $communityStepTemplate,
        $destinationData
    )

    return Save-OctopusApi -OctopusUrl $destinationData.OctopusUrl -SpaceId $null -EndPoint "/communityactiontemplates/$($communityStepTemplate.Id)/installation/$($destinationData.SpaceId)" -ApiKey $destinationData.OctopusApiKey -Method POST
}