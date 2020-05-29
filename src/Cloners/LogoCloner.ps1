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

        $filePath = "$PSScriptRoot\TempImage.tmp"
        Get-OctopusItemLogo -item $sourceItem -OctopusUrl $SourceData.OctopusUrl -ApiKey $SourceData.OctopusApiKey -filepath $filePath

        Write-OctopusVerbose "The item $($sourceItem.Name) has a logo to upload, uploading to destination"        
        Save-OctopusItemLogo -item $destinationItem -OctopusUrl $destinationData.OctopusUrl -ApiKey $destinationData.OctopusApiKey -fileContentToUpload $filePath
    }
    else
    {
        Write-OctopusVerbose "The item $($item.Name) does not have a logo, skipping logo clone"
    }    
}