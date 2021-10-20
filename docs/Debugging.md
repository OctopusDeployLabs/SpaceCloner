# Logging

All runs generate three fresh logs.  All information written to the host is written to the log.

- CleanUpLog -> A log of items indicating what you will need to clean up
- Log -> The verbose log of the clone
- ChangeLog -> A summary of all the changes the space cloner will do (when in what if mode) or has done (when in write mode)

The logs will be placed in the root folder.  Each time the space cloner runs it will copy the logs in the root folder to `logs\archive_[date of run]` folder and start fresh.

# Debugging

This is a script manipulating data and then calling an API; when something goes wrong it is important to know why.

## Parameters

The current version of the space cloner and all parameters sent in are logged at the top of the `log.txt` file.  

```
Using version 2.1.4 of the cloner.
The clone parameters sent in are:
{
  "OverwriteExistingLifecyclesPhases": true,
  "ScriptModulesToClone": null,
  "StepTemplatesToClone": null,
  "ChildProjectsToSync": null,
  "TargetsToClone": null,
  "CloneProjectDeploymentProcess": true,
  "TenantTagsToClone": "all",
  "WorkerPoolsToClone": null,
  "InfrastructureAccountsToClone": null,
  "MachinePoliciesToClone": null,
  "TenantsToClone": "all",
  "RunbooksToClone": "all",
  "ProjectGroupsToClone": null,
  "CloneProjectChannelRules": true,
  "CloneProjectRunbooks": true,
  "CloneTeamUserRoleScoping": true,
  "CloneProjectVersioningReleaseCreationSettings": true,
  "OverwriteExistingVariables": false,
  "WorkersToClone": null,
  "SpaceTeamsToClone": null,
  "PackagesToClone": null,
  "LifeCyclesToClone": null,
  "ExternalFeedsToClone": null,
  "CertificatesToClone": "OctopusDemos.app::MyKey!!!!",
  "ParentProjectName": null,
  "OverwriteExistingCustomStepTemplates": true,
  "LibraryVariableSetsToClone": null,
  "EnvironmentsToClone": "all",
  "CloneTenantVariables": true,
  "ProjectsToClone": null
}
```

## Comparisons and Conversions
The majority of the heavy lifting done by the space cloner is to translate the source ids into destination ids.  For example, **Production** is `Environments-123` on the source, but `Environments-234` on the destination.  The cloner converts `Environments-123` into `Environments-234` before saving it on the destination.

You'll see a lot of log messages similar to this:

```
Converting id list with 3 item(s) over to destination space
Getting Name of Environments-504
Attempting to find Environments-504 in the item list of 3 item(s)
Checking to see if Environments-504 matches with Environments-504
The Ids match, return the item Development
The name of Environments-504 is Development, attempting to find in destination list
The destination id for Development is Environments-241
Getting Name of Environments-505
Attempting to find Environments-505 in the item list of 3 item(s)
Checking to see if Environments-504 matches with Environments-505
Checking to see if Environments-505 matches with Environments-505
The Ids match, return the item Test
The name of Environments-505 is Test, attempting to find in destination list
The destination id for Test is Environments-242
Getting Name of Environments-506
Attempting to find Environments-506 in the item list of 3 item(s)
Checking to see if Environments-504 matches with Environments-506
Checking to see if Environments-505 matches with Environments-506
Checking to see if Environments-506 matches with Environments-506
The Ids match, return the item Production
The name of Environments-506 is Production, attempting to find in destination list
The destination id for Production is Environments-243
```

What you don't want to see is a message similar to this.  When you see that, that is most likely the culprit behind any 400 bad request errors.

```
Getting Name of ProjectGroups-1
Attempting to find ProjectGroups-1 in the item list of 60 item(s)
Checking to see if ProjectGroups-203 matches with ProjectGroups-1
Checking to see if ProjectGroups-745 matches with ProjectGroups-1
Checking to see if ProjectGroups-41 matches with ProjectGroups-1
Checking to see if ProjectGroups-61 matches with ProjectGroups-1
Checking to see if ProjectGroups-101 matches with ProjectGroups-1
Checking to see if ProjectGroups-262 matches with ProjectGroups-1
Checking to see if ProjectGroups-381 matches with ProjectGroups-1
Checking to see if ProjectGroups-603 matches with ProjectGroups-1
Checking to see if ProjectGroups-241 matches with ProjectGroups-1
Checking to see if ProjectGroups-684 matches with ProjectGroups-1
Checking to see if ProjectGroups-221 matches with ProjectGroups-1
Checking to see if ProjectGroups-882 matches with ProjectGroups-1
Checking to see if ProjectGroups-181 matches with ProjectGroups-1
Checking to see if ProjectGroups-441 matches with ProjectGroups-1
Checking to see if ProjectGroups-804 matches with ProjectGroups-1
Checking to see if ProjectGroups-261 matches with ProjectGroups-1
Checking to see if ProjectGroups-463 matches with ProjectGroups-1
Checking to see if ProjectGroups-484 matches with ProjectGroups-1
Checking to see if ProjectGroups-483 matches with ProjectGroups-1
Checking to see if ProjectGroups-881 matches with ProjectGroups-1
Checking to see if ProjectGroups-143 matches with ProjectGroups-1
Checking to see if ProjectGroups-401 matches with ProjectGroups-1
Checking to see if ProjectGroups-743 matches with ProjectGroups-1
Checking to see if ProjectGroups-682 matches with ProjectGroups-1
Checking to see if ProjectGroups-121 matches with ProjectGroups-1
Checking to see if ProjectGroups-681 matches with ProjectGroups-1
Checking to see if ProjectGroups-1 matches with ProjectGroups-1
The Ids match, return the item DEFAULT
The name of ProjectGroups-1 is DEFAULT, attempting to find in destination list
Unable to find DEFAULT in the destination list
```

## API Requests
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
