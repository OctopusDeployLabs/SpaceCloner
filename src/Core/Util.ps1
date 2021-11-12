function Get-OctopusItemByName
{
    param (
        $ItemList,
        $ItemName
        )    

    if ($null -ne $itemName)
    {
        $loweredItem = $ItemName.ToLower().Trim()
    }
    
    Write-OctopusVerbose "Looping through $($itemList.Count) items to find $loweredItem"
    foreach ($item in $itemList)
    {
        if ($null -eq $item)
        {
            Write-OctopusVerbose "      The item to compare is $null moving on to next item in list."
            continue
        }

        if ($null -eq $item.Name -and $null -eq $itemName)
        {
            Write-OctopusVerbose "      The item name is null and the item to find is null; returning item."
            return $item
        }
        
        if ($null -eq $item.Name)
        {
            Write-OctopusVerbose "      The item name is null moving on to next item in list."
            continue
        }

        Write-OctopusVerbose "      Comparing $($item.Name.ToLower().Trim()) with $loweredItem"
        if ($item.Name.ToLower().Trim() -eq $loweredItem)
        {
            Write-OctopusVerbose "      Match found on name, returning item."
            return $item
        }
    }

    return $null
}

function Get-OctopusItemById
{
    param (
        $ItemList,
        $ItemId
        ) 
        
    Write-OctopusVerbose "Attempting to find $ItemId in the item list of $($ItemList.Length) item(s)"

    foreach($item in $ItemList)
    {
        Write-OctopusVerbose "Checking to see if $($item.Id) matches with $ItemId"
        if ($item.Id -eq $ItemId)
        {
            Write-OctopusVerbose "The Ids match, return the item $($item.Name)"
            return $item
        }
    }

    Write-OctopusVerbose "No match found returning null"
    return $null    
}

function Convert-OctopusIdListToNameList
{
    param (
        $idList,
        $itemList
    )

    $NewNameList = @()
    foreach ($id in $idList)
    {
        $matchingItem = Get-OctopusitemById -ItemList $itemList -ItemId $id
        if ($null -ne $matchingItem)
        {
            $NewNameList += $matchingItem.Name
        }
    }

    return $NewNameList
}

function Get-OctopusItemByPackageId
{
    param (
        $ItemList,
        $ItemPackageId
        ) 
        
    Write-OctopusVerbose "Attempting to find $ItemPackageId in the item list of $($ItemList.Length) item(s)"

    foreach($item in $ItemList)
    {
        Write-OctopusVerbose "Checking to see if $($item.PackageId) matches with $ItemPackageId"
        if ($item.PackageId -eq $ItemPackageId)
        {
            Write-OctopusVerbose "The Ids match, return the item $($item.PackageId)"
            return $item
        }
    }

    Write-OctopusVerbose "No match found returning null"
    return $null    
}

function Convert-SourceIdToDestinationId
{
    param(
        $SourceList,
        $DestinationList,
        $IdValue,
        $ItemName,
        $MatchingOption
    )

    $idValueSplit = $IdValue -split "-"
    if ($idValueSplit.Length -le 2 -and $IdValue.Tolower().Trim() -ne "feeds-builtin" -and $IdValue.Tolower().Trim() -ne "feeds-builtin-releases")
    {
        if (($idValueSplit[1] -match "^[\d\.]+$") -eq $false)
        {
            Write-OctopusVerbose "The id value $idValue is a built in id, no need to convert, returning it."
            return $IdValue
        }
    }
    
    Write-OctopusVerbose "Getting Name of $IdValue for $itemName."
    $sourceItem = Get-OctopusItemById -ItemList $SourceList -ItemId $IdValue

    $nameToUse = $sourceItem.Name
    if ([string]::IsNullOrWhiteSpace($nameToUse))
    {
        Write-OctopusVerbose "The name property is null attempting the username property"
        $nameToUse = $sourceItem.UserName
    }

    if ([string]::IsNullOrWhiteSpace($nameToUse))
    {
        if ($MatchingOption.ToLower().Trim() -eq "errorunlessexactmatch")
        {
            Write-OctopusCritical "Unable to find a name property for $IdValue in the source list for $itemName.  Stopping to prevent bad data.  If this is a what-if run then you need to adjust your parameters because it will result in missing data."
            exit 1             
        }

        Write-OctopusVerbose "Unable to find a name property for $IdValue for $itemName.  The matching option was set to $MatchingOption, will continue to process.  To stop on mismatch change the option to start with Error."
        return $null
    }

    Write-OctopusVerbose "The name of $IdValue is $nameToUse, attempting to find in destination list"    

    $destinationItem = Get-OctopusItemByName -ItemName $nameToUse -ItemList $DestinationList    

    if ($null -eq $destinationItem)
    {
        if ($MatchingOption.ToLower().Trim() -eq "errorunlessexactmatch")
        {        
            Write-OctopusCritical "Unable to find $nameToUse in the destination list for $itemName.  Stopping to prevent bad data.  If this is a what-if run then you need to adjust your parameters because it will result in missing data."
            exit 1        
        }

        Write-OctopusWarning "Unable to find $nameToUse in the destination for $itemName.  The matching option was set to $MatchingOption, will continue to process.  To stop on mismatch change the option to start with Error."
        return $null
    }
    else
    {
        Write-OctopusVerbose "The destination id for $nameToUse is $($destinationItem.Id)"
        return $destinationItem.Id
    }
}

