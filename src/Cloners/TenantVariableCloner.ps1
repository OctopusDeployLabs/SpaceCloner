function Copy-OctopusTenantVariables
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions,
        $sourceTenant,
        $destinationTenant
    )
    
    $sourceTenantVariables = Get-OctopusTenantVariables -octopusData $sourceData -tenant $sourceTenant
    $destinationTenantVariables = Get-OctopusTenantVariables -octopusData $destinationData -tenant $destinationTenant

    $sourceTenantVariableProjects = $sourceTenantVariables.ProjectVariables.PSObject.Properties

    foreach ($sourceTenantVariableProject in $sourceTenantVariableProjects)
    {
        Write-OctopusVerbose "Attempting to match project Id $($sourceTenantVariableProject.Name) with destination Id"
        $matchingProjectId = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $sourceTenantVariableProject.Name
        Write-OctopusVerbose "The project id for $($sourceTenantVariableProject.Name) on the destination is $matchingProjectId"
        
        if ((Test-OctopusObjectHasProperty -objectToTest $destinationTenant.ProjectEnvironments -propertyName $($matchingProjectId)) -eq $false)
        {
            Write-OctopusVerbose "The destination tenant is is not assigned to this project.  Moving onto the next project."
            continue
        }

        if ($destinationTenantVariables.ProjectVariables.$($matchingProjectId).Templates.Length -eq 0)
        {
            Write-OctopusVerbose "The project $matchingProjectId doesn't have any variable templates, moving onto the next project."
            continue
        }           
        
        Write-OctopusVerbose "The project $matchingProjectId has project templates, starting the clone for each environment"
        foreach ($projectTemplateVariable in $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Templates)
        {
            Write-OctopusVerbose "Looping through each environment assigned to $($sourceTenantVariableProject.Name) to see if $($projectTemplateVariable.Id) has a value."
            $destinationVariableTemplateId = Get-OctopusItemByName -ItemList $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Templates -ItemName $projectTemplateVariable.Name
            Write-OctopusVerbose "The destination id of the variable template is $destinationVariableTemplateId"
            
            foreach ($sourceEnvironmentId in $sourceTenant.ProjectEnvironments.$($sourceTenantVariableProject.Name))
            {
                if ((Test-OctopusObjectHasProperty -objectToTest $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId) -propertyName $($projectTemplateVariable.Id)) -eq $false)
                {
                    Write-OctopusVerbose "The source tenant is using the default value on the source, moving onto the next variable"
                    continue
                }                                

                Write-OctopusVerbose "Converting the environment id $sourceEnvironmentId to the destination id"
                $destinationEnvironmentId = Convert-SourceIdToDestinationId -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdValue $sourceEnvironmentId
                Write-OctopusVerbose "The destination environment id is $destinationEnvironmentId"                
            }
        }     
    }

    Write-OctopusSuccess "Tenant $($sourceTenant.Name) variables successfully cloned"    
}