function Copy-OctopusItemLogo
{
    param(
        $sourceItem,
        $destinationItem,
        $SourceData,
        $DestinationData,
        $CloneScriptOptions,
        $CloneLogo
    )

    if ([string]::IsNullOrWhiteSpace($CloneLogo) -or $cloneLogo -eq $false)
    {
        Write-OctopusVerbose "Cloning logos is set to $CloneLogo.  Skipping the logo cloning for $($sourceItem.Name)."
        return
    }

    $queryString = $sourceItem.Links.Logo.SubString($sourceItem.Links.Logo.IndexOf("?") + 4)
    if ($queryString -ne $sourceData.ApiInformation.Version)
    {
        Write-OctopusVerbose "The item $($sourceItem.Name) has a logo, downloading it to clone to the destination"

        if ($destinationData.WhatIf -eq $true)
        {
            Write-OctopusVerbose "What if set to true, skipping download of logo"
            return
        }

        $imageDate = Get-Date 
        $dateForImage = $imageDate.ToString("yyyy_MM_dd_HH_mm_ss")
        
        $filePath = [System.IO.Path]::Combine($PSScriptRoot, "TempImage_$dateForImage.tmp")        
        Get-OctopusItemLogo -item $sourceItem -OctopusUrl $SourceData.OctopusUrl -ApiKey $SourceData.OctopusApiKey -filepath $filePath

        Write-OctopusVerbose "The item $($sourceItem.Name) has a logo to upload, uploading to destination"                   
        
        Save-OctopusItemLogo -item $destinationItem -OctopusUrl $destinationData.OctopusUrl -ApiKey $destinationData.OctopusApiKey -fileContentToUpload $filePath -whatIf $destinationData.WhatIf

        Start-Sleep -Seconds 2
        
        try {
            Remove-Item $filePath -Force   
            Write-OctopusVerbose "The temporary image for $($sourceItem.Name) has been deleted."
        }
        catch {
            Write-OctopusWarning "Unable to remove the temporary image $filePath"
        }
        
    }
    else
    {
        Write-OctopusVerbose "The item $($SourceItem.Name) does not have a logo because the links to is set to $($sourceItem.Links.Logo), which matches the API version.  An actual logo will have a non-api version value."
    }    
}