function Convert-SourceIdListToDestinationIdList
{
    param(
        $SourceList,
        $DestinationList,
        $IdList,
        $MatchingOption,
        $IdListName
    )

    $returnObject = @{
        NewIdList = @()
        CanProceed = $true
    }
    
    $originalCount = $IdList.Count

    if ($originalCount -eq 0)    
    {
        Write-OctopusVerbose "Ignoring the matching test because the id list $IdListName has no items to match to. Can Proceed is true."
        return $returnObject
    }

    Write-OctopusVerbose "Converting id list $IdListName with $originalCount item(s) over to destination space"     
    foreach ($idValue in $idList)
    {
        $ConvertedId = Convert-SourceIdToDestinationId -SourceList $SourceList -DestinationList $DestinationList -IdValue $IdValue -ItemName $IdListName -matchingOption $MatchingOption

        if ($null -ne $ConvertedId)
        {
            $returnObject.NewIdList += $ConvertedId
        }
    }    

    if ($MatchingOption.ToLower().Trim() -eq "ignoremismatch")
    {
        Write-OctopusVerbose "Ignoring the matching test for $IdListName because the Matching Option was set to IgnoreMismatch. Can Proceed is true."
        return $returnObject
    }
    
    $matchedCount = $returnObject.NewIdList.Count
    if ($matchedCount -eq $originalCount)
    {
        Write-OctopusVerbose "Exact match was found for $IdListName.  Can Proceed is true."
        return $returnObject
    }

    if ($MatchingOption.ToLower().Trim() -eq "skipunlessexactmatch" -and $originalCount -ne $matchedCount)
    {
        Write-OctopusVerbose "The matching option was set to SkipUnlessExactMatch.  The source $IdListName had $originalCount item(s) and the destination had $matchedCount item(s).  Can proceed is set to false to skip the item."
        $returnObject.CanProceed = $false
        return $returnObject
    }

    if ($originalCount -ge 1 -and $matchedCount -ge 1)
    {
        Write-OctopusVerbose "There was a partial match. The source $IdListName had $originalCount item(s) and the destination had $matchedCount item(s).  Can Proceed is true."
        return $returnObject
    }

    if ($MatchingOption.ToLower().Trim() -eq "errorunlesspartialmatch")
    {
        Write-OctopusCritical "A partial match was not found for $IdListName and the Matching Option is set to ErrorUnlessPartialMatch.  The source item had $originalCount item(s) and the destination had $matchedCount item(s).  Exiting.  If this is a what-if run then you need to adjust your parameters because it will result in missing data."
        Exit 1
    }

    Write-OctopusVerbose "A partial match was not found for $IdListName and matching option is SkipUnlessPartialMatch.  The source item had $originalCount item(s) and the destination had $matchedCount item(s).  Can proceed is set to false to skip this item."
    $returnObject.CanProceed = $false

    return $returnObject
}

