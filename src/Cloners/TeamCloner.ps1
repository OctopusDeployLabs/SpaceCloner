function Copy-OctopusSpaceTeams
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )

    if ($destinationData.HasSpaces -eq $false)
    {
        Write-OctopusWarning "The destination does not support spaces, therefore it does not support the new team structure, exiting team cloning"
        return
    }
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TeamList -itemType "Space Teams" -filters $cloneScriptOptions.SpaceTeamsToClone        
    
    if ($filteredList.length -eq 0)
    {
        return
    }

    Write-OctopusPostCloneCleanUpHeader "*************Starting Teams*************"
    foreach ($team in $filteredList)
    {
        if ($null -eq $team.SpaceId)
        {
            Write-OctopusVerbose "The team $($team.Name) is a space team, skipping"
            continue
        }

        Write-OctopusVerbose "Starting clone of team $($team.Name)"
        
        $matchingItem = Get-OctopusItemByName -ItemName $team.Name -ItemList $destinationData.teamList                

        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "Team $($team.Name) was not found in destination, creating new record."                    

            $copyOfItemToClone = Copy-OctopusObject -ItemToCopy $team -SpaceId $destinationData.SpaceId -ClearIdValue $true  
            
            $copyOfItemToClone.MemberUserIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.UserList -DestinationList $destinationData.UserList -IdList $team.MemberUserIds)            
            $copyOfItemToClone.ExternalSecurityGroups = @()            

            Save-OctopusTeam -team $copyOfItemToClone -destinationData $destinationData            

            Write-OctopusPostCloneCleanUp "Team $($team.Name) was created, external security groups were cleared."
        }
        else 
        {
            Write-OctopusVerbose "Team $($team.Name) already exists in destination, skipping"    
        }
    }    
    Write-OctopusPostCloneCleanUpHeader "*************End Teams******************"

    Write-OctopusSuccess "Teams successfully cloned, reloading destination list"    
    $destinationData.TeamList = Get-OctopusTeamList -OctopusData $DestinationData
}
