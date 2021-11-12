function Copy-OctopusVariableSetValues
{
    param
    (
        $SourceVariableSetVariables,
        $DestinationVariableSetVariables,        
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )      
    
    Write-OctopusChangeLog "    - Variables"
    foreach ($octopusVariable in $sourceVariableSetVariables.Variables)
    {                             
        $variableName = $octopusVariable.Name        
        
        if (Get-Member -InputObject $octopusVariable.Scope -Name "Environment" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has environment scoping, converting to destination values"
            
            $NewEnvironmentIds = Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Environments -DestinationList $DestinationVariableSetVariables.ScopeValues.Environments -IdList $octopusVariable.Scope.Environment -MatchingOption $CloneScriptOptions.VariableEnvironmentScopingMatch -IdListName "$variableName Environment Scoping"

            if ($NewEnvironmentIds.CanProceed -eq $false)
            {
                continue
            }

            $octopusVariable.Scope.Environment = @($NewEnvironmentIds.NewIdList)            
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Channel" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has channel scoping, converting to destination values"
            $NewChannelIds = Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Channels -DestinationList $DestinationVariableSetVariables.ScopeValues.Channels -IdList $octopusVariable.Scope.Channel -MatchingOption $CloneScriptOptions.VariableChannelScopingMatch -IdListName "$variableName Channel Scoping"

            if ($NewChannelIds.CanProceed -eq $false)
            {
                continue
            }

            $octopusVariable.Scope.Channel = @($NewChannelIds.NewIdList)            
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "ProcessOwner" -MemberType Properties)
        {
            if ($destinationData.HasRunbooks)
            {
                Write-OctopusVerbose "$variableName has process owner scoping, converting to destination values"

                $NewOwnerIds = Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Processes -DestinationList $DestinationVariableSetVariables.ScopeValues.Processes -IdList $octopusVariable.Scope.ProcessOwner -MatchingOption $CloneScriptOptions.VariableProcessOwnerScopingMatch -IdListName "$variableName Process Owners Scoping"
                
                if ($NewOwnerIds.CanProceed -eq $false)
                {
                    continue
                }

                $octopusVariable.Scope.ProcessOwner = @($NewOwnerIds.NewIdList) 
            }
            else 
            {
                $octopusVariable.Scope.PSObject.Properties.Remove('ProcessOwner')    
            }
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Action" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has deployment process step scoping, converting to destination values"

            $NewActionIds = Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Actions -DestinationList $DestinationVariableSetVariables.ScopeValues.Actions -IdList $octopusVariable.Scope.Action -MatchingOption $CloneScriptOptions.VariableActionScopingMatch -IdListName "$variableName Deployment Process Steps Scoping"

            if ($NewActionIds.CanProceed -eq $false)
            {
                continue
            }

            $octopusVariable.Scope.Action = @($NewActionIds.NewIdList)
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Machine" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has machine scoping, converting to destination values"            

            $NewMachineIds = Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Machines -DestinationList $DestinationVariableSetVariables.ScopeValues.Machines -IdList $octopusVariable.Scope.Machine -MatchingOption $CloneScriptOptions.VariableMachineScopingMatch -IdListName "$variableName Deployment Target Scoping"

            if ($NewMachineIds.CanProceed -eq $false)
            {
                continue
            }

            $octopusVariable.Scope.Machine = @($NewMachineIds.NewIdList)
        }

        if ($octopusVariable.Type -match ".*Account")
        {
            Write-OctopusVerbose "$variableName is an account value, converting to destination account"

            $newAccountId = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $octopusVariable.Value -ItemName "$($octopusVariable.Name) Account" -MatchingOption $cloneScriptOptions.VariableAccountScopingMatch

            if ($null -eq $newAccountId -and $CloneScriptOptions.VariableAccountScopingMatch.ToLower().Trim() -eq "skipunlessexactmatch")
            {
                continue
            }

            $octopusVariable.Value = $newAccountId
        }

        if ($octopusVariable.Type -eq "Certificate")
        {
            Write-OctopusVerbose "$variableName is an certificate value, converting to destination account"

            $newCertificateId = Convert-SourceIdToDestinationId -SourceList $sourceData.CertificateList -DestinationList $destinationData.CertificateList -IdValue $octopusVariable.Value -ItemName "$($octopusVariable.Name) Certificate" -MatchingOption $CloneScriptOptions.VariableCertificateScopingMatch

            if ($null -eq $newCertificateId -and $CloneScriptOptions.VariableCertificateScopingMatch.ToLower().Trim() -eq "skipunlessexactmatch")
            {
                continue
            }

            $octopusVariable.Value = $newCertificateId
        }

        if ($octopusVariable.IsSensitive -eq $true)
        {
            $octopusVariable.Value = "Dummy Value"
        }        
        
        $foundIndex = -1
        $variableMatchType = "NoMatch"     
        Write-OctopusVerbose "Checking if $variableName exists on destination"   
        for($i = 0; $i -lt $DestinationVariableSetVariables.Variables.Length; $i++)
        {            
            $localVariableMatchType = Compare-OctopusVariables -sourceVariable $octopusVariable -destinationVariable $DestinationVariableSetVariables.Variables[$i] -sourceData $sourceData -destinationData $destinationData
            if ($localVariableMatchType -ne "NoMatch")
            {
                $foundIndex = $i 
                $variableMatchType = $localVariableMatchType               
                break
            }
        }   
     
        if ($variableMatchType -eq "NoMatch")
        {
            Write-OctopusVerbose "New variable $variableName with unique scoping has been found.  Adding to list."
            
            if ($octopusVariable.Value -eq "Dummy Value")         
            {                
                Write-OctopusPostCloneCleanUp "The variable $variableName is a sensitive variable, value set to 'Dummy Value'"
            }
            
            if ($CloneScriptOptions.OverwriteExistingVariables.ToLower().Trim() -eq "addnewwithdefaultvalue")
            {
                Write-OctopusPostCloneCleanUp "The variable $variableName is a new variable and the OverwriteExistingVariables was set to AddNewWithDefaultValue, adding value set to 'REPLACE ME'"
                $octopusVariable.Value = "REPLACE ME"
            }

            Write-OctopusChangeLog "      - Add $variableName with value $($octopusVariable.Value)"
            Write-OctopusVariableScopeToChangeLog -octopusVariable $octopusVariable -destinationVariableSetVariables $destinationVariableSetVariables
            
            $octopusVariable.Id = $null

            $DestinationVariableSetVariables.Variables += $octopusVariable
        }
        elseif ($variableMatchType -eq "ScopeMatch" -and $CloneScriptOptions.OverwriteExistingVariables -ne $true)
        {
            Write-OctopusVerbose "The variable $variableName already exists on the destination with matching scope and you elected to only copy over new items, skipping this one."
            Write-OctopusChangeLog "      - $variableName already exists with the following scope, skipping"
            Write-OctopusVariableScopeToChangeLog -octopusVariable $octopusVariable -destinationVariableSetVariables $destinationVariableSetVariables
        }                                         
        elseif ($variableMatchType -eq "ScopeMatch" -and $DestinationVariableSetVariables.Variables[$foundIndex].IsSensitive -eq $true)
        {
            Write-OctopusVerbose "The variable $variableName with matching scoping is sensitive on the destination, leaving as is on the destination."
            Write-OctopusChangeLog "      - $variableName already exists with the following scope and is a sensitive variable, skipping"
            Write-OctopusVariableScopeToChangeLog -octopusVariable $octopusVariable -destinationVariableSetVariables $destinationVariableSetVariables
        }
        elseif ($variableMatchType -eq "ScopeMatch")
        {
            $DestinationVariableSetVariables.Variables[$foundIndex].Value = $octopusVariable.Value            

            Write-OctopusVerbose "The variable $variableName has a matching scope and you elected to update existing values.  Updating the value."
            Write-OctopusChangeLog "      - Update $variableName value with value $($octopusVariable.Value)"
            Write-OctopusVariableScopeToChangeLog -octopusVariable $octopusVariable -destinationVariableSetVariables $destinationVariableSetVariables

            if ($octopusVariable.Value -eq "Dummy Value")         
            {                
                Write-OctopusPostCloneCleanUp "The variable $variableName is a sensitive variable, value set to 'Dummy Value'"
            }
        }
        elseif ($variableMatchType -eq "ValueMatch")        
        {
            $DestinationVariableSetVariables.Variables[$foundIndex].Scope = $octopusVariable.Scope

            Write-OctopusVerbose "The variable $variableName has a matching value AND name.  Updating the scope to match."
            Write-OctopusChangeLog "      - Update $variableName scoping with value $($octopusVariable.Value)"
            Write-OctopusVariableScopeToChangeLog -octopusVariable $octopusVariable -destinationVariableSetVariables $destinationVariableSetVariables
        }
    }

    $variableSetValues = Save-OctopusVariableSetVariables -libraryVariableSetVariables $DestinationVariableSetVariables -destinationData $DestinationData        
}

