param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,
    $DestinationOctopusServerThumbprint,
    $TentacleInstallDirectory,
    $TentacleInstanceNameToCopy,      
    $ClonedTentacleType,
    $ClonedInstanceName,
    $ClonedListeningPort,
    $ExpectedSourceTentacleType,
    $WhatIf
)

$ErrorActionPreference = "Stop"

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Logging.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Util.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataAdapter.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataFactory.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusRepository.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusFakeFactory.ps1"))

if ($null -eq $DestinationOctopusServerThumbprint)
{
    Throw "The parameter DestinationOctopusServerThumbprint is required.  You can get this by going to configuration -> thumbprint in the destination Octopus Deploy instance."
}

if ($null -eq $TentacleInstallDirectory)
{
    if ($IsLinux)
    {
        $TentacleInstallDirectory = "/opt/octopus/tentacle"
    }
    else
    {
        $TentacleInstallDirectory = "C:\Program Files\Octopus Deploy\Tentacle"    
    }    
}

if ($null -eq $TentacleInstanceNameToCopy)
{
    $TentacleInstanceNameToCopy = "Tentacle"
}

if ($null -eq $ClonedInstanceName)
{
    $ClonedInstanceName = "ClonedInstance"
}

if ($null -eq $ClonedTentacleType)
{
    $ClonedTentacleType = "AsIs"
}

if ($null -eq $WhatIf)
{
    $WhatIf = $false
}

if ($ClonedTentacleType -ne "AsIs" -and $ClonedTentacleType -ne "Polling" -and $ClonedTentacleType -ne "Listening")
{
    Throw "The parameter value $ClonedTentacleType for the parameter ClonedTentacleType is not supported.  It must be 'AsIs', 'Polling' or 'Listening'"
}

if ([string]::IsNullOrEmpty($ExpectedSourceTentacleType) -eq $false -and $ExpectedSourceTentacleType -ne "Polling" -and $ExpectedSourceTentacleType -ne "Listening")
{
    Throw "The parameter value $ExpectedSourceTentacleType for the parameter ExpectedSourceTentacleType is not supported.  It must be 'Polling' or 'Listening'"
}

function Get-MyPublicIPAddress 
{
    # Get Ip Address of Machine 
    $ipAddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip 

    return $ipAddress 
}

function Compare-TentacleWithMachineRegistration
{
    param
    (
        $localTentacle,
        $machineRegistration
    )

    if ($null -eq (Get-Member -InputObject $machineRegistration.Endpoint -Name "Thumbprint" -MemberType Properties))
    {    
        Write-OctopusSuccess "The machine $($machineRegistration.Id):$($machineRegistration.Name) doesn't have an endpoint, thus no thumbprint to check, skipping"
        return $false
    }

    if ($machineRegistration.Endpoint.Thumbprint -ne $localTentacle.Tentacle.CertificateThumbprint)
    {    
        Write-OctopusSuccess "The machine $($machineRegistration.Id):$($machineRegistration.Name) thumbprint $($machineRegistration.Endpoint.Thumbprint) does not match the local tentacle's thumbprint $($localTentacle.Tentacle.CertificateThumbprint)"
        return $false
    }

    if ($localTentacle.Tentacle.Services.NoListen -eq $true)
    {
        Write-OctopusSuccess "The machine $($machineRegistration.Id):$($machineRegistration.Name) thumbprints match and this tentacle is a polling tentacle, found a match"
        return $true
    }

    $portNumber = ($machineRegistration.EndPoint.Uri -split ":")[2]    
    if ($localTentacle.Tentacle.Services.PortNumber -eq $portNumber)
    {
        Write-OctopusSuccess "The machine $($machineRegistration.Id):$($machineRegistration.Name) port $($localTentacle.Tentacle.Services.PortNumber) matches port number $portNumber"
        return $true
    }

    Write-OctopusSuccess "The machine $($machineRegistration.Id):$($machineRegistration.Name) port $($localTentacle.Tentacle.Services.PortNumber) does not match $portNumber proceeding"
    return $false
}

