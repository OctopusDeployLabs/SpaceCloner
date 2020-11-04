param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,
    $TentacleInstallDirectory,
    $TentacleInstanceNameToCopy,
    $PollingTentacle,
    $CloneTarget,
    $TentaclePortNumber,
    $DestinationOctopusServerThumbprint,
    $ClonedInstanceName
)

. ($PSScriptRoot + ".\src\Core\Logging.ps1")
. ($PSScriptRoot + ".\src\Core\Util.ps1")

. ($PSScriptRoot + ".\src\DataAccess\OctopusDataAdapter.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusDataFactory.ps1")
. ($PSScriptRoot + ".\src\DataAccess\OctopusRepository.ps1")

function Get-MyPublicIPAddress 
{
    # Get Ip Address of Machine 
    $ipAddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip 

    return $ipAddress 
}

if ($null -eq $DestinationOctopusServerThumbprint)
{
    Throw "The parameter DestinationOctopusServerThumbprint is required.  You can get this by going to configuration -> thumbprint in the destination Octopus Deploy instance."
}

if ($null -eq $TentacleInstallDirectory)
{
    $TentacleInstallDirectory = "C:\Program Files\Octopus Deploy\Tentacle"
}

if ($null -eq $TentacleInstanceNameToCopy)
{
    $TentacleInstanceNameToCopy = "Tentacle"
}

if ($null -eq $PollingTentacle)
{
    $PollingTentacle = $true
}

if ($null -eq $CloneTarget)
{
    $CloneTarget = $true
}

if ($null -eq $ClonedInstanceName)
{
    $ClonedInstanceName = "ClonedInstance"
}

if ($null -eq $TentaclePortNumber)
{
    if ($PollingTentacle)
    {
        $TentaclePortNumber = 10943
    }
    else
    {
        $TentaclePortNumber = 10933
    }
}

$ErrorActionPreference = "Stop"

$outputFile = "tentacle-output-file_$currentDateFormatted.txt"
$tentacleExe = "$TentacleInstallDirectory\Tentacle.exe"
& $tentacleExe show-thumbprint --Instance="$TentacleInstanceNameToCopy" --format="JSON" | Out-File $outputFile

$currentTentacleInformation = (Get-Content $outputFile) | ConvertFrom-Json

Write-OctopusSuccess "Found current tentacle with a thumbprint of $($currentTentacleInformation.Thumbprint)"

Write-OctopusSuccess "Loading up source data"
$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName -loadTargetInformationOnly $true

$sourceMachine = $null
$sourceList = $sourceData.TargetList

if ($CloneTarget -eq $false)
{
    $sourceList = $sourceData.WorkerList
}

foreach ($machine in $sourceList)
{
    if (Get-Member -InputObject $machine.Endpoint -Name "Thumbprint" -MemberType Properties)
    {
        if ($machine.Endpoint.Thumbprint -eq $currentTentacleInformation.Thumbprint)
        {
            $sourceMachine = $machine            
            Write-OctopusSuccess "Found the source machine in the source instance. It has the ID of $($sourceMachine.Id)"
            break
        }
    }
}

$ipAddress = $null
if ($sourceMachine.Endpoint.CommunicationStyle -eq "TentaclePassive")
{
    $ipAddress = $sourceMachine.Endpoint.Url -replace "https://", ""
    $ipAddress = ($ipAddress -split ":")[0]
    Write-OctopusSuccess "The IP Address of this machine is $ipAddress"
}

if ($CloneTarget)
{
    $environmentList =  @(Convert-OctopusIdListToNameList -IdList $sourceMachine.EnvironmentIds -itemList $sourceData.EnvironmentList)
    $roleList =  $sourceMachine.Roles 
    $tenantList = @(Convert-OctopusIdListToNameList -IdList $sourceMachine.TenantIds -itemList $sourceData.TenantList)
    $tenantTags = $sourceMachine.TenantTags
    $tenantType = $sourceMachine.TenantedDeploymentParticipation    
}
else
{
    $workerPoolList = @(Convert-OctopusIdListToNameList -IdList $sourceMachine.WorkerPoolIds -itemList $sourceData.WorkerPoolList)
}

$machinePolicyName = $(Get-OctopusItemById -ItemList $sourceData.MachinePolicyList -ItemId $sourceMachine.MachinePolicyId).Name
$machineName = $sourceMachine.Name

$tentacleHomeDirectory = "C:\Octopus\$ClonedInstanceName" 
$tentacleAppDirectory = "C:\Octopus\$ClonedInstanceName\Applications" 
$tentacleConfigFile = "C:\Octopus\$ClonedInstanceName\Tentacle\Tentacle.config"  

