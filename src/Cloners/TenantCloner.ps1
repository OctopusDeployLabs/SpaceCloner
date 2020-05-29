function Copy-OctopusTenants
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TenantList -itemType "Tenants" -filters $cloneScriptOptions.TenantsToClone

    if ($filteredList.length -eq 0)
    {
        return
    }
    
    foreach($tenant in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of tenant $($tenant.Name)"
        
        $matchingTenant = Get-OctopusItemByName -ItemName $tenant.Name -ItemList $destinationData.TenantList

        if ($null -eq $matchingTenant)
        {
            Write-OctopusVerbose "The tenant $($tenant.Name) doesn't exist on the source, copying over."
            $tenantToAdd = Copy-OctopusObject -ItemToCopy $tenant -ClearIdValue $true -SpaceId $destinationData.SpaceId
            $tenantToAdd.Id = $null
            $tenantToAdd.SpaceId = $destinationData.SpaceId
            $tenantToAdd.ProjectEnvironments = @{}            

            Write-OctopusVerbose "Attempting to assign all the tenant projects"
            $tenant.ProjectEnvironments.PSObject.Properties | ForEach-Object {
                Write-OctopusVerbose "Attempting to matching $($_.Name) with source"
                $matchingProjectId = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $_.Name

                Write-OctopusVerbose "Attempting to match the environment list with source"
                $scopedEnvironments = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdList $_.Value)

                if ($scopedEnvironments.Length -gt 0 -and $null -ne $matchingProjectId)
                {
                    Write-OctopusVerbose "The matching environments were found and matching project was found, let's scope it to the tenant"
                    $tenantToAdd.ProjectEnvironments[$matchingProjectId] = @($scopedEnvironments)
                }
            }            

            $destinationTenant = Save-OctopusTenant -Tenant $tenantToAdd -destinationData $destinationData           

            Copy-OctopusItemLogo -sourceItem $tenant -destinationItem $destinationTenant -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions
        }
        else
        {
            Write-OctopusVerbose "The tenant $($tenant.Name) already exists on the source, skipping."
        }
    }

    Write-OctopusSuccess "Tenants successfully cloned, reloading destination list"
    $destinationData.TenantList = Get-OctopusTenantList -OctopusData $DestinationData
}