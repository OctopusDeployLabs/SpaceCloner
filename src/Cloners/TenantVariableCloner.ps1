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

    $destinationTenantVariables.ProjectVariables = @(Copy-OctopusTenantProjectVariables -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -sourceTenant $sourceTenant -destinationTenant $destinationTenant -sourceTenantVariables $sourceTenantVariables -destinationTenantVariables $destinationTenantVariables)
    $destinationTenantVariables.LibraryVariables = @(Copy-OctopusTenantLibraryVariables -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -sourceTenant $sourceTenant -destinationTenant $destinationTenant -sourceTenantVariables $sourceTenantVariables -destinationTenantVariables $destinationTenantVariables)

    $updatedVariables = Save-OctopusTenantVariables -octopusData $destinationData -tenant $destinationTenant -tenantVariables $destinationTenantVariables     

    Write-OctopusSuccess "Tenant $($sourceTenant.Name) variables successfully cloned"    
}

function Copy-OctopusTenantProjectVariables
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions,
        $sourceTenant,
        $destinationTenant,
        $sourceTenantVariables,
        $destinationTenantVariables
    )

    $sourceTenantVariableProjects = $sourceTenantVariables.ProjectVariables.PSObject.Properties
    Write-OctopusChangeLog "   - Project Variables"

    foreach ($sourceTenantVariableProject in $sourceTenantVariableProjects)
    {
        Write-OctopusVerbose "Attempting to match project Id $($sourceTenantVariableProject.Name) with destination Id"
        $matchingProjectId = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $sourceTenantVariableProject.Name
        $project = Get-OctopusItemById -ItemId $matchingProjectId -itemList $destinationData.ProjectList
        $projectName = $project.Name

        Write-OctopusVerbose "The project id for $($sourceTenantVariableProject.Name) on the destination is $matchingProjectId"
        
        if ((Test-OctopusObjectHasProperty -objectToTest $destinationTenant.ProjectEnvironments -propertyName $($matchingProjectId)) -eq $false)
        {
            Write-OctopusVerbose "The destination tenant is is not assigned to this project.  Moving onto the next project."
            continue
        }

        if ($destinationTenantVariables.ProjectVariables.$($matchingProjectId).Templates.Length -eq 0)
        {
            Write-OctopusVerbose "The project $matchingProjectId doesn't have any variable templates, moving onto the next project."
            Write-OctopusChangeLog "     - Project $projectName doesn't have variable templates"
            continue
        }
        else
        {
            Write-OctopusChangeLog "     - Project $projectName"
        }           
        
        Write-OctopusVerbose "The project $matchingProjectId has project templates, starting the clone for each environment"
        foreach ($projectTemplateVariable in $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Templates)
        {
            Write-OctopusVerbose "Looping through each environment assigned to $($sourceTenantVariableProject.Name) to see if $($projectTemplateVariable.Id) has a value."
            $destinationVariableTemplateId = Get-OctopusItemByName -ItemList $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Templates -ItemName $projectTemplateVariable.Name
            Write-OctopusVerbose "The destination id of the variable template is $destinationVariableTemplateId"
            
            foreach ($sourceEnvironmentId in $sourceTenant.ProjectEnvironments.$($sourceTenantVariableProject.Name))
            {   
                Write-OctopusVerbose "Converting the environment id $sourceEnvironmentId to the destination id"
                $destinationEnvironmentId = Convert-SourceIdToDestinationId -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdValue $sourceEnvironmentId
                $destinationEnvironment = Get-OctopusItemById -ItemId $destinationEnvironmentId -ItemList $destinationData.EnvironmentList

                if ((Test-OctopusObjectHasProperty -objectToTest $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId) -propertyName $($projectTemplateVariable.Id)) -eq $false)
                {
                    Write-OctopusVerbose "The source tenant is using the default value on the source, moving onto the next variable"
                    Write-OctopusChangeLog "     - No update to $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name)"
                    continue
                }                                                
                
                Write-OctopusVerbose "The destination environment id is $destinationEnvironmentId"
                
                $controlType = $projectTemplateVariable.DisplaySettings.'Octopus.ControlType'
                
                if ($controlType -eq "Sensitive")
                {        
                    $newValue = "DUMMY VALUE"            
                    $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Variables.$($destinationEnvironmentId) -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $false

                    if ($added)
                    {
                        Write-OctopusPostCloneCleanUp "The variable $($projectTemplateVariable.Label) is a sensitive variable, value set to 'Dummy Value' for $($sourceTenant.Name) in environment $destinationEnvironmentId"
                    }
                }
                elseif ($controlType -match ".*Account")
                {
                    $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId).$($projectTemplateVariable.Id)
                    $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Variables.$($destinationEnvironmentId) -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
                }
                elseif ($controlType -eq "Certificate")
                {
                    $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.CertificateList -DestinationList $destinationData.CertificateList -IdValue $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId).$($projectTemplateVariable.Id)
                    $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Variables.$($destinationEnvironmentId) -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
                }
                elseif ($controlType -eq "WorkerPool")
                {
                    $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.WorkerPoolList -DestinationList $destinationData.WorkerPoolList -IdValue $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId).$($projectTemplateVariable.Id)
                    $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Variables.$($destinationEnvironmentId) -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
                }
                else
                {
                    $newValue = $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId).$($projectTemplateVariable.Id)
                    $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Variables.$($destinationEnvironmentId) -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
                }   
                
                if ($null -eq $added)
                {
                    Write-OctopusChangeLog "     - No update to $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name)"
                }
                elseif ($false -eq $added)
                {
                    Write-OctopusChangeLog "     - Updated $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) to $newValue"
                }
                else {
                    Write-OctopusChangeLog "     - Added $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) to $newValue"
                }
                
            }
        }     
    }

    return @($destinationTenantVariables.ProjectVariables)
}

