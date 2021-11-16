function Test-OctopusScopeMatchParameter
{
    param (
        $parameterValue,
        $parameterName,
        $defaultValue,
        $singleValueItem
    )
    
    if ([string]::IsNullOrWhiteSpace($parameterValue))
    {
        return $defaultValue
    }

    $lowerParameterValue = $parameterValue.ToLower().Trim()


    if ($singleValueItem)
    {
        if ($lowerParameterValue -ne "errorunlessexactmatch" -and $lowerParameterValue -ne "skipunlessexactmatch" -and $lowerParameterValue -ne "ignoremismatch")
        {
            Write-OctopusCritical "The parameter $parameterName is set to $parameterValue.  Acceptable values are ErrorUnlessExactMatch, SkipUnlessExactMatch, or IgnoreMismatch."
            exit 1
        }  
    }
    else
    {
        if ($lowerParameterValue -ne "errorunlessexactmatch" -and $lowerParameterValue -ne "skipunlessexactmatch" -and $lowerParameterValue -ne "errorunlesspartialmatch" -and $lowerParameterValue -ne "skipunlesspartialmatch" -and $lowerParameterValue -ne "ignoremismatch" -and $lowerParameterValue -ne "ignoremismatchonnewleaveexistingalone")
        {
            Write-OctopusCritical "The parameter $parameterName is set to $parameterValue.  Acceptable values are ErrorUnlessExactMatch, SkipUnlessExactMatch, ErrorUnlessPartialMatch, SkipUnlessPartialMatch, IgnoreMismatch, or IgnoreMismatchOnNewLeaveExistingAlone."
            exit 1
        }  
    }      

    return $parameterValue
}

function Test-OctopusTrueFalseParameter
{
    param (
        $parameterValue,
        $parameterName,
        $defaultValue
    )

    if ([string]::IsNullOrWhiteSpace($parameterValue))
    {
        Write-OctopusVerbose "The parameter $parameterName sent in was null or empty, setting to $defaultValue."
        return $defaultValue
    }

    if ($parameterValue -ne $true -and $parameterValue -ne $false)
    {
        Write-OctopusCritical "The value for $parameterName was $parameterValue.  It must be $true or $false. Exiting."
        exit 1
    }

    Write-OctopusVerbose "The value sent in for $parameterName is $parameterValue."
    return $parameterValue
}

function Test-OctopusProcessCloningParameter
{
    param (
        $parameterValue        
    )

    if ([string]::IsNullOrWhiteSpace($parameterValue))
    {
        Write-OctopusVerbose "The parameter ProcessCloningOption was empty or null, setting to KeepAdditionalDestinationSteps."
        return "KeepAdditionalDestinationSteps"
    }
    
    if ($parameterValue.ToLower().Trim() -ne "keepadditionaldestinationsteps" -and $parameterValue.ToLower().Trim() -ne "sourceonly")
    {
        Write-OctopusCritical "The parameter ProcessCloningOption is set to $parameterValue.  Acceptable values are KeepAdditionalDestinationSteps or SourceOnly."
        exit 1
    }

    Write-OctopusVerbose "The value sent in for ProcessCloningOption is $parameterValue."
    return $parameterValue
}

function Test-OctopusOverwriteExistingLifecyclesPhasesParameter
{
    param (
        $parameterValue
    )

    if ([string]::IsNullOrWhiteSpace($parameterValue))
    {
        Write-OctopusVerbose "The parameter OverwriteExistingLifecyclesPhases was empty or null, setting to $false."
        return $false
    }

    if ($parameterValue -ne $true -and $parameterValue -ne $false -and $parameterValue.ToLower().Trim() -ne "neverclonelifecyclephases")
    {
        Write-OctopusCritical "The parameter OverwriteExistingLifecyclesPhases is set to $parameterValue.  Acceptable values are $true, $false or NeverCloneLifecyclePhases"
        exit 1
    }

    Write-OctopusVerbose "The value sent in for OverwriteExistingLifecyclesPhases is $parameterValue."
    return $parameterValue
}

function Test-OctopusOverwriteExistingVariablesParameter
{
    param (
        $parameterValue
    )

    if ([string]::IsNullOrWhiteSpace($parameterValue))
    {
        Write-OctopusVerbose "The parameter OverwriteExistingVariables was empty or null, setting to $false."
        return $false
    }

    if ($parameterValue -ne $true -and $parameterValue -ne $false -and $parameterValue.ToLower().Trim() -ne "addnewwithdefaultvalue")
    {
        Write-OctopusCritical "The parameter OverwriteExistingVariables is set to $parameterValue.  Acceptable values are $true, $false or AddNewWithDefaultValue"
        exit 1
    }

    Write-OctopusVerbose "The value sent in for OverwriteExistingVariables is $parameterValue."

    return $parameterValue
}

function Test-OctopusNewListParameter
{
    param (
        $parameterValue,
        $parameterName
    )

    if ([string]::IsNullOrWhiteSpace($parameterValue))
    {
        Write-OctopusWarning "The paramter $parameterName is empty or null but this is a paramter you previously didn't have to set.  Setting to 'all' so it doesn't break your existing clone."
        return "all"
    }

    Write-Verbose "The value sent in for $parameterName was $parameterValue"

    return $parameterValue
}

function Test-OctopusIncludeExcludeFilterParameter
{
    param (
        $includeFilters,
        $excludeFilters,
        $parameterName,
        $defaultIncludeValue
    )

    if ([string]::IsNullOrWhiteSpace($includeFilters) -eq $false -and [string]::IsNullOrWhiteSpace($excludeFilters) -eq $false)
    {
        Write-OctopusCritical "Both include and exclude filters were set for $parameterName.  That is not allowed, either pick an exclude filter or an include filter.  Exiting."
        exit 1
    }  
    
    if ([string]::IsNullOrWhiteSpace($includeFilters) -and [string]::IsNullOrWhiteSpace($excludeFilters))
    {
        Write-OctopusVerbose "Both include and exclude filters were empty for $parameterName.  Setting the include filter to $defaultIncludeFilter."
        return $defaultIncludeValue
    }

    Write-OctopusVerbose "The values for $parameterName are include filters: $includeFilters and exclude filters: $excludeFilters"
    return $includeFilters
}