function Copy-OctopusSpaceTeamUserRoles
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    Write-OctopusChangeLog "Team Role Scoping"

    if ($destinationData.HasSpaces -eq $false)
    {
        Write-OctopusWarning "The destination does not support spaces, therefore it does not support the new team structure, exiting team cloning"
        Write-OctopusChangeLog " - The destination does not support spaces, skipping (the API format is too different)"
        return
    }

    if ($cloneScriptOptions.CloneTeamUserRoleScoping -eq $false)
    {
        Write-OctopusWarning "The option CloneTeamUserRoleScoping was set to false, skipping cloning the team user roles"
        Write-OctopusChangeLog " - The option CloneUserTeamRoleScoping was set to false, skipping."
        return
    }
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TeamList -itemType "Space Teams User Role Scoping" -filters $cloneScriptOptions.SpaceTeamsToClone        
    
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No team/role scopings found to clone matching the filters"
        return
    }    

    Write-OctopusPostCloneCleanUpHeader "*************Starting Teams User Roles*************"
    foreach ($team in $filteredList)
    {
        Write-OctopusChangeLog " - $($team.Name)"
        if ($null -eq $team.SpaceId)
        {
            Write-OctopusVerbose "The team $($team.Name) is a space team, skipping"
            Write-OctopusChangeLog "    - Is a space team, skipping"
            continue
        }

        Write-OctopusVerbose "Starting clone of team $($team.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $team.Name -ItemList $destinationData.teamList                

        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "Team $($team.Name) does not exist in destination, skipping"
            Write-OctopusChangeLog "    - Does not exist in destination, skipping"    
            continue
        }

        Write-OctopusVerbose "Team $($team.Name) was found in the destination, updating the scoping"                    

        $sourceUserRoleScoping = Get-OctopusTeamScopedUserRoleList -team $team -OctopusData $sourceData
        $destinationUserRoleScoping = Get-OctopusTeamScopedUserRoleList -team $matchingItem -OctopusData $DestinationData
        
        if ($destinationUserRoleScoping.Length -gt 0)
        {
            Write-OctopusVerbose "The team $($team.Name) in the destination already has user roles scoped to them, skipping"
            Write-OctopusChangeLog "    - Already has roles scoped to it, skipping"
            continue
        }

        foreach ($role in $sourceUserRoleScoping)
        {
            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $role -SpaceId $destinationData.SpaceId -ClearIdValue $true      

            $copyOfItemToClone.UserRoleId = Convert-SourceIdToDestinationId -sourceList $sourceData.UserRoleList -destinationList $sourceData.UserRoleList -idValue $role.UserRoleId  -ItemName "$($copyOfItem.Name) User Role" -ThrowErrorOnMismatch $true                      

            if ($null -ne $copyOfItemToClone.UserRoleId)
            {
                Write-OctopusChangeLog " - $($team.Name) adding $($copyOfItemToClone.UserRoleId)"

                $copyOfItemToClone.TeamId = $matchingItem.Id
                $copyOfItemToClone.ProjectIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdList $role.ProjectIds) 
                $copyOfItemToClone.EnvironmentIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdList $role.EnvironmentIds) 
                $copyOfItemToClone.TenantIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.TenantList -DestinationList $destinationData.TenantList -IdList $role.TenantIds) 
                $copyOfItemToClone.ProjectGroupIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.ProjectGroupList -DestinationList $destinationData.ProjectGroupList -IdList $role.ProjectGroupIds)             

                Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Environment Scoping" -idList $copyOfItemToClone.EnvironmentIds -destinationList $DestinationData.EnvironmentList
                Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Project Group Scoping" -idList $copyOfItemToClone.ProjectGroupIds -destinationList $DestinationData.ProjectGroupList
                Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Project Scoping" -idList $copyOfItemToClone.ProjectIds -destinationList $DestinationData.ProjectList
                Write-OctopusChangeLogListDetails -prefixSpaces "    " -listType "Tenant Scoping" -idList $copyOfItemToClone.TenantIds -destinationList $DestinationData.TenantList

                Save-OctopusTeamScopedRoles -teamScopedUserRoles $copyOfItemToClone -destinationData $destinationData 
            }           
            else
            {
                Write-OctopusVerbose "There is no matching role for $($role.UserRoleId), skipping this scoping"
                Write-OctopusChangeLog "    - Couldn't find a matching role, skipping"    
            }
        }                            

        Write-OctopusPostCloneCleanUp "Role Scoping was created for $($team.Name), please verify it looks correct."        
    }

    Write-OctopusPostCloneCleanUpHeader "*************End Teams User Roles******************"

    Write-OctopusSuccess "User scoped roles successfully cloned to teams"        
}
