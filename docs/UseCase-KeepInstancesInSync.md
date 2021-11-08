# Use Case: keeping instances in sync

It is not recommended, but we have seen companies split their projects across multiple Octopus Deploy instances, one for dev/test and another for staging/production.  Keeping the processes in sync between the instances can be a massive pain.  That also means the targets, workers, and connection strings are very different.

In other cases, there are two Octopus Deploy instances; they are mirror images of one another, except they deploy to different data centers.  Just like with Dev/Test and Staging/Prod split, that means the targets, workers, and connection strings are very different.

These are the use cases the space cloner was designed for.  However, it wasn't designed to determine all project dependencies (environments, variable sets, lifecycles, etc).

Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

# Gotchas
The process does not attempt to walk a tree of dependencies.  It loads up all the necessary data from the source and destination.  When it comes across an ID in the source space, it will attempt to find the corresponding ID in the destination space.  If it cannot find a matching item, it removes that binding.  

# Example - Initial Clone

For the initial clone, I would leverage the [Project Export/Import Feature](https://octopus.com/docs/projects/export-import) this copy everything (including sensitive variables) over to another instance.  

This should be done once; after that, the space cloner should be used or subsequent projects and changes.  

# Example - Dev/Test Instance and Staging/Prod instance

This example will clone a specific project, but it will exclude all environments, accounts, external feeds, tenants, and lifecycles, as those differences will likely be differences between the two instances.  

Please refer to the [Parameter reference page](CloneSpaceParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `True` so the step templates are kept in sync. You might have made some recent changes to the step template.  It is important to keep them up to date.  
- `OverwriteExistingLifecyclesPhases` - Set to `false` as the two instances will have different phases.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `false` as you'll want to exclude the release creation settings.
- `CloneProjectDeploymentProcess` - set to `true` as you'll want to include the project deployment process.
- `CloneProjectRunbooks` - set to `true` as you'll want to include the project runbooks.
- `CloneTenantVariables` - set to `true` as you'll want to include the tenant variables.

The scoping options are:
- `ProcessEnvironmentScopingMatch` - set to `SkipUnlessExactMatch` in case you might have steps scoped to `Dev` or `Test` 
- `ProcessChannelScopingMatch` - set to `SkipUnlessPartialMatch` because you might have similar channels but not an exact 1:1 match.
- `VariableChannelScopingMatch` - set to `SkipUnlessPartialMatch` because you might have similar channels but not an exact 1:1 match
- `VariableEnvironmentScopingMatch` - set to `SkipUnlessExactMatch` in case you might have steps scoped to `Dev` or `Test` 
- `VariableProcessOwnerScopingMatch` - set to `SkipUnlessPartialMatch` because you might have runbooks in your source instance not in the destination instances
- `VariableActionScopingMatch` - set to `SkipUnlessPartialMatch` because you might have deployment process steps in your source instance not in the destination instances
- `VariableMachineScopingMatch` - set to `SkipUnlessExactMatch` because will no machines will be shared between the two instances.
- `VariableAccountScopingMatch` - set to `SkipUnlessExactMatch` because you might have different accounts in your source or destination.
- `VariableCertificateScopingMatch` - set to `SkipUnlessExactMatch` because you might have different certificates in your source or destination.
- `InfrastructureEnvironmentScopingMatch` - set to `SkipUnlessExactMatch` in case you might have steps scoped to `Dev` or `Test` 
- `InfrastructureTenantScopingMatch` - set to `SkipUnlessPartialMatch` because you might have similar tenants but not an exact 1:1 match.

Deployment Process Option:
- `ProcessCloningOption` - Leave it as the default `KeepAdditionalDestinationSteps` unless you plan on having no differences between the instances and you want the source instance to be your truth center.  If the source instance is the truth center then set it to `SourceOnly`.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.yoursite.com" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpace Name "My Space Name" `
    -WorkerPoolsToClone "AWS*" `
    -ProjectGroupsToClone "all" `
    -TenantTagsToClone "all" `
    -StepTemplatesToClone "all" `
    -ScriptModulesToClone "all" `
    -MachinePoliciesToClone "all" `
    -SpaceTeamsToClone "all" `
    -LibraryVariableSetsToClone "AWS*,Global,Notification,SQL Server" `
    -ProjectsToClone "Redgate - Feature Branch Example" `
    -PackagesToClone "Redgate.*" `
    -CertificatesToClone "MyCert::CertPassword,OtherCertName::OtherCertPassword" `
    -OverwriteExistingVariables "false" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "false" `
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectVersioningReleaseCreationSettings "true" `
    -CloneProjectRunbooks "true" `
    -CloneTenantVariables "true" `
    -CloneProjectDeploymentProcess "true"
    -ProcessEnvironmentScopingMatch "SkipUnlessExactMatch" `
    -ProcessChannelScopingMatch "SkipUnlessPartialMatch" `
    -VariableChannelScopingMatch "SkipUnlessPartialMatch" `
    -VariableEnvironmentScopingMatch "SkipUnlessExactMatch" `
    -VariableProcessOwnerScopingMatch "SkipUnlessPartialMatch" `
    -VariableActionScopingMatch "SkipUnlessPartialMatch" `
    -VariableMachineScopingMatch "SkipUnlessExactMatch" `
    -VariableAccountScopingMatch "SkipUnlessExactMatch" `
    -VariableCertificateScopingMatch "SkipUnlessExactMatch" `
    -InfrastructureEnvironmentScopingMatch "SkipUnlessExactMatch" `
    -InfrastructureTenantScopingMatch "SkipUnlessPartialMatch" `
    -ProcessCloningOption "KeepAdditionalDestinationSteps" `
```

# Example - Mirrored Instances

This example will clone a specific project between a mirrored instance.

Please refer to the [Parameter reference page](CloneSpaceParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `True` so the step templates are kept in sync. You might have made some recent changes to the step template.  It is important to keep them up to date.  
- `OverwriteExistingLifecyclesPhases` - Set to `false` as the two instances will have different phases.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `true` as you'll want to include the release creation settings.
- `CloneProjectDeploymentProcess` - set to `true` as you'll want to include the project deployment process.
- `CloneProjectRunbooks` - set to `true` as you'll want to include the project runbooks.
- `CloneTenantVariables` - set to `true` as you'll want to include the tenant variables.

The scoping options are:
- `ProcessEnvironmentScopingMatch` - set to `SkipUnlessExactMatch` 
- `ProcessChannelScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableChannelScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableEnvironmentScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableProcessOwnerScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableActionScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableMachineScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableAccountScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableCertificateScopingMatch` - set to `SkipUnlessExactMatch`
- `InfrastructureEnvironmentScopingMatch` - set to `SkipUnlessExactMatch` 
- `InfrastructureTenantScopingMatch` - set to `SkipUnlessExactMatch`

Deployment Process Option:
- `ProcessCloningOption` - Set it to `SourceOnly` as the instances are a 1:1 mirror.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.yoursite.com" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "My Space Name" `
    -EnvironmentsToClone "all" `
    -WorkerPoolsToClone "all" `
    -ProjectGroupsToClone "all" `
    -TenantTagsToClone "all" `
    -ExternalFeedsToClone "all" `
    -StepTemplatesToClone "all" `
    -InfrastructureAccountsToClone "all" `
    -MachinePoliciesToClone "all" `
    -LibraryVariableSetsToClone "AWS*,Global,Notification,SQL Server" `
    -LifeCyclesToClone "all" `
    -ProjectsToClone "Redgate - Feature Branch Example" `
    -TenantsToClone "all" `
    -SpaceTeamsToClone "all" `
    -PackagesToClone "Redgate.*" `
    -CertificatesToClone "MyCert::CertPassword,OtherCertName::OtherCertPassword" `
    -OverwriteExistingVariables "false" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "true" `
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectRunbooks "true" `
    -CloneTenantVariables "true" `
    -CloneProjectDeploymentProcess "true"
    -ProcessEnvironmentScopingMatch "SkipUnlessExactMatch" `
    -ProcessChannelScopingMatch "SkipUnlessExactMatch" `
    -VariableChannelScopingMatch "SkipUnlessExactMatch" `
    -VariableEnvironmentScopingMatch "SkipUnlessExactMatch" `
    -VariableProcessOwnerScopingMatch "SkipUnlessExactMatch" `
    -VariableActionScopingMatch "SkipUnlessExactMatch" `
    -VariableMachineScopingMatch "SkipUnlessExactMatch" `
    -VariableAccountScopingMatch "SkipUnlessExactMatch" `
    -VariableCertificateScopingMatch "SkipUnlessExactMatch" `
    -InfrastructureEnvironmentScopingMatch "SkipUnlessExactMatch" `
    -InfrastructureTenantScopingMatch "SkipUnlessExactMatch" `
    -ProcessCloningOption "SourceOnly" `
```

# Example - Main instance with separate production instances

This example will clone a specific project between with a separate production-only instance.

Please refer to the [Parameter reference page](CloneSpaceParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `True` so the step templates are kept in sync. You might have made some recent changes to the step template.  It is important to keep them up to date.  
- `OverwriteExistingLifecyclesPhases` - Set to `false` as the two instances will have different phases.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `true` as you'll want to include the release creation settings.
- `CloneProjectDeploymentProcess` - set to `true` as you'll want to include the project deployment process.
- `CloneProjectRunbooks` - set to `true` as you'll want to include the project runbooks.
- `CloneTenantVariables` - set to `true` as you'll want to include the tenant variables.

The scoping options are:
- `ProcessEnvironmentScopingMatch` - set to `SkipUnlessPartialMatch` 
- `ProcessChannelScopingMatch` - set to `SkipUnlessPartialMatch` 
- `VariableChannelScopingMatch` - set to `SkipUnlessPartialMatch` 
- `VariableEnvironmentScopingMatch` - set to `SkipUnlessPartialMatch` 
- `VariableProcessOwnerScopingMatch` - set to `SkipUnlessPartialMatch` 
- `VariableActionScopingMatch` - set to `SkipUnlessPartialMatch` 
- `VariableMachineScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableAccountScopingMatch` - set to `SkipUnlessExactMatch` 
- `VariableCertificateScopingMatch` - set to `SkipUnlessExactMatch`
- `InfrastructureEnvironmentScopingMatch` - set to `SkipUnlessPartialMatch` 
- `InfrastructureTenantScopingMatch` - set to `SkipUnlessPartialMatch`

Deployment Process Option:
- `ProcessCloningOption` - Set it to `SourceOnly` as the instances are a 1:1 mirror.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.yoursite.com" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "My Space Name" `
    -EnvironmentsToClone "all" `
    -WorkerPoolsToClone "all" `
    -ProjectGroupsToClone "all" `
    -TenantTagsToClone "all" `
    -ExternalFeedsToClone "all" `
    -StepTemplatesToClone "all" `
    -InfrastructureAccountsToClone "all" `
    -MachinePoliciesToClone "all" `
    -LibraryVariableSetsToClone "AWS*,Global,Notification,SQL Server" `
    -LifeCyclesToClone "all" `
    -ProjectsToClone "Redgate - Feature Branch Example" `
    -TenantsToClone "all" `
    -SpaceTeamsToClone "all" `
    -PackagesToClone "Redgate.*" `
    -CertificatesToClone "MyCert::CertPassword,OtherCertName::OtherCertPassword" `
    -OverwriteExistingVariables "false" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "true" `
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectRunbooks "true" `
    -CloneTenantVariables "true" `
    -CloneProjectDeploymentProcess "true"
    -ProcessEnvironmentScopingMatch "SkipUnlessPartialMatch" `
    -ProcessChannelScopingMatch "SkipUnlessPartialMatch" `
    -VariableChannelScopingMatch "SkipUnlessPartialMatch" `
    -VariableEnvironmentScopingMatch "SkipUnlessPartialMatch" `
    -VariableProcessOwnerScopingMatch "SkipUnlessPartialMatch" `
    -VariableActionScopingMatch "SkipUnlessPartialMatch" `
    -VariableMachineScopingMatch "SkipUnlessExactMatch" `
    -VariableAccountScopingMatch "SkipUnlessExactMatch" `
    -VariableCertificateScopingMatch "SkipUnlessExactMatch" `
    -InfrastructureEnvironmentScopingMatch "SkipUnlessPartialMatch" `
    -InfrastructureTenantScopingMatch "SkipUnlessPartialMatch" `
    -ProcessCloningOption "SourceOnly" `
```
