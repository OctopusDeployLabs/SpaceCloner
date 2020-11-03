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
    
    foreach ($octopusVariable in $sourceVariableSetVariables.Variables)
    {                             
        $variableName = $octopusVariable.Name        
        
        if (Get-Member -InputObject $octopusVariable.Scope -Name "Environment" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has environment scoping, converting to destination values"
            $NewEnvironmentIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Environments -DestinationList $DestinationVariableSetVariables.ScopeValues.Environments -IdList $octopusVariable.Scope.Environment)
            $octopusVariable.Scope.Environment = @($NewEnvironmentIds)            
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Channel" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has channel scoping, converting to destination values"
            $NewChannelIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Channels -DestinationList $DestinationVariableSetVariables.ScopeValues.Channels -IdList $octopusVariable.Scope.Channel)
            $octopusVariable.Scope.Channel = @($NewChannelIds)            
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "ProcessOwner" -MemberType Properties)
        {
            if ($destinationData.HasRunbooks)
            {
                Write-OctopusVerbose "$variableName has process owner scoping, converting to destination values"
                $NewOwnerIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Processes -DestinationList $DestinationVariableSetVariables.ScopeValues.Processes -IdList $octopusVariable.Scope.ProcessOwner)               
                $octopusVariable.Scope.ProcessOwner = @($NewOwnerIds)            
            }
            else 
            {
                $octopusVariable.Scope.PSObject.Properties.Remove('ProcessOwner')    
            }
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Action" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has deployment process step scoping, converting to destination values"
            $NewActionIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Actions -DestinationList $DestinationVariableSetVariables.ScopeValues.Actions -IdList $octopusVariable.Scope.Action)
            $octopusVariable.Scope.Action = @($NewActionIds)
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Machine" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has machine scoping, converting to destination values"
            $NewMachineIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceVariableSetVariables.ScopeValues.Machines -DestinationList $DestinationVariableSetVariables.ScopeValues.Machines -IdList $octopusVariable.Scope.Machine)
            $octopusVariable.Scope.Machine = @($NewMachineIds)
        }

        if ($octopusVariable.Type -match ".*Account")
        {
            Write-OctopusVerbose "$variableName is an account value, converting to destination account"
            $octopusVariable.Value = Convert-SourceIdToDestinationId -SourceList $sourceData.InfrastructureAccounts -DestinationList $destinationData.InfrastructureAccounts -IdValue $octopusVariable.Value
        }

        if ($octopusVariable.Type -eq "Certificate")
        {
            Write-OctopusVerbose "$variableName is an certificate value, converting to destination account"
            $octopusVariable.Value = Convert-SourceIdToDestinationId -SourceList $sourceData.CertificateList -DestinationList $destinationData.CertificateList -IdValue $octopusVariable.Value
        }

        if ($octopusVariable.IsSensitive -eq $true)
        {
            $octopusVariable.Value = "Dummy Value"
        }        
        
        $foundIndex = -1     
        Write-OctopusVerbose "Checking if $variableName exists on destination"   
        for($i = 0; $i -lt $DestinationVariableSetVariables.Variables.Length; $i++)
        {            
            if ((Compare-OctopusVariables -sourceVariable $octopusVariable -destinationVariable $DestinationVariableSetVariables.Variables[$i] -sourceData $sourceData -destinationData $destinationData))
            {
                $foundIndex = $i                
                break
            }
        }   
     
        if ($foundIndex -eq -1)
        {
            Write-OctopusVerbose "New variable $variableName with unique scoping has been found.  Adding to list."
            $DestinationVariableSetVariables.Variables += $octopusVariable
        }
        elseif ($CloneScriptOptions.OverwriteExistingVariables -eq $false)
        {
            Write-OctopusVerbose "The variable $variableName already exists on the host and you elected to only copy over new items, skipping this one."
        }                                         
        elseif ($foundIndex -gt -1 -and $DestinationVariableSetVariables.Variables[$foundIndex].IsSensitive -eq $true)
        {
            Write-OctopusVerbose "The variable $variableName with matching scoping is sensitive on he destination, leaving as is on the destination."
        }
        elseif ($foundIndex -gt -1)
        {
            $DestinationVariableSetVariables.Variables[$foundIndex].Value = $octopusVariable.Value
            $DestinationVariableSetVariables.Variables[$foundIndex].Scope = $octopusVariable.Scope

            if ($octopusVariable.Value -eq "Dummy Value")         
            {                
                Write-OctopusPostCloneCleanUp "The variable $variableName is a sensitive variable, value set to 'Dummy Value'"
            }
        }        
    }

    Save-OctopusVariableSetVariables -libraryVariableSetVariables $DestinationVariableSetVariables -destinationData $DestinationData    
}