function Compare-OctopusVariables
{
    param(
        $sourceVariable,
        $destinationVariable,
        $sourceData,
        $destinationData
    )

    if ($destinationVariable.Name.ToLower().Trim() -ne $sourceVariable.Name.ToLower().Trim())
    {
        Write-OctopusVerbose "      The source variable name $($sourceVariable.Name) does not equal the destination name $($destinationVariable.Name).  They do not match."
        return "NoMatch"
    }
    else
    {
        Write-OctopusVerbose "      The source variable name $($sourceVariable.Name) matches the destination $($destinationVariable.Name).  Moving on to checking if there is a difference in sensitivity."
    }

    if ($destinationVariable.IsSensitive -ne $sourceVariable.IsSensitive)
    {
        Write-OctopusVerbose "      The source variable IsSensitive is set to $($sourceVariable.IsSensitive) while the destination is set to $($destinationVariable.IsSensitive).  They do not match."
        return "NoMatch"
    }
    else
    {
        Write-OctopusVerbose "      The source variable name $($sourceVariable.Name) and the destination $($destinationVariable.Name) have the same sensitivity.  Moving on to checking scoping."
    }
    
    Write-OctopusVerbose "Comparing $($sourceVariable.Value) with $($destinationVariable.Value)"
    if ($destinationVariable.IsSensitive -eq $false -and $sourceVariable.IsSensitive -eq $false -and [string]::IsNullOrWhiteSpace($sourceVariable.Value) -eq $false -and [string]::IsNullOrWhiteSpace($destinationVariable.Value) -eq $false -and $sourceVariable.Value.ToLower().Trim() -eq $destinationVariable.Value.ToLower().Trim())
    {
        Write-OctopusVerbose "      The source variable and the destination variable have the same name AND the same value"
        return "ValueMatch"
    }

    $hasMatchingEnvironmentScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Environment"

    if ($hasMatchingEnvironmentScoping -eq $false)
    {
        return "NoMatch"
    }

    $hasMatchingChannelScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Channel"

    if ($hasMatchingChannelScoping -eq $false)
    {
        return "NoMatch"
    }

    $hasMatchingProcessOwnerScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "ProcessOwner"

    if ($hasMatchingProcessOwnerScoping -eq $false)
    {
        return "NoMatch"
    }

    $hasMatchingActionScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Action"

    if ($hasMatchingActionScoping -eq $false)
    {
        return "NoMatch"
    }

    $hasMatchingRoleScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Role"

    if ($hasMatchingRoleScoping -eq $false)
    {
        return "NoMatch"
    }

    $hasMatchingMachineScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Machine"

    if ($hasMatchingMachineScoping -eq $false)
    {
        return "NoMatch"
    }

    $hasMatchingMachineScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "TenantTag"

    if ($hasMatchingMachineScoping -eq $false)
    {
        return "NoMatch"
    }

    return "ScopeMatch"
}

