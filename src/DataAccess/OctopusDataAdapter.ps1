function Get-OctopusUrl
{
    param (
        $EndPoint,        
        $SpaceId,
        $OctopusUrl
    )  

    if ($EndPoint -match "/api")
    {        
        return "$OctopusUrl/$endPoint"
    }
    
    if ([string]::IsNullOrWhiteSpace($SpaceId))
    {
        return "$OctopusUrl/api/$EndPoint"
    }
    
    return "$OctopusUrl/api/$spaceId/$EndPoint"
}

function Invoke-OctopusApi
{
    param
    (
        $url,
        $apiKey,
        $method,
        $item,
        $filePath        
    )

    try 
    {                    
        if ($null -ne $filePath)
        {
            Write-OctopusVerbose "Filepath $filePath parameter provided, saving output to the filepath from $url"
            return Invoke-RestMethod -Method $method -Uri $url -Headers @{"X-Octopus-ApiKey"="$ApiKey"} -OutFile $filePath
        }                     

        if ($null -eq $item)
        {       
            Write-OctopusVerbose "No data to post or put, calling bog standard invoke-restmethod for $url"
            return Invoke-RestMethod -Method $method -Uri $url -Headers @{"X-Octopus-ApiKey"="$ApiKey"}                            
        }

        $body = $item | ConvertTo-Json -Depth 10
        Write-OctopusVerbose $body    
            
        Write-OctopusVerbose "Invoking $method $url"  
        return Invoke-RestMethod -Method $method -Uri $url -Headers @{"X-Octopus-ApiKey"="$ApiKey"} -Body $body
    }
    catch 
    {
        if ($null -ne $_.Exception.Response)
        {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-OctopusVerbose -Message "Error calling $url $($_.Exception.Message) StatusCode: $($_.Exception.Response.StatusCode.value__ ) StatusDescription: $($_.Exception.Response.StatusDescription) $responseBody"        
        }
        else 
        {
            Write-OctopusVerbose $_.Exception    
        }
    }

    Throw "There was an error calling the Octopus API please check the log for more details"
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
        $OctopusUrl
    )

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
        $OctopusUrl
    )    

    $method = "POST"

    if ($null -ne $Item.Id)    
    {
        Write-OctopusVerbose "Item has id, updating method call to PUT"
        $method = "Put"
        $endPoint = "$endPoint/$($Item.Id)"
    }
    
    $results = Save-OctopusApi -EndPoint $Endpoint $method $method -Item $Item -ApiKey $ApiKey -OctopusUrl $OctopusUrl -SpaceId $SpaceId

    Write-OctopusVerbose $results

    return $results
}

function Get-OctopusItemLogo
{
    param(
        $item,
        $octopusUrl,
        $apiKey,
        $filePath
    )
    
    $url = Get-OctopusUrl -EndPoint $item.Links.Logo -SpaceId $null -OctopusUrl $OctopusUrl

    return Invoke-OctopusApi -Method "Get" -Url $url -apiKey $ApiKey -filePath $filePath
}

function Save-OctopusItemLogo
{
    param(
        $item,
        $octopusUrl,
        $apiKey,
        $fileContentToUpload        
    )
    
    $url = Get-OctopusUrl -EndPoint $item.Links.Logo -SpaceId $null -OctopusUrl $OctopusUrl

    Write-OctopusVerbose "Uploading logo to $url"        
    
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
    $ContentType = "application/octet-stream"
    $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $ContentType
    
    $content = New-Object System.Net.Http.MultipartFormDataContent
    $content.Add($streamContent)

    $httpClient.PostAsync($url, $content).Result

    return
        
}