function Copy-OctopusCertificates
{
    param(
        $sourceData,
        $destinationData,
        $cloneScriptOptions
    )
    
    Write-OctopusSuccess "Starting certificate cloning to destination"
    Write-OctopusChangeLog "Certificates"
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

        if ($null -ne $certObject)
        {
            Write-OctopusVerbose "Downloading Certificate $($certificate.Name) from the Octopus Server."

            $certFileExtension = Get-OctopusCertificateFileExtension -certificateDataFormat $certificate.CertificateDataFormat
            $certFileName = $certificate.Name -replace " ", ""
            $certFileName = $certfileName -replace "\.", ""

            Write-OctopusVerbose "Attempting to match Certificate Environment Ids to the destination"
            $newEnvironmentIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $certificate.EnvironmentIds -MatchingOption $CloneScriptOptions.InfrastructureEnvironmentScopingMatch -IdListName "$($certificate.Name) Environment Scoping"
            if ($newEnvironmentIds.CanProceed -eq $false)
            {
                continue
            }
            $certObject.EnvironmentIds = @($newEnvironmentIds.NewIdList)  

            Write-OctopusVerbose "Attempting to match Certificate Tenant Ids to the destination"
            $newTenantIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TenantList -DestinationList $DestinationData.TenantList -IdList $certificate.TenantIds -MatchingOption $CloneScriptOptions.InfrastructureTenantScopingMatch -IdListName "$($certificate.Name) Tenant Scoping"
            if ($newTenantIds.CanProceed -eq $false)
            {
                continue
            }
            $certObject.TenantIds = @($newTenantIds.NewIdList)
            
            $certObject.TenantTags = $certificate.TenantTags
            $certObject.TenantedDeploymentParticipation = $certificate.TenantedDeploymentParticipation

            $filePath = [System.IO.Path]::Combine($PSScriptRoot, "$($certFileName).$($certFileExtension)")

            if (Test-Path $filePath)
            {
                Write-OctopusVerbose "      The file $filePath already exists, deleting now."
                Remove-Item $filePath
            }

            Get-OctopusCertificateExport -certificate $certificate -octopusData $sourceData -filePath $filePath
            Write-OctopusVerbose "      The certificate $($certificate.Name) has finished downloading"
            
            Write-OctopusVerbose "Reading the downloaded cert $filePath as binary"
            try
            {
                $fileContentToConvertToBase64 = (Get-Content -Path $filePath -AsByteStream)
            }
            catch
            {
                Write-OctopusError "Unable to read the file $filePath as binary"
                Write-OctopusError $_.Exception                
            }
            
            $certificateContent = [System.Convert]::ToBase64String($fileContentToConvertToBase64)

            $passwordObject = @{
                HasValue = $false
                NewValue = $null
            }
            if ([string]::IsNullOrWhiteSpace($certPassword) -eq $false)
            {
                Write-OctopusVerbose "Password found, adding it to the cert request"
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

            $jsonPayload = [pscustomobject]$jsonPayload

            $updatedCert = Save-OctopusCertificate -cert $jsonPayload -destinationData $destinationData
            $destinationData.CertificateList = Update-OctopusList -itemList $destinationData.CertificateList -itemToReplace $updatedCert

            Remove-Item $filePath
        }
    }    

    Write-OctopusSuccess "Certificates successfully cloned"        
}

function Get-OctopusCertificateFileExtension
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