function Test-OctopusObjectHasProperty
{
    param(
        $objectToTest,
        $propertyName
    )

    $hasProperty = Get-Member -InputObject $objectToTest -Name $propertyName -MemberType Properties

    if ($hasProperty)
    {
        Write-OctopusVerbose "$propertyName property found."
        return $true
    }
    else
    {
        Write-OctopusVerbose "$propertyName property missing."
        return $false
    }    
}

function Add-PropertyIfMissing
{
    param(
        $objectToTest,
        $propertyName,
        $propertyValue,
        $overwriteIfExists)
    
    if ((Test-OctopusObjectHasProperty -objectToTest $objectToTest -propertyName $propertyName) -eq $false)
    {            
        $objectToTest | Add-Member -MemberType NoteProperty -Name $propertyName -Value $propertyValue

        return $true
    }
    elseif ($null -ne $overwriteIfExists -and $overwriteIfExists -eq $true -and ((Test-OctopusObjectHasProperty -objectToTest $objectToTest -propertyName $propertyName) -eq $false))
    {
        $objectToTest.$propertyName = $propertyValue

        return $false
    }

    return $null
}

function Copy-OctopusObject
{
    param(
        $ItemToCopy,        
        $ClearIdValue,
        $SpaceId
    )

    $copyOfItem = $ItemToCopy | ConvertTo-Json -Depth 10
    $copyOfItem = $copyOfItem | ConvertFrom-Json

    if ($ClearIdValue)
    {
        $copyOfItem.Id = $null
    }

    if($null -ne $SpaceId -and (Test-OctopusObjectHasProperty -objectToTest $copyOfItem -propertyName "SpaceId"))
    {
        $copyOfItem.SpaceId = $SpaceId
    }

    return $copyOfItem
}

function Get-OctopusFilteredList
{
    param(
        $itemList,
        $itemType,
        $filters
    )

    $filteredList = New-OctopusFilteredList -itemList $itemList -itemType $itemType -filters $filters  
        
    if ($filteredList.Length -eq 0)
    {
        Write-OctopusWarning "No $itemType items were found to clone, skipping"
    }
    else
    {
        Write-OctopusSuccess "$itemType items were found to clone, starting clone for $itemType"
    }

    return $filteredList
}

function Get-OctopusFilteredListByPackageId
{
    param(
        $itemList,
        $itemType,
        $filters
    )

    $filteredList = New-OctopusPackageIdFilteredList -itemList $itemList -itemType $itemType -filters $filters  
        
    if ($filteredList.Length -eq 0)
    {
        Write-OctopusWarning "No $itemType items were found to clone, skipping"
    }
    else
    {
        Write-OctopusSuccess "$itemType items were found to clone, starting clone for $itemType"
    }

    return $filteredList
}

function Get-OctopusExclusionList
{
    param(
        $itemList,
        $itemType,
        $filters
    )

    $filteredList = New-OctopusFilteredList -itemList $itemList -itemType $itemType -filters $filters  
        
    if ($filteredList.Length -eq 0)
    {
        Write-OctopusWarning "No $itemType items were found to exclude"
    }    

    return $filteredList
}

function New-OctopusFilteredList
{
    param(
        $itemList,
        $itemType,
        $filters
    )

    $filteredList = @()  
    
    Write-OctopusSuccess "Creating filter list for $itemType with a filter of $filters"

    if ([string]::IsNullOrWhiteSpace($filters) -eq $false -and $null -ne $itemList)
    {
        $splitFilters = $filters -split ","

        foreach($item in $itemList)
        {
            foreach ($filter in $splitFilters)
            {
                Write-OctopusVerbose "Checking to see if $filter matches $($item.Name)"
                if ([string]::IsNullOrWhiteSpace($filter))
                {
                    continue
                }
                if (($filter).ToLower().Trim() -eq "all")
                {
                    Write-OctopusVerbose "The filter is 'all' -> adding $($item.Name) to $itemType filtered list"
                    $filteredList += $item
                }
                elseif ($item.Name -like $filter)
                {
                    Write-OctopusVerbose "The filter $filter matches $($item.Name), adding $($item.Name) to $itemType filtered list"
                    $filteredList += $item
                }
                else
                {
                    Write-OctopusVerbose "The item $($item.Name) does not match filter $filter"
                }
            }
        }
    }
    else
    {
        Write-OctopusWarning "The filter for $itemType was not set."
    }

    return $filteredList
}

