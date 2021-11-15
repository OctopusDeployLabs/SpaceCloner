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

## Items To Clone

All the items to clone parameters allow for the following filters:
- `all`: special keyword which will clone everything
- Wildcards: use AWS* to pull in all items starting with AWS
- Specific item names: pass in specific item names to clone that item and only that item

You can provide a comma-separated list of items.  For example, setting the `VariableSetsToClone` to "AWS*,Global,Notification" will clone all variable sets which start with AWS, along with the global and notification variable sets.  

You must specify items to clone.  By default, nothing is cloned.  If you wish to skip an item, you can exclude it from the parameter list OR set the value to an empty string "".  

- `EnvironmentsToClone`: The list of environments to clone.  The default is `$null`, nothing will be cloned.
- `ExternalFeedsToClone`: The list of external feeds to clone.  The default is `$null`, nothing will be cloned.
- `InfrastructureAccountsToClone`: The list of accounts feeds to clone.  The default is `$null`, nothing will be cloned.
- `LibraryVariableSetsToClone`: The list of library variable sets to clone. The default is `$null`, nothing will be cloned.
- `LifeCyclesToClone`: The list of lifecycles to clone.  The default is `$null`, nothing will be cloned.
- `MachinePoliciesToClone`: The list of machine policies to clone.  The default is `$null`, nothing will be cloned.
- `PackagesToClone`: The list of packages to clone.  Will only clone the latest version.  Any build information associated with the package will be cloned as well. Big packages will slow down the runtime of this script. The default is `$null`, nothing will be cloned.
- `ProjectGroupsToClone`: The list of project groups to clone.  The default is `$null`, nothing will be cloned.
- `ProjectsToClone`: The list of projects to clone. The default is `$null`, nothing will be cloned.
- `RunbooksToClone`:  The list of runbooks in the projects to clone.  This defaults to `all`.
- `ScriptModulesToClone`: The list of script modules to clone. The default is `$null`, nothing will be cloned.
- `SpaceTeamsToClone`: The list of teams specific to the space to clone.  Will not clone system teams.  Version 2019 or higher required. The default is `$null`, nothing will be cloned.
- `StepTemplatesToClone`: The list of step templates to clone.  The default is `$null`, nothing will be cloned.
- `TargetsToClone`: The list of targets to clone.  Please note, this won't clone any polling tentacles. The default is `$null`, nothing will be cloned.
- `TenantsToClone`: The list of tenants to clone.  The default is `$null`, nothing will be cloned.
- `TenantTagsToClone`: The list of tenant tags to clone.  The default is `$null`, nothing will be cloned.
- `WorkerPoolsToClone`: The list of worker pools to clone.  The default is `$null`, nothing will be cloned.
- `WorkersToClone`: The list of workers to clone.  Please note, this won't clone any polling tentacles. The default is `$null`, nothing will be cloned. 

- `CertificatesToClone`: The list of certificates to clone.  No support for `all` or wildcards.  Format: `[CertificateName1]::[Password01],[CertificateName2]::[Password02]`, for example `MyCert::Password!`.  

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

The infrastructure scoping parameters are:
- `InfrastructureEnvironmentScopingMatch`: How to handle when a Deployment Target or Account is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `InfrastructureTenantScopingMatch`: How to handle when a Deployment Target or Account is scoped to 1 to N Tenants in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableTenantTagsScopingMatch`: How to handle when a Deployment Target or Account is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.

See more how this works in the [how matching works page](HowMatchingWorks.md).

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingCustomStepTemplates`: Indicates if existing custom step templates (not community step templates) should be overwritten.  Useful when you make a change to a step template, you want to move over to another instance.  Defaults to `false`.
- `OverwriteExistingLifecyclesPhases`: Indicates you want to overwrite the phases on existing lifecycles.  This is useful when you have an updated lifecycle you want to be applied another space/instance.  You will want to leave this to false if the destination lifecycle has different phases.  The default is `false`.  You can also send in `NeverCloneLifecyclePhases` which means it will never clone a lifecycle phase ever.  This is useful when you need to have instances with completely separate environments.
- `OverwriteExistingVariables`: Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.  Options are `true`, `false`, or `AddNewWithDefaultValue`. See more how this works in the [how matching works page](HowMatchingWorks.md).
- `CloneProjectChannelRules`: Indicates if the project channel rules should be cloned and overwrite existing channel rules.  The default is `false`.
- `CloneProjectDeploymentProcess`: Indicates if the project deployment process should be cloned.  Set this to `false` to only clone project runbooks.  The default is `true`.
- `CloneProjectRunbooks`: Indicates if project runbooks should be cloned.  Set this to `false` to only clone the project deployment process.  The default is `true`.
- `CloneProjectVersioningReleaseCreationSettings`: Indicates if the release versioning strategy and release creation strategy should be cloned.  The default is `false`.
- `CloneTeamUserRoleScoping`: Indicates if the space teams should have their scoping cloned.  Will use the same teams based on parameter `SpaceTeamsToClone`.  The default is`false`.
- `CloneTenantVariables`: Indicates if tenant variables should be cloned.  The default is`false`.
- `IgnoreVersionCheckResult`: Indicates if the script should ignore version checks rules and proceed with the clone.  This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `SkipPausingWhenIgnoringVersionCheckResult`: When `IgnoreVersionCheckResult` is set to true the script will pause for 20 seconds when it detects a difference to let you cancel.  You can skip that check by setting this to `true`. This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `ProcessCloningOption`: Tells the cloner how to handle the situation where steps are in a destination runbook or deployment process but not in the source.  Options are `KeepAdditionalDestinationSteps` or `SourceOnly`.  The default is `KeepAdditionalDestinationSteps`. See more how this works in the [how matching works page](HowMatchingWorks.md).
- `WhatIf`: Set to `$true` if you want to see everything this script will do without it actually doing the work.  Set to `$false` to have it do the work.  Defaults to `$false`.