function Compare-OctopusVariables
{
    param(
        $sourceVariable,
        $destinationVariable,
        $sourceData,
        $destinationData
    )

    if ($destinationVariable.Name -ne $sourceVariable.Name)
    {
        Write-OctopusVerbose "      The source variable name $($sourceVariable.Name) does not equal the destination name $($destinationVariable.Name).  They do not match, skipping."
        return $false
    }
    else
    {
        Write-OctopusVerbose "      The source variable name $($sourceVariable.Name) matches the destination $($destinationVariable.Name).  Moving on to checking if there is a difference in sensitivity."
    }

    if ($destinationVariable.IsSensitive -ne $sourceVariable.IsSensitive)
    {
        Write-OctopusVerbose "      The source variable IsSensitive is set to $($sourceVariable.IsSensitive) while the destination is set to $($destinationVariable.IsSensitive).  They do not match.  Skipping."
        return $false
    }
    else
    {
        Write-OctopusVerbose "      The source variable name $($sourceVariable.Name) and the destination $($destinationVariable.Name) have the same sensitivity.  Moving on to checking scoping."
    }

    $hasMatchingEnvironmentScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Environment"

    if ($hasMatchingEnvironmentScoping -eq $false)
    {
        return $false
    }

    $hasMatchingChannelScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Channel"

    if ($hasMatchingChannelScoping -eq $false)
    {
        return $false
    }

    $hasMatchingProcessOwnerScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "ProcessOwner"

    if ($hasMatchingProcessOwnerScoping -eq $false)
    {
        return $false
    }

    $hasMatchingActionScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Action"

    if ($hasMatchingActionScoping -eq $false)
    {
        return $false
    }

    $hasMatchingRoleScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Role"

    if ($hasMatchingRoleScoping -eq $false)
    {
        return $false
    }

    $hasMatchingMachineScoping = Compare-VariableScopingProperty -sourceVariable $sourceVariable -destinationVariable $destinationVariable -sourceData $sourceData -destinationData $destinationData -propertyName "Machine"

    if ($hasMatchingMachineScoping -eq $false)
    {
        return $false
    }

    return $true
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
        Write-OctopusVerbose "      The source variable is scoped to $($propertyName)s $($sourceVariable.Scope.$propertyName) while the destination variable is scoped to the $($destinationVariable.Scope.$propertyName).  This means one has scoping while the other does not."

        return $false
    }
    
    if ($sourceHasPropertyScoping -and $destinationHasPropertyScoping)
    {
        Write-OctopusVerbose "      The source variable and destination variable are both scoped to $($propertyName)s, comparing the two scoping"

        if ($sourceVariable.Scope.$propertyName.Length -ne $destinationVariable.Scope.$propertyName.Length)
        {
            Write-OctopusVerbose "      The source variable and destination variable do not have the same $propertyName scoping length, they do not match"

            return $false
        }

        foreach ($sourceValue in $sourceVariable.Scope.$propertyName)
        {
            $matchingDestinationValue = $destinationVariable.Scope.$propertyName | Where-Object {$_ -eq $sourceValue}

            if ($null -eq $matchingDestinationValue)
            {
                Write-OctopusVerbose "      The $propertyName id $destinationEnvironmentId cannot be found in the destination variable scope and they have already been converted over, so there should be a match, there is no way they match."
                return $false
            }
        }

        Write-OctopusVerbose "      The source variable and destination variable $propertyName scoping matches"
    }
    else 
    {
        Write-OctopusVerbose "      The source variable and destination variable are both not scoped to $($propertyName)s, moving on"
    }

    return $true
}