# Logging

All runs generate two fresh logs.  All information written to the host is written to the log.

- CleanUpLog -> A log of items indicating what you will need to clean up
- Log -> The verbose log of the clone

The logs will be placed in the logs\[date of run] folder.  The script will create that folder automatically.

# Debugging

This is a script manipulating data and then calling an API; it is possible it will send a bad JSON body up to the API.  

All JSON requests are stored in the log.  For example:

```
Going to invoke POST https://code-aperture.octopus.app/api/Spaces-104/Environments with the following body
{
    "Id":  null,
    "Name":  "Test",
    "Description":  "",
    "SortOrder":  1,
    "UseGuidedFailure":  false,
    "AllowDynamicInfrastructure":  false,
    "SpaceId":  "Spaces-104",
    "ExtensionSettings":  [
                              {
                                  "ExtensionId":  "issuetracker-jira",
                                  "Values":  {

                                             }
                              }
                          ],
    "Links":  {
                  "Self":  "/api/Spaces-106/environments/Environments-111",
                  "Machines":  "/api/Spaces-106/environments/Environments-111/machines{?skip,take,partialName,roles,isDisabled,healthStatuses,commStyles,tenantIds,tenantTags,shellNames}",
                  "SinglyScopedVariableDetails":  "/api/Spaces-106/environments/Environments-111/singlyScopedVariableDetails",
                  "Metadata":  "/api/Spaces-106/environments/Environments-111/metadata"
              }
}
```

You can copy that body and URL into Postman to manipulate until it works for you.  Once you know the cause, you can update the script to make sure it doesn't happen again.

## Stepping through code

Create a script that will call the space cloner.  For example,

```
    Z:\Code.git\SpaceCloner_Labs\CloneTentacleInstance.ps1 `
        -SourceOctopusUrl "https://myinstance.app" `
        -SourceOctopusApiKey "API-KEY" `
        -SourceSpaceName "Default"`
        -DestinationOctopusUrl "https://myinstance.app" `
        -DestinationOctopusApiKey "API-KEY" `
        -DestinationSpaceName "Demo" `
        -PollingTentacle $true `
        -DestinationOctopusServerThumbprint "B86B3E73924F19E889642A261584593E57765875"
```

Open up the space cloner in Visual Studio code and hit the `F5` key and that will start debugging.  You can add break points and everything else you are used to.