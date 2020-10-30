function Copy-OctopusVariableSetValues
{
    param
    (
        $SourceVariableSetVariables,
        $DestinationVariableSetVariables,        
        $SourceData,
        $DestinationData,
        $SourceProjectData,
        $DestinationProjectData,
        $CloneScriptOptions
    )
    
    $variableTracker = @{}  
    
    foreach ($octopusVariable in $sourceVariableSetVariables.Variables)
    {                             
        $variableName = $octopusVariable.Name        
        
        if (Get-Member -InputObject $octopusVariable.Scope -Name "Environment" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has environment scoping, converting to destination values"
            $NewEnvironmentIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourcedata.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $octopusVariable.Scope.Environment)
            $octopusVariable.Scope.Environment = @($NewEnvironmentIds)            
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "Channel" -MemberType Properties)
        {
            Write-OctopusVerbose "$variableName has channel scoping, converting to destination values"
            $NewChannelIds = @(Convert-SourceIdListToDestinationIdList -SourceList $sourceProjectData.ChannelList -DestinationList $DestinationProjectData.ChannelList -IdList $octopusVariable.Scope.Channel)
            $octopusVariable.Scope.Channel = @($NewChannelIds)            
        }

        if (Get-Member -InputObject $octopusVariable.Scope -Name "ProcessOwner" -MemberType Properties)
        {
            if ($destinationData.HasRunbooks)
            {
                Write-OctopusVerbose "$variableName has process owner scoping, converting to destination values"
                $NewOwnerIds = @()
                foreach($value in $octopusVariable.Scope.ProcessOwner)
                {
                    Write-OctopusVerbose "Attempting to convert $value to a destination value"

                    if ($value -like "Projects-*")
                    {
                        Write-OctopusVerbose "The process owner is the project, converting to the new project id"
                        $NewOwnerIds += $DestinationProjectData.Project.Id
                    }
                    elseif($value -like "Runbooks-*")
                    {
                        Write-OctopusVerbose "The process owner is a runbook, converting to the new runbook id"
                        $NewOwnerIds += Convert-SourceIdToDestinationId -SourceList $SourceProjectData.RunbookList -DestinationList $DestinationProjectData.RunbookList -IdValue $value
                    }
                }

                Write-OctopusVerbose "The new process owner ids are $NewOwnerIds"
                
                $octopusVariable.Scope.ProcessOwner = @($NewOwnerIds)            
            }
            else 
            {
                $octopusVariable.Scope.PSObject.Properties.Remove('ProcessOwner')    
            }
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

        $trackingName = $variableName -replace "\.", ""
        
        $variableExistsOnDestination = $false        
        for($i = 0; $i -lt $DestinationVariableSetVariables.Variables.Length; $i++)
        {            
            if ($DestinationVariableSetVariables.Variables[$i].Name -eq $variableName)
            {
                $variableExistsOnDestination = $true
                $foundCounter += 1
                if ($foundCounter -eq $variableTracker[$trackingName])
                {
                    $foundIndex = $i
                }
            }
        }   
        
        Write-OctopusVerbose "Cloning $variableName"
        if ($null -eq $variableTracker[$trackingName])
        {
            Write-OctopusVerbose "This is the first time we've seen $variableName"
            $variableTracker[$trackingName] = 1
        }
        else
        {
            $variableTracker.$trackingName += 1
            Write-OctopusVerbose "We've now seen $variableName $($variableTracker[$trackingName]) times"
        }

        $foundCounter = 0
        $foundIndex = -1
        $variableExistsOnDestination = $false        
        for($i = 0; $i -lt $DestinationVariableSetVariables.Variables.Length; $i++)
        {            
            if ($DestinationVariableSetVariables.Variables[$i].Name -eq $variableName)
            {
                Write-OctopusVerbose "Found the variable $variableName in the destination, checking to see if the scope matches"

                Compare-VariableScoping -sourceVariable $octopusVariable -destinationVariable $DestinationVariableSetVariables.Variables[$i] -sourceData $sourceData -destinationData $destinationData

                $variableExistsOnDestination = $true
                $foundCounter += 1
                if ($foundCounter -eq $variableTracker[$trackingName])
                {
                    $foundIndex = $i
                }
            }
        }        
        
        if ($foundCounter -gt 1 -and $variableExistsOnDestination -eq $true -and $CloneScriptOptions.AddAdditionalVariableValuesOnExistingVariableSets -eq $false)
        {
            Write-OctopusVerbose "The variable $variableName already exists on destination. You selected to skip duplicate instances, skipping."
        }       
        elseif ($foundIndex -eq -1)
        {
            Write-OctopusVerbose "New variable $variableName value found.  This variable has appeared so far $($variableTracker[$trackingName]) time(s) in the source variable set.  Adding to list."
            $DestinationVariableSetVariables.Variables += $octopusVariable
        }
        elseif ($CloneScriptOptions.OverwriteExistingVariables -eq $false)
        {
            Write-OctopusVerbose "The variable $variableName already exists on the host and you elected to only copy over new items, skipping this one."
        }                                         
        elseif ($foundIndex -gt -1 -and $DestinationVariableSetVariables.Variables[$foundIndex].IsSensitive -eq $true)
        {
            Write-OctopusVerbose "The variable $variableName at value index $($variableTracker[$trackingName]) is sensitive, leaving as is on the destination."
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

function Compare-VariableScoping
{
    param(
        $sourceVariable,
        $destinationVariable,
        $sourceData,
        $destinationData
    )

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
        Write-OctopusVerbose "The source variable is scoped to $($propertyName)s $($sourceVariable.Scope.$propertyName) while the destination variable is scoped to the $($destinationVariable.Scope.Environment), the two do not match"

        return $false
    }
    
    if ($sourceHasPropertyScoping -and $destinationHasPropertyScoping)
    {
        Write-OctopusVerbose "The source variable and destination variable are both scoped to $($propertyName)s, comparing the two scoping"

        if ($sourceVariable.Scope.$propertyName.Length -ne $destinationVariable.Scope.$propertyName.Length)
        {
            Write-OctopusVerbose "The source variable and destination variable do not have the same $propertyName scoping length, they do not match"

            return $false
        }

        foreach ($sourceEnvironmentId in $sourceVariable.Scope.$propertyName)
        {
            $matchingDestinationEnvironment = $destinationVariable.Scope.$propertyName | Where-Object {$_ -eq $sourceEnvironmentId}

            if ($null -eq $matchingDestinationEnvironment)
            {
                Write-OctopusVerbose "The $propertyName id $destinationEnvironmentId cannot be found in the destination variable scope and they have already been converted over, so there should be a match, there is no way they match."
                return $false
            }
        }

        Write-OctopusVerbose "The source variable and destination variable $propertyName scoping matches"
    }
    else 
    {
        Write-OctopusVerbose "The source variable and destination variable are both not scoped to $($propertyName)s, moving on"
    }

    return $true
}