function New-OctopusTargetRegistration
{
    param 
    (
        $sourceData,
        $currentTentacleInformation
    )

    $targetRegistration = @{
        HasTarget = $false;
        Hostname = $null;
        MatchingRegistrations = @()
    }

    Write-OctopusSuccess "Checking to see if the tentacle is a target on the source space"
    
    foreach ($machine in $sourceData.TargetList)
    {
        if (Compare-TentacleWithMachineRegistration -machineRegistration $machine -localTentacle $currentTentacleInformation)
        {        
            $targetRegistration.HasTarget = $true
            if ($null -eq $targetRegistration.Hostname -and $machine.Endpoint.CommunicationStyle -eq "TentaclePassive")
            {            
                $targetRegistration.Hostname = $machine.Endpoint.Uri.Replace("https://", "")
                $targetRegistration.Hostname = $($targetRegistration.Hostname -split ":")[0]
                Write-OctopusSuccess "The hostname of this machine is $($targetRegistration.Hostname)"
            }

            $targetRegistration.MatchingRegistrations += @{
                EnvironmentList =  @(Convert-OctopusIdListToNameList -IdList $machine.EnvironmentIds -itemList $sourceData.EnvironmentList);
                RoleList =  $machine.Roles;
                TenantList = @(Convert-OctopusIdListToNameList -IdList $machine.TenantIds -itemList $sourceData.TenantList);
                TenantTags = $machine.TenantTags;
                TenantType = $machine.TenantedDeploymentParticipation;
                MachinePolicyName = $(Get-OctopusItemById -ItemList $sourceData.MachinePolicyList -ItemId $machine.MachinePolicyId).Name;
                MachineName = $machine.Name
                Id = $machine.Id                                        
            }            

            Write-OctopusSuccess "Found the source machine in the source instance. It has the ID of $($machine.Id)"                        
        }
    }

    return $targetRegistration
}

function New-OctopusWorkerRegistration
{
    param 
    (
        $sourceData,
        $currentTentacleInformation
    )

    $workerRegistration = @{
        HasWorker = $false;
        Hostname = $null;
        MatchingRegistrations = @()
    }

    Write-OctopusSuccess "Checking to see if the tentacle is a worker on the source space"
    
    foreach ($worker in $sourceData.WorkerList)
    {
        if (Compare-TentacleWithMachineRegistration -machineRegistration $worker -localTentacle $currentTentacleInformation)
        {
            $workerRegistration.HasWorker = $true
            if ($null -eq $workerRegistration.Hostname -and $worker.Endpoint.CommunicationStyle -eq "TentaclePassive")
            {            
                $workerRegistration.Hostname = $worker.Endpoint.Uri.Replace("https://", "")
                $workerRegistration.Hostname = $($workerRegistration.Hostname -split ":")[0]
                Write-OctopusSuccess "The hostname of this machine is $($workerRegistration.Hostname)"
            }

            Write-OctopusSuccess "Found a source worker in the source instance. It has the ID of $($worker.Id)"
            $workerRegistration.MatchingRegistrations += @{
                WorkerPoolList = @(Convert-OctopusIdListToNameList -IdList $worker.WorkerPoolIds -itemList $sourceData.WorkerPoolList);
                MachinePolicyName = $(Get-OctopusItemById -ItemList $sourceData.MachinePolicyList -ItemId $worker.MachinePolicyId).Name;
                MachineName = $worker.Name
                Id = $worker.Id
            }                                                
        }
    }

    return $workerRegistration
}

function Get-ClonedTentacleIsListening
{
    param 
    (
        $existingTentacle,
        $ClonedTentacleType
    )

    if ($existingTentacle.Tentacle.Services.NoListen -eq $false -and $ClonedTentacleType -eq "AsIs")
    {
        Write-OctopusSuccess "The existing tentacle is listening, and you've elected to keep that as is. The cloned tentacle will be listening."
        return $true
    }
    
    if ($ClonedTentacleType -eq "Listening")
    {
        Write-OctopusSuccess "You've chosen this is a listening tentacle no matter what.  The cloned tentacle will be listening."
        return $true
    }

    Write-OctopusSuccess "The cloned tentacle will be a polling tentacle"
    return $false
}

