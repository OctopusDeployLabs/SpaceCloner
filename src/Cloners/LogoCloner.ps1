function Copy-OctopusItemLogo
{
    param(
        $sourceItem,
        $destinationItem,
        $SourceData,
        $DestinationData,
        $CloneScriptOptions
    )

    $queryString = $sourceItem.Links.Logo.SubString($sourceItem.Links.Logo.IndexOf("?") + 4)
    if ($queryString -ne $sourceData.ApiInformation.Version)
    {
        Write-OctopusVerbose "The item $($sourceItem.Name) has a logo, downloading it to clone to the destination"

        $imageDate = Get-Date 
        $dateForImage = $imageDate.ToString("yyyy_MM_dd_HH_mm_ss")
        $filePath = "$PSScriptRoot\TempImage_$dateForImage.tmp"
        Get-OctopusItemLogo -item $sourceItem -OctopusUrl $SourceData.OctopusUrl -ApiKey $SourceData.OctopusApiKey -filepath $filePath

        Write-OctopusVerbose "The item $($sourceItem.Name) has a logo to upload, uploading to destination"        
        Save-OctopusItemLogo -item $destinationItem -OctopusUrl $destinationData.OctopusUrl -ApiKey $destinationData.OctopusApiKey -fileContentToUpload $filePath

        Write-OctopusVerbose "The temporary image for $($sourceItem.Name) has been deleted."
        try {
            Remove-Item $filePath    
        }
        catch {
            Write-OctopusWarning "Unable to remove the temporary image $filePath"
        }
        
    }
    else
    {
        Write-OctopusVerbose "The item $($item.Name) does not have a logo, skipping logo clone"
    }    
}