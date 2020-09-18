# CloneSpaceProject.ps1 Parameter Reference

`CloneSpaceProject.ps1` is a script which uses a reverse lookup to determine all the items to clone.  `CloneSpace.ps1` expects you to know all the items (environments, step templates, variable sets, etc.) associated with a project.  `CloneSpaceProject.ps1` was written with the assumption you don't know all the ins and outs of a project.  It will look at the list of projects you provide it and determine what are all the items required for a clone to work.  It will then call the `CloneSpace.ps1` at the end with all the parameters filled out for you.

The script `CloneSpaceProject.ps1` accepts the following parameters.

## Source Information
- `SourceOctopusUrl` - the base URL of the source Octopus Server.  For example, https://samples.octopus.app.  This can be the same as the destination.
- `SourceOctopusApiKey` - the API key to access the source Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  That service account user must have read permissions.
- `SourceSpaceName` - the name of the space you wish to copy from.

## Destination Information
- `DestinationOctopusUrl` - the base URL of the destination Octopus Server. For example, https://codeaperture.octopus.app.  This can be the same as the source.
- `DestinationOctopusApiKey` - the API key to access the destination Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  Recommend that the service account has `Space Manager` permissions.
- `DestinationSpaceName` - the name of the space you wish to copy to.

## Items To Clone

All the items to clone parameters allow for the following filters:
- `all` -> special keyword which will clone everything
- Wildcards -> use AWS* to pull in all items starting with AWS
- Specific item names -> pass in specific item names to clone that item and only that item

You can provide a comma-separated list of items.  For example, setting the `VariableSetsToClone` to "AWS*,Global,Notification" will clone all variable sets which start with AWS, along with the global and notification variable sets.  

You must specify items to clone.  By default, nothing is cloned.  If you wish to skip an item, you can exclude it from the parameter list OR set the value to an empty string "".  

- `ProjectsToClone` - The list of projects to clone.

## Items to Exclude

All the items to exclude parameters allow for the following filters:
- `all` -> special keyword which will clone everything
- Wildcards -> use AWS* to pull in all items starting with AWS
- Specific item names -> pass in specific item names to clone that item and only that item

- `EnvironmentsToExclude` - The list of environments to exclude from this clone
- `WorkersToExclude` - The list of workers to exclude from this clone
- `TargetsToExclude` - The list of targets to exclude from this clone
- `TenantsToExclude` - The list of tenants to exclude from this clone

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingCustomStepTemplates` - Indicates if existing custom step templates (not community step templates) should be overwritten.  Useful when you make a change to a step template, you want to move over to another instance.  Defaults to `false`.
- `OverwriteExistingLifecyclesPhases` - Indicates you want to overwrite the phases on existing lifecycles.  This is useful when you have an updated lifecycle you want to be applied another space/instance.  You will want to leave this to false if the destination lifecycle has different phases.  The default is `false`.
- `OverwriteExistingVariables` - Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.
- `CloneProjectChannelRules` - Indicates if the project channel rules should be cloned and overwrite existing channel rules.  The default is `false`.
- `CloneProjectDeploymentProcess` - Indicates if the project deployment process should be cloned.  Set this to `false` to only clone project runbooks.  The default is `true`.
- `CloneProjectRunbooks` - Indicates if project runbooks should be cloned.  Set this to `false` to only clone the project deployment process.  The default is `true`.
- `CloneProjectVersioningReleaseCreationSettings` - Indicates if the same versioning rules will be applied to the project.  The default is `false`.
- `CloneTeamUserRoleScoping` - Indicates if the space teams should have their scoping cloned.  Will use the same teams based on parameter `SpaceTeamsToClone`.  The default is`false`.
- `AddAdditionalVariableValuesOnExistingVariableSets` - Indicates a variable on the destination should only have one value.  You would have multiple values if you were scoping variables.  The default is `false`.
- `IgnoreVersionCheckResult` - Indicates if the script should ignore version checks rules and proceed with the clone.  This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `SkipPausingWhenIgnoringVersionCheckResult` - When `IgnoreVersionCheckResult` is set to true the script will pause for 20 seconds when it detects a difference to let you cancel.  You can skip that check by setting this to `true`. This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.

## AddAdditionalVariableValuesOnExistingVariableSets further detail

On your source space, you have a variable set with the following values:

![](../img/source-space-more-values.png)

On your destination space, you have the same variable set with the following values:

![](../img/destination-less-values.png)

When the variable `AddAdditionalVariableValuesOnExistingVariableSets` is set to `True` it will add that missing value.

When the variable `AddAdditionalVariableValuesOnExistingVariableSets` is set to `False` it will not add that missing value.