function Get-OctopusListeningPortNumber
{
    param 
    (
        $tentacleExe
    )

    $maxPortNumber = 10933
    $instanceList = (& $tentacleExe list-instances --format="JSON") | Out-String | ConvertFrom-Json

    foreach ($instance in $instanceList)
    {
        $instanceConfig = (& $tentacleExe show-configuration --instance="$($instance.InstanceName)") | Out-String | ConvertFrom-Json    

        if ($instanceConfig.Tentacle.Services.NoListen -eq $false -and $instanceConfig.Tentacle.Services.PortNumber -ge $maxPortNumber)
        {
            $maxPortNumber = $instanceConfig.Tentacle.Services.PortNumber + 1
        }
    }

    Write-OctopusSuccess "The new port number for the listening tentacle is: $maxPortNumber"

    return $maxPortNumber
}

function Get-ServerHostNameForListeningTentacleRegistration
{
    param 
    (
        $targetRegistrationList,
        $workerRegistrationList,
        $DestinationOctopusUrl,
        $clonedTentaclesAreListening
    )

    if ($clonedTentaclesAreListening -eq $false)
    {
        return $null
    }

    $Hostname = $targetRegistrationList.Hostname

    if ($null -eq $Hostname)
    {
        $Hostname = $workerRegistrationList.Hostname
    }

    if ($null -eq $Hostname)
    {
        Write-OctopusSuccess "You have selected a listening tentacle, but the source tentacle is not listening, attempting to pull the public IP Address"
        $Hostname = Get-MyPublicIPAddress             
    }

    if ($DestinationOctopusUrl -like "*octopus.app*")
    {
        Write-OctopusCritical "The host name of this machine is $Hostname.  The destination URL ends in octopus.app, this indicates an Octopus Cloud instance.  There is a high chance that the cloud instance won't be able to see this VM.  Recommend using polling tentacles.  Are you sure you want to proceed?  Going to pause 20 seconds so you can stop this script."
        $versionCheckCountDown = 20
            
        while ($versionCheckCountDown -gt 0)
        {
            Write-OctopusCritical "Seconds left: $versionCheckCountDown"
            Start-Sleep -Seconds 1        
            $versionCheckCountDown -= 1
        }

        Write-OctopusCritical "Someone ate their YOLO flakes this morning, proceeding with registration."
    }

    return $Hostname
}

