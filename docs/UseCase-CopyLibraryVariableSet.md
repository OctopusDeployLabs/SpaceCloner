# Use Case: Copy a Library Variable Set

Octopus Deploy makes it easy to copy a project or projects.  However, there might be a need for each project/project group to have its own variable set.  It is now possible to create a new variable set from existing variable set in the same space.

## Gotchas
Because this is hitting the Octopus Restful API, it cannot decrypt items from the Octopus Database.  To decrypt items from the Octopus database, you'll need access to the master key and the database.  This script was designed to run on an Octopus Cloud instance.  You, the user, do not have access to that information.  

Please see the [sensitive variables page](SensitiveVariables.md) for more information on the script handles sensitive variables.

# Example - CloneLibraryVariableSet.ps1
This example will clone a library variable in the same space in the same instance.  

Please refer to the [Parameter reference page](CloneLibraryVariableSetParameterReference.md) for more details on the parameters.

- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `false` so any new values (specifically around scoping) are not added.  

```PowerShell
CloneLibraryVariableSet.ps1 -SourceOctopusUrl "https://samples.octopus.app" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "Target - SQL Server" `
    -DestinationOctopusUrl "https://samples.octopus.app" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "Target - SQL Server" `
    -SourceVariableSetName "Notification" `
    -DestinationVariableSetName "Notification_New" `
    -OverwriteExistingVariables "false" `
    -AddAdditionalVariableValuesOnExistingVariableSets "False" `    
```