function New-OctopusPackageIdFilteredList
{
    param(
        $itemList,
        $itemType,
        $filters
    )

    $filteredList = @()  
    
    Write-OctopusSuccess "Creating filter list for $itemType with a filter of $filters"

    if ([string]::IsNullOrWhiteSpace($filters) -eq $false -and $null -ne $itemList)
    {
        $splitFilters = $filters -split ","

        foreach($item in $itemList)
        {
            foreach ($filter in $splitFilters)
            {
                Write-OctopusVerbose "Checking to see if $filter matches $($item.PackageId)"
                if ([string]::IsNullOrWhiteSpace($filter))
                {
                    continue
                }
                if (($filter).ToLower() -eq "all")
                {
                    Write-OctopusVerbose "The filter is 'all' -> adding $($item.PackageId) to $itemType filtered list"
                    $filteredList += $item
                }
                elseif ($item.PackageId -like $filter)
                {
                    Write-OctopusVerbose "The filter $filter matches $($item.PackageId), adding $($item.PackageId) to $itemType filtered list"
                    $filteredList += $item
                }
                else
                {
                    Write-OctopusVerbose "The item $($item.PackageId) does not match filter $filter"
                }
            }
        }
    }
    else
    {
        Write-OctopusWarning "The filter for $itemType was not set."
    }

    return $filteredList
}

function Convert-OctopusProcessDeploymentStepId
{
    param(
        $sourceProcess,
        $destinationProcess,
        $sourceId
    )

    Write-OctopusVerbose "Attempting to determine the destination action ID of the step source $sourceId"
    $sourceStepName = $null
    $sourceActionName = $null

    foreach ($step in $sourceProcess.Steps)
    {
        foreach ($action in $step.Actions)
        {
            if ($action.Id -eq $sourceId)
            {
                Write-OctopusVerbose "Found the $sourceId in the deployment process with the step name $($step.Name) and action name $($action.Name)"                
                $sourceStepName = $step.Name
                $sourceActionName = $action.Name
                break
            }
        }

        if ($null -ne $sourceStepName)
        {
            break
        }
    }
    
    if ($null -eq $sourceStepName)
    {
        return $null
    }

    foreach ($step in $destinationProcess.Steps)
    {
        Write-OctopusVerbose "Checking to see if $($step.Name) matches $sourceStepName"
        if ($step.Name.ToLower().Trim() -eq $sourceStepName.ToLower().Trim())
        {
            Write-OctopusVerbose "The step names match, now loop through the actions"
            foreach($action in $step.Actions)
            {
                Write-OctopusVerbose "Checking to see if $($action.Name) matches $sourceActionName"
                if ($action.Name.ToLower().Trim() -eq $sourceActionName.ToLower().Trim())
                {
                    Write-OctopusVerbose "The action names match, return $($action.Id)"
                    return $action.Id
                }
            }
        }
    }

    return $null
}

