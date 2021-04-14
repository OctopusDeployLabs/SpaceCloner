function Copy-OctopusBuiltInPackages
{
    param(
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    Write-OctopusSuccess "Starting package cloning to destination"
    Write-OctopusChangeLog "Packages"

    $filteredSourceFeedPackages = Get-OctopusFilteredListByPackageId -itemList $SourceData.PackageList -itemType "Packages" -filters $cloneScriptOptions.PackagesToClone
        
    if ($filteredSourceFeedPackages.length -eq 0)
    {
        Write-OctopusChangeLog " - No Packages found to clone matching the filters"
        return
    }

    foreach ($package in $filteredSourceFeedPackages)
    {
        Write-OctopusVerbose "  Starting clone for package $($package.PackageId)"
        Write-OctopusVerbose "      Checking to see if $($package.PackageId) already exists on destination."
        $matchingItem = Get-OctopusItemByPackageId -ItemPackageId $package.PackageId -ItemList $DestinationData.PackageList

        $clonePackageToDestination = $false
        if ($null -ne $matchingItem)
        {
            Write-OctopusVerbose "      The destination has $($package.PackageId) already, checking the latest version numbers."
            if ($package.Version -ne $matchingItem.Version)
            {
                Write-OctopusVerbose "      The destination has $($package.Version) while the source has $($package.Version).  Copying this package over."
                Write-OctopusChangeLog " - New $($package.PackageId).$($package.Version)"
                $clonePackageToDestination = $true
            }
            else 
            {
                Write-OctopusVerbose "      The destiantion already has this package version, skipping." 
                Write-OctopusChangeLog " - $($package.PackageId).$($package.Version) already exists, skipping."   
            }
        }
        else 
        {
            Write-OctopusVerbose "      The destination does not have $($package.PackageId), copying the latest package over"
            Write-OctopusChangeLog " - New $($package.PackageId).$($package.Version)"
            $clonePackageToDestination = $true
        }

        if ($clonePackageToDestination -eq $false)
        {
            Write-OctopusVerbose "  Finished cloning package $($package.PackageId)"
            continue
        }
                
        $filePath = [System.IO.Path]::Combine($PSScriptRoot, "$($package.PackageId).$($package.Version)$($package.FileExtension)")

        if (Test-Path $filePath)
        {
            Write-OctopusVerbose "      The file $filePath already exists, deleting now."
            Remove-Item $filePath
        }

        if ($DestinationData.WhatIf -eq $true)
        {
            continue
        }
        
        Write-OctopusVerbose "      Downloading the package to $filePath"
        Get-OctopusPackage -package $package -octopusData $SourceData -filePath $filePath

        Write-OctopusVerbose "      Uploading the package $filePath to the destination"
        Save-OctopusPackage -octopusData $destinationData -fileContentToUpload $filePath

        $deleteTryAttempts = 0
        While ($deleteTryAttempts -lt 5 -and (Test-Path $filePath))
        {
            try {
                Remove-Item $filePath 
            }
            catch {
                Write-OctopusWarning "      $($_.Exception.Message) This is the $($deleteTryAttempts + 1) time I've tried to delete this file.  Going to sleep and try again in 2 seconds."
                Start-Sleep -Seconds 2
                $deleteTryAttempts += 1
            }
        }       

        if ((Test-OctopusObjectHasProperty -objectToTest $package -propertyName "PackageVersionBuildInformation"))
        {
            Write-OctopusVerbose "      Checking to see if the build information is populated"
            if ($null -ne $package.PackageVersionBuildInformation)
            {
                Write-OctopusVerbose "      The package has build information, clone that to the destination"
                $buildInformation = Copy-OctopusObject -ItemToCopy $package.PackageVersionBuildInformation -ClearIdValue $true -SpaceId $null
                $buildInformationBody = @{
                    PackageId = $package.PackageId
                    Version = $package.Version
                    OctopusBuildInformation = $buildInformation
                }
                Save-OctopusBuildInformation -BuildInformation $buildInformationBody -DestinationData $destinationData
            }
        }

        Write-OctopusVerbose "  Finished cloning package $($package.PackageId)"
    }
}