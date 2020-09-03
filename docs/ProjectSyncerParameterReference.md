# ProjectSyncer.ps1 Parameter Reference

The script `CloneSpace.ps1` accepts the following parameters.

## Source Information
- `SourceOctopusUrl` - the base URL of the source Octopus Server.  For example, https://samples.octopus.app.  This can be the same as the destination.
- `SourceOctopusApiKey` - the API key to access the source Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  That service account user must have read permissions.
- `SourceSpaceName` - the name of the space you wish to copy from.

## Items To Clone

All the items to clone parameters allow for the following filters:
- `all` -> special keyword which will clone everything
- Wildcards -> use AWS* to pull in all items starting with AWS
- Specific item names -> pass in specific item names to clone that item and only that item

You can provide a comma-separated list of items.  For example, setting the `VariableSetsToClone` to "AWS*,Global,Notification" will clone all variable sets which start with AWS, along with the global and notification variable sets.  

You must specify items to clone.  By default, nothing is cloned.  If you wish to skip an item, you can exclude it from the parameter list OR set the value to an empty string "".  

- `RunbooksToClone` -  The list of runbooks in the projects to clone.  This defaults to `all`.

## Parent / Child Projects
- `ParentProjectName` - The name of the project to clone.  This has to match exactly one project in the source space.  If this is specified, the regular project cloner process is skipped.
- `ChildProjectsToSync` - The list of projects to sync the deployment process with.   This parameter uses the same wild card matching as the other filters.  Can match to 1 to N number of projects.

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingVariables` - Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.
- `CloneProjectChannelRules` - Indicates if the project channel rules should be cloned and overwrite existing channel rules.  The default is `false`.
- `CloneProjectDeploymentProcess` - Indicates if the project deployment process should be cloned.  Set this to `false` to only clone project runbooks.  The default is `true`.
- `CloneProjectRunbooks` - Indicates if project runbooks should be cloned.  Set this to `false` to only clone the project deployment process.  The defaults is `true`.
- `CloneProjectVersioningReleaseCreationSettings` - Indicates if the release versioning strategy and release creation strategy should be cloned.  The default is `false`.
- `AddAdditionalVariableValuesOnExistingVariableSets` - Indicates a variable on the destination should only have one value.  You would have multiple values if you were scoping variables.  The defaults is `false`.

## AddAdditionalVariableValuesOnExistingVariableSets further detail

On your source space, you have a variable set with the following values:

![](../img/source-space-more-values.png)

On your destination space, you have the same variable set with the following values:

![](../img/destination-less-values.png)

When the variable `AddAdditionalVariableValuesOnExistingVariableSets` is set to `True` it will add that missing value.

When the variable `AddAdditionalVariableValuesOnExistingVariableSets` is set to `False` it will not add that missing value.