function Compare-OctopusVersions
{
    param(
        $sourceData,
        $destinationData,
        $IgnoreVersionCheckResult,
        $SkipPausingWhenIgnoringVersionCheckResult
    )

    if ($sourceData.MajorVersion -ne $destinationData.MajorVersion -or $sourceData.MinorVersion -ne $destinationData.MinorVersion)
    {
        Write-OctopusCritical "The source $($sourceData.OctopusUrl) is on version $($sourceData.MajorVersion).$($sourceData.MinorVersion).x while the destination $($destinationData.OctopusUrl) is on version $($destinationData.MajorVersion).$($DestinationData.MinorVersion).x."

        if ($IgnoreVersionCheckResult -eq $false)
        {
            if ($sourceData.MajorVersion -ne $destinationData.MajorVersion)
            {
                Write-OctopusCritical "The major versions do not match.  Attempting to clone between major versions is fairly risky.  Please upgrade the source or destination to match and try again.  You can ignore this warning by setting the argument IgnoreVersionCheckResult to $true"    
                Exit 1
            }

            if ($sourceData.MajorVersion -eq $destinationData.MajorVersion -and $sourceData.MinorVersion -lt $destinationData.MinorVersion)
            {
                Write-OctopusCritical "The major versions match and the source data minor version is less than the destination data minor version.  You should be safe to run this clone.  However, by default this functionality is blocked.  You can ignore this warning by setting the argument IgnoreVersionCheckResult to $true"
                exit 1
            }

            if ($sourceData.MajorVersion -eq $destinationData.MajorVersion -and $sourceData.MinorVersion -gt $destinationData.MinorVersion)
            {
                Write-OctopusCritical "The major versions match and the source data minor version is higher than the destination data minor version.  This is a bit more risky, but you should be safe to try.  You can ignore this warning by setting the argument IgnoreVersionCheckResult to $true"
                exit 1
            }

            Write-OctopusCritical "The major and minor versions do not match, in general the cloner will work, however, you run the risk of something not cloning corectly.  You can ignore this warning by setting the argument IgnoreVersionCheckResult to $true"
        }

        Write-OctopusCritical "You have chosen to ignore that difference.  This run may work or it may not work."
        
        if ($SkipPausingWhenIgnoringVersionCheckResult -eq $false)
        {
            Write-OctopusCritical "I am pausing for 20 seconds to give you a chance to cancel.  If you cloning to a production instance it is highly recommended you cancel this.  You can skip this pausing by setting the argument SkipPausingWhenIgnoringVersionCheckResult to $true"
            $versionCheckCountDown = 20
            
            while ($versionCheckCountDown -gt 0)
            {
                Write-OctopusCritical "Seconds left: $versionCheckCountDown"
                Start-Sleep -Seconds 1        
                $versionCheckCountDown -= 1
            }
        }
        else
        {
            Write-OctopusCritical "Someone ate their YOLO-flakes today and elected to skip the pause of the version check as well."    
        }
        
        Write-OctopusCritical "Alright, this is a bold choice, I like it.  Proceeding."
    }
}

function Convert-OctopusPackageList
{
    param (
        $item,
        $sourceData,
        $destinationData
    )

    foreach ($package in $item.Packages)
    {
        $package.FeedId = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $package.FeedId
        $package.Id = $null
    }    
}

function Get-OctopusScriptActionTypes
{
    return @("Octopus.Script", "Octopus.AwsRunScript", "Octopus.AzurePowerShell", "Octopus.KubernetesRunScript" )
}

function Update-OctopusList
{
    param(
        $itemList,
        $itemToReplace
    )

    $itemArray = @($itemList)

    $indexOfItem = -1
    $index = -1
    Write-OctopusVerbose "Going to replace $($itemToReplace.Id) in list"
    foreach ($item in $itemArray)
    {
        $index += 1
        Write-OctopusVerbose "Comparing $($itemToReplace.Id) with $($item.Id)"

        if ($itemToReplace.Id -eq $item.Id)
        {
            Write-OctopusVerbose "Item matches"
            $indexOfItem = $index
            break
        }
    }

    if ($indexOfItem -ge 0)
    {
        Write-OctopusVerbose "The item exists in the array, replacing it"
        $itemArray.Item($indexOfItem) = $itemToReplace
    }
    else
    {
        Write-OctopusVerbose "Unable to find matching id, adding it to list"    
        $itemArray += $itemToReplace
    }

    return $itemArray
}

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
        if ($lowerParameterValue -ne "errorunlessexactmatch" -and $lowerParameterValue -ne "skipunlessexactmatch" -and $lowerParameterValue -ne "errorunlesspartialmatch" -and $lowerParameterValue -ne "skipunlesspartialmatch" -and $lowerParameterValue -ne "ignoremismatch")
        {
            Write-OctopusCritical "The parameter $parameterName is set to $parameterValue.  Acceptable values are ErrorUnlessExactMatch, SkipUnlessExactMatch, ErrorUnlessPartialMatch, SkipUnlessPartialMatch, or IgnoreMismatch."
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