try 
{
    Write-OctopusSuccess "Creating the cloned tentacle instance $clonedInstanceName"
	& $tentacleExe create-instance --instance $clonedInstanceName --config $tentacleConfigFile --console 
    if ($lastExitCode -ne 0) 
    { 
	    $errorMessage = $error[0].Exception.Message	 
	    throw "Installation failed on create-instance: $errorMessage" 
	} 
	
	Write-OctopusSuccess "Configuring the home directory"
	& $tentacleExe configure --instance $clonedInstanceName --home $tentacleHomeDirectory --console 
    if ($lastExitCode -ne 0) 
    { 
	    $errorMessage = $error[0].Exception.Message	 
	    throw "Installation failed on configure: $errorMessage" 
	} 
	
	Write-OctopusSuccess "Configuring the app directory"
	& $tentacleExe configure --instance $clonedInstanceName --app $tentacleAppDirectory --console 
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
    }
		
	Write-OctopusSuccess "Creating a certificate for the tentacle"
	& $tentacleExe new-certificate --instance $clonedInstanceName --console 
    if ($lastExitCode -ne 0) 
    { 
	    $errorMessage = $error[0].Exception.Message	 
	    throw "Installation failed on creating new certificate: $errorMessage" 
    } 
    
    Write-OctopusSuccess "Trusting the certificate $octopusServerThumbprint"
	& $tentacleExe configure --instance $clonedInstanceName --trust $DestinationOctopusServerThumbprint --console
    if ($lastExitCode -ne 0) 
    { 
	    $errorMessage = $error[0].Exception.Message	 
	    throw "Installation failed on configure: $errorMessage" 
    }

    $baseArgs = @()

    if ($CloneTarget)
    {
        $baseArgs += "register-with"

        foreach ($role in $roleList) {
            $baseArgs += "--role=$role"
        }
        
        foreach ($env in $environmentList) {
            $baseArgs += "--environment=`"$env`""
        }

        foreach ($tenant in $tenantList) {
            $baseArgs += "--tenant=`"$tenant`""            
        }

        foreach ($tenantTag in $tenantTags) {
            $baseArgs += "--tenanttag=`"$tenantTag`""
        }

        $baseArgs += "--tenanted-deployment-participation=$tenantType"
    }
    else
    {
        $baseArgs += "register-worker"    
        foreach ($workerPool in $workerPoolList) {
            $baseArgs += "--workerpool=`"$workerpool`""
        }
    }

    if ($PollingTentacle)
    {
        $baseArgs += "--server-comms-port=$TentaclePortNumber"    
        $baseArgs += "--comms-style=TentacleActive"
    }
    else
    {
        if ($null -eq $ipAddress)
        {
            Write-OctopusSuccess "You have selected a listening tentacle, but the source tentacle is not listening, attempting to pull the public IP Address"
            $IpAddress = Get-MyPublicIPAddress             
        }

        if ($DestinationOctopusUrl -like "*octopus.app*")
        {
            Write-OctopusCritical "IP address of this machine is $IpAddress.  The destination URL ends in octopus.app, this indicates an Octopus Cloud instance.  There is a high chance that the cloud instance won't be able to see this VM.  Recommend using polling tentacles.  Are you sure you want to proceed?  Going to pause 20 seconds so you can stop this script."
            $versionCheckCountDown = 20
                
            while ($versionCheckCountDown -gt 0)
            {
                Write-OctopusCritical "Seconds left: $versionCheckCountDown"
                Start-Sleep -Seconds 1        
                $versionCheckCountDown -= 1
            }

            Write-OctopusCritical "Someone ate their YOLO flakes this morning, proceeding with registration."
        }

        $baseArgs += "--publicHostName=$ipAddress"    
        $baseArgs += "--comms-style=TentaclePassive"
    }

    $baseArgs += "--instance=$clonedInstanceName"
    $baseArgs += "--server=$DestinationOctopusUrl"
    $baseArgs += "--apiKey=$DestinationOctopusApiKey"
    $baseArgs += "--space=`"$DestinationSpaceName`""
    $baseArgs += "--policy=`"$machinePolicyName`""
    $baseArgs += "--name=`"$machineName`""
    $baseArgs += "--force"
    $baseArgs += "--console"
    
    Write-Host $baseArgs

	& $tentacleExe $baseArgs 
    
    & $tentacleExe service --instance $clonedInstanceName --install --start --console
    if ($lastExitCode -ne 0) 
    { 
	    $errorMessage = $error[0].Exception.Message	 
	    throw "Installation failed on service install: $errorMessage" 
	} 
}
catch 
{
    Write-OctopusCritical "There was an exception cloning the tentacle, deleting the new tentacle instance"   
	& $tentacleExe delete-instance --instance $clonedInstanceName
}
