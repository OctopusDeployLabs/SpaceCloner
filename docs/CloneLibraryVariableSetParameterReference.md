# CloneSpace.ps1 Parameter Reference

The script `CloneSpace.ps1` accepts the following parameters.

## Source Information
- `SourceOctopusUrl` - the base URL of the source Octopus Server.  For example, https://samples.octopus.app.  This can be the same as the destination.
- `SourceOctopusApiKey` - the API key to access the source Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  That service account user must have read permissions.
- `SourceSpaceName` - the name of the space you wish to copy from.

## Destination Information
- `DestinationOctopusUrl` - the base URL of the destination Octopus Server. For example, https://codeaperture.octopus.app.  This can be the same as the source.
- `DestinationOctopusApiKey` - the API key to access the destination Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  Recommend that the service account has `Space Manager` permissions.
- `DestinationSpaceName` - the name of the space you wish to copy to.

## Variable Set To Clone
- `SourceVariableSetName` - The name of the source library variable set.
- `DestinationVariableSetName` - The name of the destination library variable set.  The variable set doesn't have to exist, the script will create it.        

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingVariables` - Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.
- `IgnoreVersionCheckResult` - Indicates if the script should ignore version checks rules and proceed with the clone.  This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `SkipPausingWhenIgnoringVersionCheckResult` - When `IgnoreVersionCheckResult` is set to true the script will pause for 20 seconds when it detects a difference to let you cancel.  You can skip that check by setting this to `true`. This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `WhatIf` - Set to `$true` if you want to see everything this script will do without it actually doing the work.  Set to `$false` to have it do the work.  Defaults to `$false`.