function Copy-OctopusTenantLibraryVariables
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions,
        $sourceTenant,
        $destinationTenant,
        $sourceTenantVariables,
        $destinationTenantVariables
    )

    $sourceTenantLibraryVariableLIst = $sourceTenantVariables.LibraryVariables.PSObject.Properties

    foreach ($sourceTenantLibraryVariable in $sourceTenantLibraryVariableList)
    {
        Write-OctopusVerbose "Attempting to match library variable set Id $($sourceTenantLibraryVariable.Name) with destination Id"
        $matchingVariableSetId = Convert-SourceIdToDestinationId -SourceList $sourceData.VariableSetList -DestinationList $destinationData.VariableSetList -IdValue $sourceTenantLibraryVariable.Name
        Write-OctopusVerbose "The library variable set id for $($sourceTenantLibraryVariable.Name) on the destination is $matchingVariableSetId"    

        if ($destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Templates.Length -eq 0)
        {
            Write-OctopusVerbose "The project $matchingVariableSetId doesn't have any variable templates, moving onto the next project."
            continue
        }           
        
        Write-OctopusVerbose "The project $matchingVariableSetId has project templates, starting the clone for each environment"
        foreach ($projectTemplateVariable in $sourceTenantVariables.LibraryVariableSets.$($sourceTenantLibraryVariable.Name).Templates)
        {
            Write-OctopusVerbose "Looping through each environment assigned to $($sourceTenantLibraryVariable.Name) to see if $($projectTemplateVariable.Id) has a value."
            $destinationVariableTemplateId = Get-OctopusItemByName -ItemList $destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Templates -ItemName $projectTemplateVariable.Name
            Write-OctopusVerbose "The destination id of the variable template is $destinationVariableTemplateId"
            
            if ((Test-OctopusObjectHasProperty -objectToTest $sourceTenantVariables.LibraryVariableSets.$($sourceTenantLibraryVariable.Name).Variables -propertyName $($projectTemplateVariable.Id)) -eq $false)
            {
                Write-OctopusVerbose "The source tenant is using the default value on the source, moving onto the next variable"
                continue
            }                                
            
            $controlType = $projectTemplateVariable.DisplaySettings.'Octopus.ControlType'
            
            if ($controlType -eq "Sensitive")
            {     
                $newValue = "DUMMY VALUE"
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $false

                if ($added)
                {
                    Write-OctopusPostCloneCleanUp "The variable $($projectTemplateVariable.Label) is a sensitive variable, value set to 'Dummy Value' for $($sourceTenant.Name) in environment $destinationEnvironmentId"
                }
            }
            elseif ($controlType -match ".*Account")
            {
                $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $sourceTenantVariables.LibraryVariableSets.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            }
            elseif ($controlType -eq "Certificate")
            {
                $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.CertificateList -DestinationList $destinationData.CertificateList -IdValue $sourceTenantVariables.LibraryVariableSets.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            }
            elseif ($controlType -eq "WorkerPool")
            {
                $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.WorkerPoolList -DestinationList $destinationData.WorkerPoolList -IdValue $sourceTenantVariables.LibraryVariableSets.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            }
            else
            {
                $newValue = $sourceTenantVariables.LibraryVariableSets.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariableSets.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            } 
            
            
        }     
    }

    return @($destinationTenantVariables.LibraryVariableSets)
}