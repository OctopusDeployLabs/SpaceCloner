function Copy-OctopusTenants
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TenantList -itemType "Tenants" -filters $cloneScriptOptions.TenantsToClone

    Write-OctopusChangeLog "Tenants"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No tenants found to clone matching the filters"
        return
    }
    
    foreach($tenant in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of tenant $($tenant.Name)"
        
        $matchingTenant = Get-OctopusItemByName -ItemName $tenant.Name -ItemList $destinationData.TenantList

        if ($null -eq $matchingTenant)
        {
            Write-OctopusVerbose "The tenant $($tenant.Name) doesn't exist on the source, copying over."
            Write-OctopusChangeLog " - Add $($tenant.Name)"

            $tenantToAdd = Copy-OctopusObject -ItemToCopy $tenant -ClearIdValue $true -SpaceId $destinationData.SpaceId
            $tenantToAdd.Id = $null
            $tenantToAdd.SpaceId = $destinationData.SpaceId
            $tenantToAdd.ProjectEnvironments = @{}                        

            $destinationTenant = Save-OctopusTenant -Tenant $tenantToAdd -destinationData $destinationData
            $destinationData.TenantList += $destinationTenant

            Copy-OctopusItemLogo -sourceItem $tenant -destinationItem $destinationTenant -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions
            Copy-OctopusTenantVariables -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -sourceTenant $tenant -destinationTenant $destinationTenant        
        }
        else
        {
            Write-OctopusVerbose "Updating $($tenant.Name) projects"
            Write-OctopusChangeLog " - Update $($tenant.Name) projects"

            $projectFilteredList = Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ProjectsToClone
            $tenantToUpdate = Copy-OctopusObject -itemToCopy $matchingTenant -clearIdValue $false -spaceId $destinationData.SpaceId

            foreach ($sourceProject in $projectFilteredList)
            {
                $sourceProjectId = $sourceProject.Id
                if ($null -eq (Get-Member -InputObject $tenant.ProjectEnvironments -Name $sourceProjectId -MemberType Properties))
                {
                    continue
                }
                
                Write-OctopusVerbose "Attempting to matching $sourceProjectId with source"
		        $matchingProjectId = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $sourceProjectId
                Write-OctopusVerbose "The project id for $sourceProjectId on the destination is $matchingProjectId"

                $scopedEnvironments = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdList $tenant.ProjectEnvironments.$sourceProjectId)

                Add-PropertyIfMissing -objectToTest $tenantToUpdate.ProjectEnvironments -propertyName $matchingProjectId -propertyValue @($scopedEnvironments)
                $tenantToUpdate.ProjectEnvironments.$matchingProjectId = @($scopedEnvironments)
            }

            $updatedTenant = Save-OctopusTenant -Tenant $tenantToUpdate -destinationData $destinationData
            $destinationData.TenantList = Update-OctopusList -itemList $destinationData.TenantList -itemToReplace $updatedTenant
	    
	        Copy-OctopusTenantVariables -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -sourceTenant $tenant -destinationTenant $matchingTenant
        }
    }

    Write-OctopusSuccess "Tenants successfully cloned"    
}