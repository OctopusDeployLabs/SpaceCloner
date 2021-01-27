function Get-OctopusItemByName
{
    param (
        $ItemList,
        $ItemName
        )    

    return ($ItemList | Where-Object {$_.Name -eq $ItemName})
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
        $IdValue
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
    
    Write-OctopusVerbose "Getting Name of $IdValue"
    $sourceItem = Get-OctopusItemById -ItemList $SourceList -ItemId $IdValue

    $nameToUse = $sourceItem.Name
    if ([string]::IsNullOrWhiteSpace($nameToUse))
    {
        Write-OctopusVerbose "The name property is null attempting the username property"
        $nameToUse = $sourceItem.UserName
    }

    if ([string]::IsNullOrWhiteSpace($nameToUse))
    {
        Write-OctopusVerbose "Unable to find a name property for $IdValue"
        return $null
    }

    Write-OctopusVerbose "The name of $IdValue is $nameToUse, attempting to find in destination list"    

    $destinationItem = Get-OctopusItemByName -ItemName $nameToUse -ItemList $DestinationList    

    if ($null -eq $destinationItem)
    {
        Write-OctopusVerbose "Unable to find $nameToUse in the destination list"
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
        $IdList
    )

    $NewIdList = @()
    Write-OctopusVerbose "Converting id list with $($IdList.Length) item(s) over to destination space"     
    foreach ($idValue in $idList)
    {
        $ConvertedId = Convert-SourceIdToDestinationId -SourceList $SourceList -DestinationList $DestinationList -IdValue $IdValue

        if ($null -ne $ConvertedId)
        {
            $NewIdList += $ConvertedId
        }
    }

    return @($NewIdList)
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
        $propertyValue)
    
    if ((Test-OctopusObjectHasProperty -objectToTest $objectToTest -propertyName $propertyName) -eq $false)
    {            
        $objectToTest | Add-Member -MemberType NoteProperty -Name $propertyName -Value $propertyValue
    }
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
                if (($filter).ToLower() -eq "all")
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

    $sourceStepName = $null
    $sourceActionName = $null

    foreach ($step in $sourceProcess.Steps)
    {
        foreach ($action in $step.Actions)
        {
            if ($action.Id -eq $sourceId)
            {
                break
            }
        }

        if ($null -ne $sourceStepName)
        {
            break
        }
    }
    
    foreach ($step in $destinationProcess.Steps)
    {
        if ($step.name -eq $sourceStepName)
        {
            foreach($action in $step.Actions)
            {
                if ($action.Name -eq $sourceActionName)
                {
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