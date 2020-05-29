$currentDate = Get-Date
$currentDateFormatted = $currentDate.ToString("yyyy_MM_dd_HH_mm")

$logFolder = "$PSScriptRoot\..\..\logs\clonerun_$currentDateFormatted" 

if ((Test-Path -Path $logFolder) -eq $false)
{
    New-Item -Path $logFolder -ItemType Directory
}

$logPath = "$logFolder\Log.txt"
$cleanupLogPath = "$logFolder\CleanUp.txt"
$apiResponsesLogPath = "$logFolder\ApiResponses.txt"

function Get-OctopusCleanUpLogPath
{
    return $cleanupLogPath
}

function Get-OctopusLogPath
{
    return $logPath
}

function Get-OctopusApiResponseLogPath
{
    return $apiResponsesLogPath
}

function Write-OctopusVerbose
{
    param($message)
    
    Add-Content -Value $message -Path $logPath    
}

function Write-OctopusSuccess
{
    param($message)

    Write-Host $message -ForegroundColor Green
    Write-OctopusVerbose $message    
}

function Write-OctopusWarning
{
    param($message)

    Write-Host $message -ForegroundColor Yellow    
    Write-OctopusVerbose $message
}

function Write-OctopusCritical
{
    param ($message)

    Write-Host $message -ForegroundColor Red
    Write-OctopusVerbose $message
}

function Write-OctopusPostCloneCleanUp
{
    param($message)
    
    Add-Content -Value "   $message" -Path $cleanupLogPath
}

function Write-OctopusPostCloneCleanUpHeader
{
    param($message)

    Add-Content -Value $message -Path $cleanupLogPath
}