function New-OctopusRegistrationArguments
{
    param
    (
        $newInstanceName,        
        $DestinationOctopusUrl,
        $DestinationOctopusApiKey,
        $DestinationSpaceName,
        $listeningTentacle,
        $Hostname,
        $IsTarget,
        $machineRegistration
    )

    $baseArgs = @()

    if ($IsTarget)
    {                
        $baseArgs += "register-with"

        foreach ($role in $machineRegistration.RoleList) {
            $baseArgs += "--role=$role"
        }
        
        foreach ($env in $machineRegistration.EnvironmentList) {
            $baseArgs += "--environment=`"$env`""
        }

        foreach ($tenant in $machineRegistration.TenantList) {
            $baseArgs += "--tenant=`"$tenant`""            
        }

        foreach ($tenantTag in $machineRegistration.TenantTags) {
            $baseArgs += "--tenanttag=`"$tenantTag`""
        }

        $baseArgs += "--tenanted-deployment-participation=$($machineRegistration.TenantType)"
    }
    else
    {
        $baseArgs += "register-worker"    
        foreach ($workerPool in $machineRegistration.WorkerPoolList) {
            $baseArgs += "--workerpool=`"$workerpool`""
        }
    }  

    $baseArgs += "--instance=$newInstanceName"
    $baseArgs += "--server=$DestinationOctopusUrl"
    $baseArgs += "--apiKey=$DestinationOctopusApiKey"
    $baseArgs += "--space=`"$DestinationSpaceName`""
    $baseArgs += "--policy=`"$($machineRegistration.MachinePolicyName)`""
    $baseArgs += "--name=`"$($machineRegistration.MachineName)`""
    $baseArgs += "--force"
    $baseArgs += "--console"

    if ($listeningTentacle -eq $false)
    {
        Write-OctopusSuccess "The cloned tentacle will be polling, setting the port number to 10943"
        $baseArgs += "--server-comms-port=10943"    
        $baseArgs += "--comms-style=TentacleActive"

        return $baseArgs
    }

    $baseArgs += "--publicHostName=$Hostname"    
    $baseArgs += "--comms-style=TentaclePassive"

    return $baseArgs
}

function Get-TentacleDirectories
{
    param
    (
        $ClonedInstanceName
    )

    $tentacleDirectory = @{}

    if ($IsWindows)
    {
        $tentacleDirectory.HomeDirectory = "C:\Octopus\$ClonedInstanceName" 
        $tentacleDirectory.AppDirectory = "C:\Octopus\$ClonedInstanceName\Applications" 
        $tentacleDirectory.ConfigFile = "C:\Octopus\$ClonedInstanceName\Tentacle\Tentacle.config"  
    }
    else
    {
        $tentacleDirectory.HomeDirectory = "/etc/octopus/default/$ClonedInstanceName" 
        $tentacleDirectory.AppDirectory = "/home/Octopus/$ClonedInstanceName/Applications/" 
        $tentacleDirectory.ConfigFile = "/etc/octopus/default/$ClonedInstanceName/tentacle-default.config"  
    }

    return $tentacleDirectory
}

function New-TentacleInstance
{
    param
    (
        $PollingTentacle,
        $ClonedInstanceName,
        $tentacleDirectory,
        $tentacleExe,
        $tentacleListenPort,
        $DestinationOctopusServerThumbprint,
        $registrationList, 
        $sourceData
    )

    try 
    {
        Write-OctopusSuccess "Creating the cloned tentacle instance $clonedInstanceName"
        & $tentacleExe create-instance --instance $clonedInstanceName --config "$($tentacleDirectory.ConfigFile)" --console 
        if ($lastExitCode -ne 0) 
        { 
            $errorMessage = $error[0].Exception.Message	 
            throw "Installation failed on create-instance: $errorMessage" 
        } 

        Write-OctopusSuccess "Configuring the home directory"
        & $tentacleExe configure --instance $clonedInstanceName --home "$($tentacleDirectory.HomeDirectory)" --console 
        if ($lastExitCode -ne 0) 
        { 
            $errorMessage = $error[0].Exception.Message	 
            throw "Installation failed on configure: $errorMessage" 
        }  

        Write-OctopusSuccess "Configuring the app directory"
        & $tentacleExe configure --instance $clonedInstanceName --app "$($tentacleDirectory.AppDirectory)" --console 
        if ($lastExitCode -ne 0) 
        { 
            $errorMessage = $error[0].Exception.Message	 
            throw "Installation failed on configure: $errorMessage" 
        } 

        if ($PollingTentacle)
        {
            Write-OctopusSuccess "Configuring the polling tentacle"
            & $tentacleExe configure --instance $clonedInstanceName --nolisten $true --console 
            if ($lastExitCode -ne 0) 
            { 
                $errorMessage = $error[0].Exception.Message	 
                throw "Installation failed on configure: $errorMessage" 
            }   
        }
        else
        {
            Write-OctopusSuccess "Configuring the listening port"
            & $tentacleExe configure --instance $clonedInstanceName --port $tentacleListenPort --nolisten $false --console 
            if ($lastExitCode -ne 0) 
            { 
                $errorMessage = $error[0].Exception.Message	 
                throw "Installation failed on configure: $errorMessage" 
            }  
            
            & "netsh" advfirewall firewall add rule "name=Octopus Deploy Tentacle" dir=in action=allow protocol=TCP localport=$tentacleListenPort
        }

        Write-OctopusSuccess "Creating a certificate for the tentacle"
        & $tentacleExe new-certificate --instance $clonedInstanceName --console 
        if ($lastExitCode -ne 0) 
        { 
            $errorMessage = $error[0].Exception.Message	 
            throw "Installation failed on creating new certificate: $errorMessage" 
        } 

        Write-OctopusSuccess "Trusting the certificate $DestinationOctopusServerThumbprint"
        & $tentacleExe configure --instance $clonedInstanceName --trust $DestinationOctopusServerThumbprint --console
        if ($lastExitCode -ne 0) 
        { 
            $errorMessage = $error[0].Exception.Message	 
            throw "Installation failed on configure: $errorMessage" 
        }

        & $tentacleExe service --instance $clonedInstanceName --install --start --console
        if ($lastExitCode -ne 0) 
        { 
            $errorMessage = $error[0].Exception.Message	 
            throw "Installation failed on service install: $errorMessage" 
        }

        foreach ($rename in $registrationList.RenameList)
        {
            if ($rename.Type -eq "Target")
            {
                $itemToUpdate = Get-OctopusItemById -ItemList $sourceData.TargetList -ItemId $rename.Id
                Write-OctopusVerbose "Renaming $($itemToUpdate.Name) to $($rename.NewName) and disabling the target"
                $itemToUpdate.Name = $rename.NewName
                $itemToUpdate.IsDisabled = $true

                Save-OctopusTarget -target $itemToUpdate -destinationData $sourceData
            }

            if ($rename.Type -eq "Worker")
            {
                $itemToUpdate = Get-OctopusItemById -ItemList $sourceData.WorkerList -ItemId $rename.Id
                Write-OctopusVerbose "Renaming $($itemToUpdate.Name) to $($rename.NewName) and disabling the worker"
                $itemToUpdate.Name = $rename.NewName
                $itemToUpdate.IsDisabled = $true

                Save-OctopusWorker -worker $itemToUpdate -destinationData $sourceData
            }
        }

        foreach ($argument in $registrationList.RegistrationList)
        {            
            Write-Host $argument.ArgumentList

	        & $tentacleExe $argument.ArgumentList
        }
    }
    catch 
    {
        Write-OctopusCritical "There was an exception cloning the tentacle, deleting the new tentacle instance"   
        Write-OctopusSuccess $_
	    & $tentacleExe delete-instance --instance $clonedInstanceName
        Throw "There was an error cloning the tentacle, the new tentacle instance was deleted."
    }
     
}

function New-SanitizedRegistrationName
{
    param
    (
        $name
    )

    $sanitizedRegistrationName = $name.Replace(", ", "")
    $sanitizedRegistrationName = $sanitizedRegistrationName.Replace("\\", "")
    $sanitizedRegistrationName = $sanitizedRegistrationName.Replace("/", "")

    return $sanitizedRegistrationName
}

$tentacleExe = [System.IO.Path]::Combine($TentacleInstallDirectory, "Tentacle")

$currentTentacleInformation = (& $tentacleExe show-configuration --instance="$TentacleInstanceNameToCopy") | Out-String | ConvertFrom-Json
Write-OctopusSuccess "Found current tentacle with a thumbprint of $($currentTentacleInformation.Tentacle.CertificateThumbprint), the nolisten set to $($currentTentacleInformation.Tentacle.Services.NoListen) and port set to $($currentTentacleInformation.Tentacle.Services.PortNumber)"

$clonedTentaclesAreListening = Get-ClonedTentacleIsListening -existingTentacle $currentTentacleInformation -ClonedTentacleType $ClonedTentacleType
if ([string]::IsNullOrWhiteSpace($ExpectedSourceTentacleType) -eq $false)
{
    if ($ExpectedSourceTentacleType -eq "Polling" -and $clonedTentaclesAreListening -eq $true)
    {
        Write-OctopusSuccess "The expected tentacle type was polling but the specified tentacle instance $TentacleInstanceNameToCopy is a listening tentacle.  Exiting."
        exit 0
    }

    if ($ExpectedSourceTentacleType -eq "Listening" -and $clonedTentaclesAreListening -eq $false)
    {
        Write-OctopusSuccess "The expected tentacle type was listening but the specified tentacle instance $TentacleInstanceNameToCopy is a polling tentacle.  Exiting."
        exit 0
    }
}

Write-OctopusSuccess "Loading up source data"
$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName -loadTargetInformationOnly $true -whatif $whatIf

$targetRegistrationList = New-OctopusTargetRegistration -sourceData $sourceData -currentTentacleInformation $currentTentacleInformation
$workerRegistrationList = New-OctopusWorkerRegistration -sourceData $sourceData -currentTentacleInformation $currentTentacleInformation

if ($clonedTentaclesAreListening)
{    
    Write-OctopusSuccess "The cloned tentacle will be a listening tentacle, this script will create one new instance and do multiple registrations of that instance"
    if ($null -ne $ClonedListeningPort)
    {
        $tentacleListenPort = $ClonedListeningPort
    }
    else
    {
        $tentacleListenPort = Get-OctopusListeningPortNumber -tentacleExe $tentacleExe    
    }
    
    $tentacleDirectory = Get-TentacleDirectories -ClonedInstanceName $ClonedInstanceName
    $Hostname = Get-ServerHostNameForListeningTentacleRegistration -targetRegistrationList $targetRegistrationList -workerRegistrationList $workerRegistrationList -DestinationOctopusUrl $DestinationOctopusUrl

    $registrationList = @{
        RegistrationList = @()
        RenameList = @()
    }

    foreach ($target in $targetRegistrationList.MatchingRegistrations)
    {
        $registrationArguments = @{
            ArgumentList = New-OctopusRegistrationArguments -newInstanceName $ClonedInstanceName -DestinationOctopusUrl $DestinationOctopusUrl -DestinationOctopusApiKey $DestinationOctopusApiKey -DestinationSpaceName $DestinationSpaceName -listeningTentacle $true -Hostname $Hostname -IsTarget $true -machineRegistration $target
        }
        
        $registrationList.RegistrationList += $registrationArguments
        
        if ($SourceOctopusUrl.ToLower().Trim() -eq $DestinationOctopusUrl.ToLower().Trim() -and $SourceSpaceName.ToLower().Trim() -eq $DestinationSpaceName.ToLower().Trim())
        {
            $registrationList.RenameList += @{
                Type="Target"
                Id = $target.Id
                OldName = $target.MachineName
                NewName = "$($target.MachineName)_Old"
            }
        }
    }

    foreach ($worker in $workerRegistrationList.MatchingRegistrations)
    {
        $registrationArguments = @{
            ArgumentList = New-OctopusRegistrationArguments -newInstanceName $ClonedInstanceName -DestinationOctopusUrl $DestinationOctopusUrl -DestinationOctopusApiKey $DestinationOctopusApiKey -DestinationSpaceName $DestinationSpaceName -listeningTentacle $true -Hostname $Hostname -IsTarget $false -machineRegistration $worker
        }
        
        $registrationList.RegistrationList += $registrationArguments

        if ($SourceOctopusUrl.ToLower().Trim() -eq $DestinationOctopusUrl.ToLower().Trim() -and $SourceSpaceName.ToLower().Trim() -eq $DestinationSpaceName.ToLower().Trim())
        {
            $registrationList.RenameList += @{
                Type="Worker"
                Id = $worker.Id
                OldName = $worker.MachineName
                NewName = "$($worker.MachineName)_Old"
            }
        }
    }

    if ($WhatIf -eq $false)
    {
        New-TentacleInstance -PollingTentacle $false -ClonedInstanceName $ClonedInstanceName -tentacleDirectory $tentacleDirectory -tentacleExe $tentacleExe -tentacleListenPort $tentacleListenPort -DestinationOctopusServerThumbprint $DestinationOctopusServerThumbprint -registrationList $registrationList -sourceData $sourceData
    }
    else
    {
        Write-OctopusSuccess "What if is set to true.  I would have created a new listening tentacle with the instance name $ClonedInstanceName and the port $tentacleListenPort and registered it $($registrationList.ArgumentList.Count) times as either a target or a worker"
        Write-Host ($tentacleDirectory | ConvertTo-Json)
        foreach ($argument in $registrationList.RegistrationList.ArgumentList)
        {
            Write-Host $argument
        }

        if ($registrationList.RenameList.Count -gt 0)
        {
            Write-OctopusSuccess "I also would have renamed the existing tentacle registrations:"
            foreach ($rename in $registrationList.RenameList)
            {
                Write-OctopusSuccess "$($rename.Id) $($rename.OldName) -> $($rename.NewName)"
            }
        }
    }
}
else
{
    Write-OctopusSuccess "The cloned tentacle will be a polling tentacle, this script will create a unique polling tentacle for each matching registration it found on the source server.  Unlike listening tentacles, polling tentacles can only be associated with one target or one worker."

    foreach ($target in $targetRegistrationList.MatchingRegistrations)
    {
        $sanitizedRegistrationName = New-SanitizedRegistrationName -name $target.MachineName
        $instanceName = "$($clonedInstanceName)_$($sanitizedRegistrationName)"
        $tentacleDirectory = Get-TentacleDirectories -ClonedInstanceName $instanceName

        $registrationList = @{
            RegistrationList = @(
                @{
                    ArgumentList = New-OctopusRegistrationArguments -newInstanceName $instanceName -DestinationOctopusUrl $DestinationOctopusUrl -DestinationOctopusApiKey $DestinationOctopusApiKey -DestinationSpaceName $DestinationSpaceName -listeningTentacle $false -Hostname $null -IsTarget $true -machineRegistration $target
                }
            )
            RenameList = @()
        }
        
        if ($SourceOctopusUrl.ToLower().Trim() -eq $DestinationOctopusUrl.ToLower().Trim() -and $SourceSpaceName.ToLower().Trim() -eq $DestinationSpaceName.ToLower().Trim())
        {
            $registrationList.RenameList += @{
                Type="Target"
                Id = $target.Id
                OldName = $target.MachineName
                NewName = "$($target.MachineName)_Old"
            }
        }

        if ($WhatIf -eq $false)
        {
            New-TentacleInstance -PollingTentacle $true -ClonedInstanceName $instanceName -tentacleDirectory $tentacleDirectory -tentacleExe $tentacleExe -tentacleListenPort $null -DestinationOctopusServerThumbprint $DestinationOctopusServerThumbprint -registrationList $registrationList -sourceData $sourceData
        }
        else
        {
            Write-OctopusSuccess "What if is set to true.  I would have created a new polling tentacle with the instance name $instanceName and registered it as a target"            
            Write-Host $registrationList.RegistrationList[0].ArgumentList
            Write-Host ($tentacleDirectory | ConvertTo-Json)

            if ($registrationList.RenameList.Count -gt 0)
            {
                Write-OctopusSuccess "I also would have renamed the existing tentacle registrations:"
                foreach ($rename in $registrationList.RenameList)
                {
                    Write-OctopusSuccess "$($rename.Id) $($rename.OldName) -> $($rename.NewName)"
                }
            }
        }
    }

    foreach ($worker in $workerRegistrationList.MatchingRegistrations)
    {
        $sanitizedRegistrationName = New-SanitizedRegistrationName -name $worker.MachineName
        $instanceName = "$($clonedInstanceName)_$($sanitizedRegistrationName)"
        $tentacleDirectory = Get-TentacleDirectories -ClonedInstanceName $instanceName

        $registrationList = @{
            RegistrationList = @(
                @{
                    ArgumentList = New-OctopusRegistrationArguments -newInstanceName $instanceName -DestinationOctopusUrl $DestinationOctopusUrl -DestinationOctopusApiKey $DestinationOctopusApiKey -DestinationSpaceName $DestinationSpaceName -listeningTentacle $false -Hostname $null -IsTarget $false -machineRegistration $worker
                }
            )
            RenameList = @()
        }
        
        if ($SourceOctopusUrl.ToLower().Trim() -eq $DestinationOctopusUrl.ToLower().Trim() -and $SourceSpaceName.ToLower().Trim() -eq $DestinationSpaceName.ToLower().Trim())
        {
            $registrationList.RenameList += @{
                Type="Worker"
                Id = $worker.Id
                OldName = $worker.MachineName
                NewName = "$($worker.MachineName)_Old"
            }
        }

        if ($WhatIf -eq $false)
        {
           New-TentacleInstance -PollingTentacle $true -ClonedInstanceName $instanceName -tentacleDirectory $tentacleDirectory -tentacleExe $tentacleExe -tentacleListenPort $null -DestinationOctopusServerThumbprint $DestinationOctopusServerThumbprint -registrationList $registrationList -sourceData $sourceData
        }
        else
        {
            Write-OctopusSuccess "What if is set to true.  I would have created a new polling tentacle with the instance name $instanceName and registered it as a worker"
            Write-Host $registrationList.RegistrationList[0].ArgumentList
            Write-Host ($tentacleDirectory | ConvertTo-Json)

            if ($registrationList.RenameList.Count -gt 0)
            {
                Write-OctopusSuccess "I also would have renamed the existing tentacle registrations:"
                foreach ($rename in $registrationList.RenameList)
                {
                    Write-OctopusSuccess "$($rename.Id) $($rename.OldName) -> $($rename.NewName)"
                }
            }
        }
    }
}