function Compare-VariableScopingProperty
{
    param(
        $sourceVariable,
        $destinationVariable,
        $sourceData,
        $destinationData,
        $propertyName
    )

    $sourceHasPropertyScoping = $null -ne (Get-Member -InputObject $sourceVariable.Scope -Name $propertyName -MemberType Properties)
    $destinationHasPropertyScoping = $null -ne (Get-Member -InputObject $destinationVariable.Scope -Name $propertyName -MemberType Properties)

    if ($sourceHasPropertyScoping -ne $destinationHasPropertyScoping)
    {  
        Write-OctopusVerbose "          The source variable is scoped to $($propertyName)s $($sourceVariable.Scope.$propertyName) while the destination variable is scoped to the $($destinationVariable.Scope.$propertyName).  This means one has scoping while the other does not."

        return $false
    }
    
    if ($sourceHasPropertyScoping -and $destinationHasPropertyScoping)
    {
        Write-OctopusVerbose "          The source variable and destination variable are both scoped to $($propertyName)s, comparing the two scoping"

        if ($sourceVariable.Scope.$propertyName.Length -ne $destinationVariable.Scope.$propertyName.Length)
        {
            Write-OctopusVerbose "          The source variable and destination variable do not have the same $propertyName scoping length, they do not match"

            return $false
        }

        foreach ($sourceValue in $sourceVariable.Scope.$propertyName)
        {
            $matchingDestinationValue = $destinationVariable.Scope.$propertyName | Where-Object {$_ -eq $sourceValue}

            if ($null -eq $matchingDestinationValue)
            {
                Write-OctopusVerbose "          The $propertyName id $sourceValue cannot be found in the destination variable scope and they have already been converted over, so there should be a match, there is no way they match."
                return $false
            }
            else
            {
                Write-OctopusVerbose "          The $propertyName id $sourceValue was found in the destination variable scope.  Moving onto the next scope."    
            }
        }

        Write-OctopusVerbose "          The source variable and destination variable $propertyName scoping matches."
    }
    else 
    {
        Write-OctopusVerbose "          The source variable and destination variable are both not scoped to $($propertyName)s.  Therefore the scope matches."
    }

    return $true
}

