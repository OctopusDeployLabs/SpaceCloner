# Contributing Guidelines

We are happy to accept pull requests for this repository.  For a pull request to be approved the following guidelines must be followed:

- Have the CLA signed (you will be prompted to sign one when you create your PR)
- All new code follows the same structure as existing code.
    - SpaceCloner - the entry script, it controls the order of which items are cloned.
    - [Feature]Cloner - The cloning logic for a specific feature.  Should have a entry function at the top that accepts `$sourceData`, `$destinationData`, and `$cloneScriptOptions` as parameters. 
    - OctopusDataAdapter - adapter providing low level access to the Octopus API.
    - OctopusDataFactory - The factory which builds the source and destination data.  
    - OctopusRepository - Repository contains method to pull data by using the Octopus Data Adapter.
- Code standards
    - Functions use [approved verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7).
    - Changes are well structured and easy to read.    
    - Plenty of logging for future debugging.  No direct writing to the host, leverage the functions found in `Logging.ps1`.
    - No direct access from a Cloner(s) to the OctopusDataAdapter.  Everything should go through the OctopusRepository.
    - Minimal duplicate code.