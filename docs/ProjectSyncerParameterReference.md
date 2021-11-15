# ProjectSyncer.ps1 Parameter Reference

The script `CloneSpace.ps1` accepts the following parameters.

## Source Information
- `SourceOctopusUrl`: the base URL of the source Octopus Server.  For example, https://samples.octopus.app.  This can be the same as the destination.
- `SourceOctopusApiKey`: the API key to access the source Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  That service account user must have read permissions.
- `SourceSpaceName`: the name of the space you wish to copy from.

## Items To Clone

All the items to clone parameters allow for the following filters:
- `all`: special keyword which will clone everything
- Wildcards: use AWS* to pull in all items starting with AWS
- Specific item names: pass in specific item names to clone that item and only that item

You can provide a comma-separated list of items.  For example, setting the `VariableSetsToClone` to "AWS*,Global,Notification" will clone all variable sets which start with AWS, along with the global and notification variable sets.  

You must specify items to clone.  By default, nothing is cloned.  If you wish to skip an item, you can exclude it from the parameter list OR set the value to an empty string "".  

- `RunbooksToClone`: The list of runbooks in the projects to clone.  This defaults to `all`.

## Parent / Child Projects
- `ParentProjectName`: The name of the project to clone.  This has to match exactly one project in the source space.  If this is specified, the regular project cloner process is skipped.
- `ChildProjectsToSync`: The list of projects to sync the deployment process with.   This parameter uses the same wild card matching as the other filters.  Can match to 1 to N number of projects.

## Scoping Match Options

Imagine if your source instance had the environments `Development` and `Test` while the destination only had `Production`.  You have a step scoped to only run on `Development`.  When that step is cloned over what should it do?

You can have variables, deployment process steps, or infrastructure items (workers, accounts, targets), scoped to a variety of items.  The scope matching options tell the space cloner how to handle when a mismatch like this occurs.  The options are:

- `ErrorUnlessExactMatch`: An **Error** will be thrown unless an exact match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` AND `Test`.
- `SkipUnlessExactMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless an exact match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` AND `Test`.
- `ErrorUnlessPartialMatch`: An **Error** will be thrown unless a partial match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` OR `Test`.
- `SkipUnlessPartialMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless a partial match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` OR `Test`.
- `IgnoreMismatch`: The item will be cloned regardless of matching.
- `IgnoreMismatchOnNewLeaveExistingAlone`: The item will be cloned when it is new and scoping doesn't match.  Otherwise it will leave that already exists alone.

The process scoping parameters are:
- `ProcessEnvironmentScopingMatch`: How to handle when a step in a deployment or runbook process is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `ProcessChannelScopingMatch`: How to handle when a step in a deployment or runbook process is scoped to to 1 to N Channels in the source but not all Channels are in the destination.  Default is `SkipUnlessPartialMatch`.
- `ProcessTenantTagsScopingMatch`: How to handle when a step in a deployment or runbook process is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.

The variable scoping parameters are:
- `VariableChannelScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Channels in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableEnvironmentScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableProcessOwnerScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment or Runbooks in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableActionScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment Steps in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableMachineScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment Targets in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableTenantTagsScopingMatch`: How to handle when a step in a project or library variabe set is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableAccountScopingMatch`: How to handle when a variable in a project or library variable set is scoped to an Account in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableCertificateScopingMatch`: How to handle when a variable in a project or library variable set is scoped to an Certificate in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.

See more how this works in the [How Scope Cloning Works Documentation](HowScopeCloningWorks.md).

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingVariables`: Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.  Options are `true`, `false`, or `AddNewWithDefaultValue`. See how [Variable Matching Works](HowVariableMatchingWorks.md)
- `CloneProjectChannelRules`: Indicates if the project channel rules should be cloned and overwrite existing channel rules.  The default is `false`.
- `CloneProjectDeploymentProcess`: Indicates if the project deployment process should be cloned.  Set this to `false` to only clone project runbooks.  The default is `true`.
- `CloneProjectRunbooks`: Indicates if project runbooks should be cloned.  Set this to `false` to only clone the project deployment process.  The defaults is `true`.
- `CloneProjectVersioningReleaseCreationSettings`: Indicates if the release versioning strategy and release creation strategy should be cloned.  The default is `false`.
- `ProcessCloningOption`: Tells the cloner how to handle the situation where steps are in a destination runbook or deployment process but not in the source.  Options are `KeepAdditionalDestinationSteps` or `SourceOnly`.  The default is `KeepAdditionalDestinationSteps`.