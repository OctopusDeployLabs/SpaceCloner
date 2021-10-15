function Copy-OctopusCertificates
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    $certListToClone = $cloneScriptOptions.CertificatesToClone -split ","
    
    foreach ($certNameAndPassword in $certListToClone)
    {
        $certSplit = $certNameAndPassword -split "::"
        $certName = $certSplit[0]

        $certPassword = $null
        if ($certSplit.Length -gt 1)
        {
            $certPassword = $certSplit[1]
        }

        Write-OctopusVerbose "Starting clone of Certificate $($certName)"
        
        $certificate = Get-OctopusItemByName -itemName $certName -itemList $sourceData.CertificateList

        if ($null -eq $certificate)
        {
            Write-OctopusVerbose "  Unable to find certificate $($certName) on the source."
            continue
        }

        $matchingItem = Get-OctopusItemByName -ItemName $certificate.Name -ItemList $destinationData.CertificateList                       

        $certObject = $null
        If ($null -eq $matchingItem)
        {
            Write-OctopusVerbose "Certificate $($certificate.Name) was not found in destination, creating new record."
            Write-OctopusChangeLog " - Add $($certificate.Name)"                    
            $certObject = Copy-OctopusObject -ItemToCopy $certificate -SpaceId $destinationData.SpaceId -ClearIdValue $true 

            $certObject.EnvironmentIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $target.EnvironmentIds)
            $certObject.TenantIds = @(Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TenantList -DestinationList $DestinationData.TenantList -IdList $target.TenantIds)
        }
        elseif ($matchingItem.Thumbprint -ne $certificate.Thumbprint) 
        {
            Write-OctopusVerbose "Certificate $($certificate.Name) has the thumbprint $($certificate.Thumbprint) while the destination has the thumbprint $($matchingItem.Thumbprint).  Updating the destination."  
            Write-OctopusChangeLog " - Update $($certificate.Name)"  
            $certObject = $matchingItem
        }
        else
        {
            Write-OctopusVerbose "Certificate $($certificate.Name) already exists in destination and the thumbprints match."  
            Write-OctopusChangeLog " - $($certificate.Name) already exists with matching thumbprint, skipping"  
        }

        if ($cloneCertificate -eq $true)
        {
            Write-OctopusVerbose "Downloading Certificate $($certificate.Name) from the Octopus Server."

            $certFileExtension = Get-OctopusCertificateFileExtension -certificateDataFormat $certificate.CertificateDataFormat
            $certFileName = $certificate.Name -replace " ", ""

            $filePath = [System.IO.Path]::Combine($PSScriptRoot, "$($certFileName).$($certFileExtension)")

            if (Test-Path $filePath)
            {
                Write-OctopusVerbose "      The file $filePath already exists, deleting now."
                Remove-Item $filePath
            }

            if ($DestinationData.WhatIf -eq $true)
            {
                Write-OctopusVerbose "      Whatif set to true, skipping downloading and uploading of certificate"
                continue
            }

            Get-OctopusCertificateExport -certificate $certificate -octopusData $sourceData -filePath $filePath
            Write-OctopusVerbose "      The certificate $($certificate.Name) has finished downloading"
            
            $certificateContent = [Convert]::ToBase64String((Get-Content -Path $filePath -Encoding Byte))
            $passwordObject = @{
                HasValue = $false
                NewValue = $null
            }

            if ([string]::IsNullOrWhiteSpace($certPassword) -eq $false)
            {
                $passwordObject.HasValue = $true
                $passwordObject.NewValue = $certPassword
            }

            $jsonPayload = @{
                Id = $null
                Name = $certObject.Name
                Notes = $certObject.Notes
                CertificateData = @{
                    HasValue = $true
                    NewValue = $certificateContent
                }
                Password = $passwordObject
                EnvironmentIds = $certObject.EnvironmentIds
                TenantIds = $certObject.TenantIds
                TenantTags = $certObject.Tenanttags
                TenantedDeploymentParticipation = $certObject.TenantedDeploymentParticipation
            }   
            
            if ($null -ne $certObject.Id)
            {
                $jsonPayload.Id = $certObject.Id
            }

            Save-OctopusCertificate -cert $jsonPayload -destinationData $destinationData
        }
    }    

    Write-OctopusSuccess "Certificates successfully cloned"        
}

Get-OctopusCertificateFileExtension
{
    param (
        $certificateDataFormat
    )

    $formatToCompare = $CertificateDataFormat.ToLower().Trim()

    if ($formatToCompare -eq "pkcs12")
    {
        return "pfx"
    }

    if ($formatToCompare -eq "der")
    {
        return "der"
    }

    if ($formatToCompare -eq "pem")
    {
        return "pem"
    }

    return "unknown"
}