function Write-OctopusVariableScopeToChangeLog
{
    param (
        $octopusVariable,
        $destinationVariableSetVariables
    )

    if ($null -ne $octopusVariable.Scope.Environment -and $octopusVariable.Scope.Environment.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.Environment -listType "Environment" -destinationList $destinationVariableSetVariables.ScopeValues.Environments -prefixSpaces "       "
    }
    
    if ($null -ne $octopusVariable.Scope.ProcessOwner -and $octopusVariable.Scope.ProcessOwner.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.ProcessorOwner -listType "Process Owner" -destinationList $destinationVariableSetVariables.ScopeValues.Processes -prefixSpaces "       "
    }

    if ($null -ne $octopusVariable.Scope.Channel -and $octopusVariable.Scope.Channel.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.Channel -listType "Environment" -destinationList $destinationVariableSetVariables.ScopeValues.Channels -prefixSpaces "       "
    }

    if ($null -ne $octopusVariable.Scope.Action -and $octopusVariable.Scope.Action.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.Action -listType "Action" -destinationList $destinationVariableSetVariables.ScopeValues.Actions -prefixSpaces "       "
    }

    if ($null -ne $octopusVariable.Scope.Role -and $octopusVariable.Scope.Role.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.Role -listType "Role" -destinationList $destinationVariableSetVariables.ScopeValues.Roles -prefixSpaces "       "
    }

    if ($null -ne $octopusVariable.Scope.Machine -and $octopusVariable.Scope.Machine.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.Machine -listType "Machine" -destinationList $destinationVariableSetVariables.ScopeValues.Machines -prefixSpaces "       "
    }

    if ($null -ne $octopusVariable.Scope.TenantTag -and $octopusVariable.Scope.TenantTag.Length -gt 0)
    {
        Write-OctopusChangeLogListDetails -idList $octopusVariable.Scope.TenantTag -listType "Tenant Tag" -destinationList $destinationVariableSetVariables.ScopeValues.TenantTags -skipConvertingToName $true -prefixSpaces "       "
    }
}