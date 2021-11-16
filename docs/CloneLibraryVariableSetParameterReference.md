# CloneSpace.ps1 Parameter Reference

The script `CloneSpace.ps1` accepts the following parameters.

## Source Information
- `SourceOctopusUrl`: the base URL of the source Octopus Server.  For example, https://samples.octopus.app.  This can be the same as the destination.
- `SourceOctopusApiKey`: the API key to access the source Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  That service account user must have read permissions.
- `SourceSpaceName`: the name of the space you wish to copy from.

## Destination Information
- `DestinationOctopusUrl`: the base URL of the destination Octopus Server. For example, https://codeaperture.octopus.app.  This can be the same as the source.
- `DestinationOctopusApiKey`: the API key to access the destination Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  Recommend that the service account has `Space Manager` permissions.
- `DestinationSpaceName`: the name of the space you wish to copy to.

## Variable Set To Clone
- `SourceVariableSetName`: The name of the source library variable set.
- `DestinationVariableSetName`: The name of the destination library variable set.  The variable set doesn't have to exist, the script will create it.       

## Scoping Match Options

Imagine if your source instance had the environments `Development` and `Test` while the destination only had `Production`.  You have a step scoped to only run on `Development`.  When that step is cloned over what should it do?

You can have variables, deployment process steps, or infrastructure items (workers, accounts, targets), scoped to a variety of items.  The scope matching options tell the space cloner how to handle when a mismatch like this occurs.  The options are:

- `ErrorUnlessExactMatch`: An **Error** will be thrown unless an exact match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` AND `Test`.
- `SkipUnlessExactMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless an exact match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` AND `Test`.
- `ErrorUnlessPartialMatch`: An **Error** will be thrown unless a partial match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` OR `Test`.
- `SkipUnlessPartialMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless a partial match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` OR `Test`.
- `IgnoreMismatch`: The item will be cloned regardless of matching.
- `IgnoreMismatchOnNewLeaveExistingAlone`: The item will be cloned when it is new and scoping doesn't match.  Otherwise it will leave that already exists alone.

The variable scoping parameters are:
- `VariableChannelScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Channels in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableEnvironmentScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableProcessOwnerScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment or Runbooks in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableActionScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment Steps in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableMachineScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment Targets in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableTenantTagsScopingMatch`: How to handle when a step in a project or library variabe set is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableAccountScopingMatch`: How to handle when a variable in a project or library variable set is scoped to an Account in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableCertificateScopingMatch`: How to handle when a variable in a project or library variable set is scoped to an Certificate in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.

See more how this works in the [how matching works page](HowMatchingWorks.md).

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingVariables`: Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.  Options are `true`, `false`, or `AddNewWithDefaultValue`. See more how this works in the [how matching works page](HowMatchingWorks.md).
- `IgnoreVersionCheckResult`: Indicates if the script should ignore version checks rules and proceed with the clone.  This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `SkipPausingWhenIgnoringVersionCheckResult`: When `IgnoreVersionCheckResult` is set to true the script will pause for 20 seconds when it detects a difference to let you cancel.  You can skip that check by setting this to `true`. This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `WhatIf`: Set to `$true` if you want to see everything this script will do without it actually doing the work.  Set to `$false` to have it do the work.  Defaults to `$false`.