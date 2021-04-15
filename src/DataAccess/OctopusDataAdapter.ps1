function Get-OctopusUrl
{
    param (
        $EndPoint,
        $SpaceId,
        $OctopusUrl
    )

    $octopusUrlToUse = $OctopusUrl
    if ($OctopusUrl.EndsWith("/"))
    {
        $octopusUrlToUse = $OctopusUrl.Substring(0, $OctopusUrl.Length - 1)
    }

    if ($EndPoint -match "/api")
    {
        if (!$EndPoint.StartsWith("/api"))
        {
            $EndPoint = $EndPoint.Substring($EndPoint.IndexOf("/api"))
        }

        return "$octopusUrlToUse$EndPoint"
    }

    if ([string]::IsNullOrWhiteSpace($SpaceId))
    {
        return "$octopusUrlToUse/api/$EndPoint"
    }

    return "$octopusUrlToUse/api/$spaceId/$EndPoint"
}

function Invoke-OctopusApi
{
    param
    (
        $url,
        $apiKey,
        $method,
        $item,
        $filePath,
        $retryCount
    )

    try
    {
        if ($null -ne $filePath)
        {
            Write-OctopusVerbose "Filepath $filePath parameter provided, saving output to the filepath from $url"
            return Invoke-RestMethod -Method $method -Uri $url -Headers @{"X-Octopus-ApiKey" = "$ApiKey" } -OutFile $filePath -TimeoutSec 60
        }

        if ($null -eq $item)
        {
            Write-OctopusVerbose "No data to post or put, calling bog standard invoke-restmethod for $url"
            return Invoke-RestMethod -Method $method -Uri $url -Headers @{"X-Octopus-ApiKey" = "$ApiKey" } -ContentType 'application/json; charset=utf-8' -TimeoutSec 60
        }

        $body = $item | ConvertTo-Json -Depth 10
        Write-OctopusVerbose $body

        Write-OctopusVerbose "Invoking $method $url"
        return Invoke-RestMethod -Method $method -Uri $url -Headers @{"X-Octopus-ApiKey" = "$ApiKey" } -Body $body -ContentType 'application/json; charset=utf-8' -TimeoutSec 60
    }
    catch [System.TimeoutException]
    {        
        $newRetryCount = 1
        if ($null -ne $retryCount)
        {
            $newRetryCount = $retryCount + 1
        }

        if ($newRetryCount -gt 4)
        {
            Throw "Timeout detected, max retries has been exceeded for this call.  Exiting."
        }
        else 
        {
            Write-OctopusWarning "Timeout detected, going to retry this call for the $newRetryCount time."
            Invoke-OctopusApi -url $url -apiKey $apiKey -method $method -item $item -filePath $filePath -retryCount $retryCount        
        }
    }
    catch
    {
        if ($null -ne $_.Exception.Response)
        {
            if ($_.Exception.Response.StatusCode -eq 401)
            {
                Write-OctopusCritical "Unauthorized error returned from $url, please verify API key and try again"
            }
            elseif ($_.ErrorDetails.Message)
            {                
                Write-OctopusVerbose -Message "Error calling $url StatusCode: $($_.Exception.Response) $($_.ErrorDetails.Message)"
            }            
            else 
            {
                Write-OctopusVerbose $_.Exception
            }
        }
        else
        {
            Write-OctopusVerbose $_.Exception
        }

        Throw "There was an error calling the Octopus API please check the log for more details"
    }    
}

Function Get-OctopusApiItemList
{
    param (
        $EndPoint,
        $ApiKey,
        $SpaceId,
        $OctopusUrl
    )

    $url = Get-OctopusUrl -EndPoint $EndPoint -SpaceId $SpaceId -OctopusUrl $OctopusUrl

    $results = Invoke-OctopusApi -Method "Get" -Url $url -apiKey $ApiKey

    Write-OctopusVerbose "$url returned a list with $($results.Items.Length) item(s)"

    if ($results.Items.Count -eq 0)
    {
        return @()
    }

    return $results.Items
}

Function Get-OctopusApi
{
    param (
        $EndPoint,
        $ApiKey,
        $SpaceId,
        $OctopusUrl
    )

    $url = Get-OctopusUrl -EndPoint $EndPoint -SpaceId $SpaceId -OctopusUrl $OctopusUrl

    $results = Invoke-OctopusApi -Method "Get" -Url $url -apiKey $ApiKey

    return $results
}

Function Save-OctopusApi
{
    param (
        $EndPoint,
        $ApiKey,
        $Method,
        $Item,
        $SpaceId,
        $OctopusUrl,
        $whatIf
    )

    if ($null -ne $whatIf -and $whatIf -eq $true)
    {
        Write-OctopusVerbose "What if set to true, skipping $method to $endPoint and just returning the item"
        Write-OctopusVerbose ($item | ConvertTo-Json -Depth 10)
        
        if ($null -eq $Item)
        {
            return $null
        }        
        
        if ((Test-OctopusObjectHasProperty -objectToTest $Item -propertyName "Id") -eq $true -and $null -eq $Item.Id)
        {
            $Item.Id = (New-Guid).ToString()
        }

        return $item
    }

    $url = Get-OctopusUrl -EndPoint $EndPoint -SpaceId $SpaceId -OctopusUrl $OctopusUrl

    $results = Invoke-OctopusApi -Method $Method -Url $url -apiKey $ApiKey -item $item

    return $results
}

function Save-OctopusApiItem
{
    param(
        $Item,
        $Endpoint,
        $ApiKey,
        $SpaceId,
        $OctopusUrl,
        $WhatIf
    )

    $method = "POST"

    if ($null -ne $Item.Id)
    {
        Write-OctopusVerbose "Item has id, updating method call to PUT"
        $method = "Put"
        $endPoint = "$endPoint/$($Item.Id)"
    }

    $results = Save-OctopusApi -EndPoint $Endpoint $method $method -Item $Item -ApiKey $ApiKey -OctopusUrl $OctopusUrl -SpaceId $SpaceId -WhatIf $WhatIf

    Write-OctopusVerbose $results

    return $results
}

function Save-OctopusBlobData
{
    param(
        $url,
        $apiKey,
        $fileContentToUpload,
        $whatIf
    )    

    if ($null -ne $whatIf -and $whatIf -eq $true)
    {
        return
    }

    Write-OctopusVerbose "Uploading data to $url"

    Add-Type -AssemblyName System.Net.Http

    $httpClientHandler = New-Object System.Net.Http.HttpClientHandler

    $httpClient = New-Object System.Net.Http.HttpClient $httpClientHandler
    $httpClient.DefaultRequestHeaders.Add("X-Octopus-ApiKey", $ApiKey)

    $packageFileStream = New-Object System.IO.FileStream @($fileContentToUpload, [System.IO.FileMode]::Open)

    $contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
    $contentDispositionHeaderValue.Name = "fileData"
    $contentDispositionHeaderValue.FileName = [System.IO.Path]::GetFileName($fileContentToUpload)

    $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
    $streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
    $ContentType = "multipart/form-data"
    $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $ContentType

    $content = New-Object System.Net.Http.MultipartFormDataContent
    $content.Add($streamContent)

    $result = $httpClient.PostAsync($url, $content).Result    

    $streamContent.Dispose()

    return
}