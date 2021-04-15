function Copy-OctopusTenantVariables
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions        
    )

    Write-OctopusChangeLog "Tenant Variables"

    if ($cloneScriptOptions.CloneTenantVariables -eq $false)
    {
        Write-OctopusWarning "Clone tenant variables script option is not turned on, skipping"
        Write-OctopusChangeLog " - Clone tenant variables is not enabled, skipping"
        return
    }

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TenantList -itemType "Tenants" -filters $cloneScriptOptions.TenantsToClone
    
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No tenants found to clone matching the filters"
        return
    }
    
    foreach($sourceTenant in $filteredList)
    {
        $destinationTenant = Get-OctopusItemByName -ItemName $sourceTenant.Name -ItemList $destinationData.TenantList

        if ($null -eq $destinationTenant)
        {
            Write-OctopusChangeLog " - $($sourceTenant.Name) not found unable to clone variables"
            continue
        }

        Write-OctopusChangeLog " - Updating $($sourceTenant.Name)"

        $sourceTenantVariables = Get-OctopusTenantVariables -octopusData $sourceData -tenant $sourceTenant
        $destinationTenantVariables = Get-OctopusTenantVariables -octopusData $destinationData -tenant $destinationTenant

        $destinationTenantVariables.ProjectVariables = Copy-OctopusTenantProjectVariables -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -sourceTenant $sourceTenant -destinationTenant $destinationTenant -sourceTenantVariables $sourceTenantVariables -destinationTenantVariables $destinationTenantVariables
        $destinationTenantVariables.LibraryVariables = Copy-OctopusTenantLibraryVariables -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -sourceTenant $sourceTenant -destinationTenant $destinationTenant -sourceTenantVariables $sourceTenantVariables -destinationTenantVariables $destinationTenantVariables

        $updatedVariables = Save-OctopusTenantVariables -octopusData $destinationData -tenant $destinationTenant -tenantVariables $destinationTenantVariables     

        Write-OctopusSuccess "Tenant $($sourceTenant.Name) variables successfully cloned"    
    }        
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
            $destinationVariableTemplate = Get-OctopusItemByName -ItemList $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Templates -ItemName $projectTemplateVariable.Name
            $destinationVariableTemplateId = $destinationVariableTemplate.Id
            Write-OctopusVerbose "The destination id of the variable template is $destinationVariableTemplateId"
            
            foreach ($sourceEnvironmentId in $sourceTenant.ProjectEnvironments.$($sourceTenantVariableProject.Name))
            {   
                Write-OctopusVerbose "Converting the environment id $sourceEnvironmentId to the destination id"
                $destinationEnvironmentId = Convert-SourceIdToDestinationId -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdValue $sourceEnvironmentId
                $destinationEnvironment = Get-OctopusItemById -ItemId $destinationEnvironmentId -ItemList $destinationData.EnvironmentList

                $sourceHasValue = Test-OctopusObjectHasProperty -objectToTest $sourceTenantVariables.ProjectVariables.$($sourceTenantVariableProject.Name).Variables.$($sourceEnvironmentId) -propertyName $($projectTemplateVariable.Id)
                $destinationHasValue = Test-OctopusObjectHasProperty -objectToTest $destinationTenantVariables.ProjectVariables.$($matchingProjectId).Variables.$($destinationEnvironmentId) -propertyName $($destinationVariableTemplateId)

                if ($sourceHasValue -eq $false -and $destinationHasValue -eq $false)
                {
                    Write-OctopusVerbose "The source tenant is using the default value on the source, moving onto the next variable"
                    Write-OctopusChangeLog "       - No update to $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) because it is using the default value"
                    continue
                }
                elseif ($sourceHasValue -eq $false -and $destinationHasValue -eq $true -and $CloneScriptOptions.OverwriteExistingVariables -eq $true) 
                {
                    Write-OctopusVerbose "The source tenant is using the default value on the source, but the destination is not and overwrite variables is true, Resetting to default value"
                    Write-OctopusChangeLog "       - Resetting $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) to default"

                    $destinationTenantVariables.ProjectVariables.$($matchingProjectId.Name).Variables.$($destinationEnvironmentId).PSObject.Properties.Remove($destinationVariableTemplateId)

                    continue
                }
                elseif ($sourceHasValue -eq $false -and $destinationHasValue -eq $true -and $CloneScriptOptions.OverwriteExistingVariables -eq $false) 
                {
                    Write-OctopusVerbose "The source doesn't have a value but the destination does, overwrite is set to false, so leaving as is"
                    Write-OctopusChangeLog "       - No update to $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) because overwrite is set to false (would reset to default)"
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
                    Write-OctopusChangeLog "       - No update to $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name)"
                }
                elseif ($false -eq $added)
                {
                    Write-OctopusChangeLog "       - Updated $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) to $newValue"
                }
                else
                {
                    Write-OctopusChangeLog "       - Added $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) to $newValue"
                }
                
            }
        }     
    }

    return $destinationTenantVariables.ProjectVariables
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
        $libraryVariableSet = Get-OctopusItemById -ItemList $sourceData.VariableSetList -ItemId $sourceTenantLibraryVariable.Name
        Write-OctopusVerbose "The library variable set id for $($sourceTenantLibraryVariable.Name) on the destination is $matchingVariableSetId"    

        if ($destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Templates.Length -eq 0)
        {
            Write-OctopusVerbose "The library variable set $matchingVariableSetId doesn't have any variable templates, moving onto the next project."
            continue
        }    
        
        Write-OctopusChangeLog "   - Library Variable Set $($libraryVariableSet.Name)"
        
        Write-OctopusVerbose "The project $matchingVariableSetId has project templates, starting the clone for each environment"
        foreach ($projectTemplateVariable in $sourceTenantVariables.LibraryVariables.$($sourceTenantLibraryVariable.Name).Templates)
        {
            Write-OctopusVerbose "Looping through each environment assigned to $($sourceTenantLibraryVariable.Name) to see if $($projectTemplateVariable.Id) has a value."
            $destinationVariableTemplate = Get-OctopusItemByName -ItemList $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Templates -ItemName $projectTemplateVariable.Name
            $destinationVariableTemplateId = $destinationVariableTemplate.Id
            Write-OctopusVerbose "The destination id of the variable template is $destinationVariableTemplateId"
            
            $sourceHasValue = Test-OctopusObjectHasProperty -objectToTest $sourceTenantVariables.LibraryVariables.$($sourceTenantLibraryVariable.Name).Variables -propertyName $($projectTemplateVariable.Id)
            $destinationHasValue = Test-OctopusObjectHasProperty -objectToTest $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId

            if ($sourceHasValue -eq $false -and $destinationHasValue -eq $false)
            {
                Write-OctopusVerbose "The source tenant is using the default value on the source, moving onto the next variable"
                Write-OctopusChangeLog "     - No update to $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) because it is using the default value"
                continue
            }
            elseif ($sourceHasValue -eq $false -and $destinationHasValue -eq $true -and $CloneScriptOptions.OverwriteExistingVariables -eq $true) 
            {
                Write-OctopusVerbose "The source tenant is using the default value on the source, but the destination is not and overwrite variables is true, Resetting to default value"
                Write-OctopusChangeLog "     - Resetting $($projectTemplateVariable.Label) for Environment $($destinationEnvironment.Name) to default"

                $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables.PSObject.Properties.Remove($destinationVariableTemplateId)
                continue
            }
            elseif ($sourceHasValue -eq $false -and $destinationHasValue -eq $true -and $CloneScriptOptions.OverwriteExistingVariables -eq $false) 
            {
                Write-OctopusVerbose "The source doesn't have a value but the destination does, overwrite is set to false, so leaving as is"
                Write-OctopusChangeLog "     - No update to $($projectTemplateVariable.Label) because overwrite is set to false (would reset to default)"
                continue
            }                             
            
            $controlType = $projectTemplateVariable.DisplaySettings.'Octopus.ControlType'
            
            if ($controlType -eq "Sensitive")
            {     
                $newValue = "DUMMY VALUE"
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $false

                if ($added)
                {
                    Write-OctopusPostCloneCleanUp "The variable $($projectTemplateVariable.Label) is a sensitive variable, value set to 'Dummy Value' for $($sourceTenant.Name) in environment $destinationEnvironmentId"
                }
            }
            elseif ($controlType -match ".*Account")
            {
                $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $sourceTenantVariables.LibraryVariables.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            }
            elseif ($controlType -eq "Certificate")
            {
                $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.CertificateList -DestinationList $destinationData.CertificateList -IdValue $sourceTenantVariables.LibraryVariables.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            }
            elseif ($controlType -eq "WorkerPool")
            {
                $newValue = Convert-SourceIdToDestinationId -SourceList $sourceData.WorkerPoolList -DestinationList $destinationData.WorkerPoolList -IdValue $sourceTenantVariables.LibraryVariables.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            }
            else
            {
                $newValue = $sourceTenantVariables.LibraryVariables.$($sourceTenantLibraryVariable.Name).Variables.$($projectTemplateVariable.Id)
                $added = Add-PropertyIfMissing -objectToTest $destinationTenantVariables.LibraryVariables.$($matchingVariableSetId).Variables -propertyName $destinationVariableTemplateId -propertyValue $newValue -overwriteIfExists $CloneScriptOptions.OverwriteExistingVariables
            } 
            
            if ($null -eq $added)
            {
                Write-OctopusChangeLog "     - No update to $($projectTemplateVariable.Label)"
            }
            elseif ($false -eq $added)
            {
                Write-OctopusChangeLog "     - Updated $($projectTemplateVariable.Label) to $newValue"
            }
            else
            {
                Write-OctopusChangeLog "     - Added $($projectTemplateVariable.Label) to $newValue"
            }
        }     
    }

    return $destinationTenantVariables.LibraryVariables
}