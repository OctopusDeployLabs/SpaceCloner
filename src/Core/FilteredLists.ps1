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
        $filters,
        $includeFilters
    )   
    
    if ([string]::IsNullOrWhiteSpace($includeFilters))
    {
        $filteredList = New-OctopusFilteredList -itemList $itemList -itemType $itemType -filters $filters     

        if ($filteredList.Length -eq 0)
        {
            Write-OctopusVerbose "No $itemType items were found to exclude"
        }    
    
        return $filteredList
    }
    
    $filteredList = @()
    
    if ($includeFilters.ToLower().Trim() -eq "all")
    {
        Write-OctopusVerbose "The include filter was set to all for $itemType, there are no items to exclude."

        return $filteredList
    }   
    
    if ($null -eq $itemList)
    {
        Write-OctopusVerbose "There were no items in the item list $itemType, nothing to exclude."

        return $filteredList
    }

    Write-OctopusVerbose "The inclusion filter $includeFilters for $itemType was sent in.  Going to build the exclusion list based on that."
    $splitFilters = $includeFilters -split ","
    
    foreach ($item in $itemList)
    {
        $matchFound = $false
        foreach ($filter in $splitFilters)
        {
            Write-OctopusVerbose "Checking to see if filter $filter matches $($item.Name)"
            if ([string]::IsNullOrWhiteSpace($filter))
            {
                Write-OctopusVerbose "The filter $filter was null or empty, that's odd, moving onto the next filter"
                continue
            }
            
            if ($item.Name -like $filter)
            {
                Write-OctopusVerbose "The filter $filter matches $($item.Name), it will not be included in the exclusion list."
                $matchFound = $true
            }
        }

        if ($matchFound -eq $false)
        {
            Write-OctopusVerbose "No match was found for $($item.Name), adding it to the exclusion list."
            $filteredList += $item
        }
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

    if ([string]::IsNullOrWhiteSpace($filters) -eq $true)
    {
        Write-OctopusWarning "The filter for $itemType was not set.  Returning empty list."
        return $filteredList
    }

    if ($null -eq $itemList -or $itemList.Count -eq 0)
    {
        Write-OctopusWarning "The item list for $itemType was empty.  Returning an empty list."
        return $filteredList
    }
    
    if ([string]::IsNullOrWhiteSpace($filters) -eq $false -and $filters.ToLower().Trim() -eq "all")
    {
        Write-OctopusVerbose "The filter was set to 'all' returning the entire list of $itemType."
        return $itemList
    }

    $splitFilters = $filters -split ","

    foreach ($filter in $splitFilters)
    {
        if ([string]::IsNullOrWhiteSpace($filter))
        {
            Write-OctopusVerbose "The filter is an empty string, moving onto the next item."
            continue
        } 

        $filterToCompare = $filter.ToLower().Trim()

        foreach($item in $itemList)
        {                            
            Write-OctopusVerbose "Checking to see if $filterToCompare matches $($item.Name)"
                                               
            if ($item.Name.ToLower().Trim() -like $filterToCompare)
            {
                Write-OctopusVerbose "The filter $filter matches $($item.Name), adding $($item.Name) to $itemType filtered list"
                $filteredList += $item
            }
            else
            {
                Write-OctopusVerbose "The item $($item.Name) does not match filter $filter.  Moving onto next item."
                continue
            }
        }
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