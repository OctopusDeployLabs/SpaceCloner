# Use Case: parent-child projects
It is easy to clone a project in Octopus Deploy.  However, once that is done, keeping the child project's process in sync with the parent project is very painful.  You have to go into each child project and update it manually.  The space cloner script was designed with this use case in mind. 

Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

# Example - Parent / Child Projects Different Space

This example is syncing the parent project in the same space.  

Please refer to the [Parameter reference page](CloneSpaceParameterReference.md) for more details on the parameters.

Options:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.  
- `OverwriteExistingCustomStepTemplates` - Set to `true` as you'll want to make sure you have the latest step templates.
- `OverwriteExistingLifecyclesPhases` - Set to `false` because you've most likely have a unique lifecycle.
- `CloneProjectChannelRules` - set to `false` as the project already exists with its own rules.
- `CloneTeamUserRoleScoping` - set to `false` as you won't want to overwrite team user role scoping.
- `CloneProjectVersioningReleaseCreationSettings` - set to `false` as you'll want to exclude the release creation settings.
- `CloneProjectDeploymentProcess` - set to `true` as you'll want to include the project deployment process.
- `CloneProjectRunbooks` - set to `true` as you'll want to include the project runbooks.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance1.yoursite.com" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "New Space Name" `
    -ParentProjectName "Redgate - Feature Branch Example" `
    -ChildProjectsToSync "Redgate - Child*" `
    -OverwriteExistingVariables "false" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "false" `
    -CloneProjectChannelRules "false" `
    -CloneTeamUserRoleScoping "false" `
    -CloneProjectVersioningReleaseCreationSettings "false" `
    -CloneProjectRunbooks "true" `
    -CloneProjectDeploymentProcess "true"
```

# Example - Parent / Child Projects Same Space

This example is syncing the parent project in the same space.  

Please refer to the [Parameter reference page](ProjectSyncerParameterReference.md) for more details on the parameters.

Options:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added still.  
- `CloneProjectChannelRules` - set to `false` as its the same space in the same instance, and this makes no sense to rune.
- `CloneProjectVersioningReleaseCreationSettings` - set to `false` as you'll want to exclude the release creation settings.
- `CloneProjectDeploymentProcess` - set to `true` as you'll want to include the project deployment process.
- `CloneProjectRunbooks` - set to `true` as you'll want to include the project runbooks.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -ParentProjectName "Redgate - Feature Branch Example" `
    -ChildProjectsToSync "Redgate - Child*" `  
    -OverwriteExistingVariables "false" `
    -CloneProjectChannelRules "false" `
    -CloneProjectVersioningReleaseCreationSettings "false" `
    -CloneProjectRunbooks "true" `
    -CloneProjectDeploymentProcess "true"
```
