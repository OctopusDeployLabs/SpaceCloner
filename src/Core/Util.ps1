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

function Convert-SourceIdToDestinationId
{
    param(
        $SourceList,
        $DestinationList,
        $IdValue
    )

    $idValueSplit = $IdValue -split "-"
    if (($idValueSplit[1] -match "^[\d\.]+$") -eq $false)
    {
        Write-OctopusVerbose "The id value $idValue is a built in id, no need to convert, returning it."
        return $IdValue
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

    $filteredList = @()  
    
    Write-OctopusSuccess "Creating filter list for $itemType"

    if ([string]::IsNullOrWhiteSpace($filters) -eq $false)
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

        if ($filteredList.Length -eq 0)
        {
            Write-OctopusWarning "No $itemType items were found to clone, skipping"
        }
        else
        {
            Write-OctopusSuccess "$itemType items were found to clone, starting clone for $itemType"
        }
    }
    else
    {
        Write-OctopusWarning "The filter for $itemType was not set.  No $itemType will be cloned.  If you wish to clone all $itemType use 'all' or use a comma seperated list (wild cards supported), IE 'AWS*,Space Infrastructure."
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