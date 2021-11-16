# How Matching Works

A critical piece of functionality for the space cloner is matching data between the source instance and the destination instance.  If you want to use the space cloner, it is highly recommended you understand how the matching logic works.  

## Matching On Name not Id

A environment named `Production` will have different Id in the source and destination instance or space.  Your source instance/space might have `Production` set to `Environments-1` while the destination instance has it set at `Environments-2346`.  Because of this, matching must occur by name, not by ID.  

For the most part, this works without issue.  The majority of the data in each space in each instance is guaranteed to be unique per name.  That includes:

- Infrastructure
    - Accounts
    - Certificates    
    - Environments
    - External Feeds
    - Machine Policies
    - Targets (no polling tentacles)
    - Worker Pools
    - Workers (no polling tentacles)
- Library
    - Build Information
    - Library Variable Sets
    - Lifecycles
    - Packages
    - Script Modules
    - Step Templates (both community and custom step templates)
    - Tenant Tags
- Project Groups
    - Projects
        - Deployment Process Names
        - Runbooks
            - Runbook Process Names        
- Tenants
- Configuration
    - Teams

## Translating data

The majority of functionality provided by the space cloner is translating ids between instance/spaces.  Because names are guaranteed to have uniqueness this translation will work.  

The translation process is:

1. ID `Environments-2` is scoped to a variable
1. Determine the Environment Name associated with that ID using the source Environment list.
1. `Production` is the name associated with that ID.
1. Search the destination Environment list for `Production`
1. `Production` is found, it has the ID of `Environments-550`.

## Handling Missing Data

While names are guaranteed to be unique, there is no guarantee all data will be the same between the source and destination instance/space.  The above matching assumes both the source and destination have `Production`.  What happens when it doesn't?  The short answer is the clone will most likely fail with an error message.  Some data in Octopus Deploy is required while other data is optional.

## Required Data

Below is data that _must_ exist on both instances.  

**Please Note**: while the data has to exist, the details can be very different.  If you had a worker pool called `AWS Worker Pool`, one instance could have 5 EC2 VMs in the US-West-1 region, while another instance could have 3 EC2 VMs in the US-East-2 region.

- Projects
    - Project Group
    - Default Lifecycle
    - Any Referenced Library Variable Sets
    - Any Referenced Script Modules
    - Deployment / Runbook Process Steps
        - Worker Pool (when defined)
        - Execution Container Feed (when using execution containers)
        - Step Template (when step is a step template)
        - Package Feed (when the step references a package)
    - Channels
        - Referenced Lifecycle
- Target Cloner
    - Machine Policy
    - Worker Pool (when the target needs a worker pool)
    - Account (when the target references a account)
- Teams
    - User Role
- Tenants
    - Variables
        - Project
        - Environment
        - Account
        - Certificate
        - Worker Pool
- Workers
    - Machine Policy

**Please Note**: That required data only applies to items you tell it to clone.  For example, if your project has 30 channels and you tell it to clone 5 then the lifecycles referenced by those 5 channels must exist.  The space cloner doesn't care about the remaining 25.

The space cloner will throw an error if it cannot find the required data.

## Expected Different Data

In general, we expect the following data to be very different between spaces/instances.  This data is the very reason why you have multiple instances.

- Tenants
- Projects
- Deployment Targets
- Workers

## Scoping Data

In Octopus Deploy you can scope a number of items such as deployment process steps, variables, or deployment targets to environments, accounts, channels, etc.  Due to a variety of use cases, a significant amount of logic in the space cloner is dedicated to scope cloning.

The most common scoping data is:

- Environments
- Channels
- Tenant Tags

Less common scoping data is:

- Accounts
- Certificates
- Worker Pools
- Roles
- Deployment Process Steps
- Process Owner (runbooks or deployment process)

Scoping is used in a variety on a variety of data.

- Projects
    - Deployment Process:
        - Environments
        - Channels
        - Tenant Tags
    - Runbook Processes:
        - Environments
        - Channels
        - Tenant Tags
    - Variables:
        - Environments
        - Channels
        - Tenant Tags
        - Accounts
        - Certificates
        - Worker Pools
        - Roles
        - Deployment Process Steps
        - Process Owner
- Library
    - Lifecycles:
        - Environments
    - Library Variable Sets:        
        - Environments        
        - Tenant Tags
        - Accounts
        - Certificates
        - Worker Pools
        - Roles        
- Infrastructure
    - Accounts:
        - Environments
        - Tenants
        - Tenant Tags
    - Deployment Targets:
        - Environments
        - Tenants
        - Tenant Tags

### Handling Different Data

We leave it to you via parameters and command line options to control how to handle different data.  The options are:

- `ErrorUnlessExactMatch`: An **Error** will be thrown unless an exact match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` AND `Test`.
- `SkipUnlessExactMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless an exact match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` AND `Test`.
- `ErrorUnlessPartialMatch`: An **Error** will be thrown unless a partial match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` OR `Test`.
- `SkipUnlessPartialMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless a partial match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` OR `Test`.
- `IgnoreMismatch`: The item will be cloned regardless of matching.
- `IgnoreMismatchOnNewLeaveExistingAlone`: The item will be cloned when it is new and scoping doesn't match.  Otherwise it will leave that already exists alone.

The data is:

- Deployment Process Steps (both runbook and deployment process)
    - Environments: Default is `SkipUnlessPartialMatch`
    - Channels: Default is `SkipUnlessPartialMatch`
    - Tenant Tags: Default is `SkipUnlessPartialMatch`
- Variables (both project and library variable set)
    - Environments: Default is `SkipUnlessPartialMatch`
    - Channels: Default is `SkipUnlessPartialMatch`
    - Process Owners (deployment process or runbook): Default is `SkipUnlessPartialMatch`
    - Deployment Process Steps: Default is `SkipUnlessPartialMatch`
    - Deployment Targets: Default is `SkipUnlessPartialMatch`
    - Accounts: Default is `SkipUnlessExactMatch`
    - Certificates: Default is `SkipUnlessExactMatch`
    - Tenant Tags: Default is `SkipUnlessPartialMatch`
- Infrastructure (targets, accounts, and certificates)
    - Environments: Default is `SkipUnlessPartialMatch`
    - Tenants: Default is `SkipUnlessPartialMatch`
    - Tenant Tags: Default is `SkipUnlessPartialMatch`

#### Skip unless exact match example

We will use this variable set as an example:

![variable set example for space cloner](../img/variable-scoping-original.png)

The source has the following environments:

- Development
- Test
- Production

The destination has the following environments:

- Test
- Production

When the variable environment scoping is set to `SkipUnlessExactMatch` the resulting clone will be.  Make note that `Application.Database.Name` only has `Production`.  That is because the other option was scoped to `Development` and `Test`, but the destination didn't have `Development`

![skip unless exact match](../img/skip-unless-exact-match.png)

#### Skip Unless Partial Match Example

Let's re-run that.  But this time we will use `SkipUnlessPartialMatch`.  Again the source is:

![variable set example for space cloner](../img/variable-scoping-original.png)

The source has the following environments:

- Development
- Test
- Production

The destination has the following environments:

- Test
- Production

The result will be the following.  Make that `OctopusPrintVariables` still does not appear in this scenario.  That is because that step is scoped to `Development`.  There is no `Development`, there has to be at least one item for a partial match to occur.  So the variable was skipped.

![skip unless partial match](../img/skip-unless-partial-match.png)

#### Ignore Mismatch

For the final example, we will use `IgnoreMismatch`.  Of all the items this is the most dangerous and can lead to unpredictable results.  Again the source is:

![variable set example for space cloner](../img/variable-scoping-original.png)

The source has the following environments:

- Development
- Test
- Production

The destination has the following environments:

- Test
- Production

The result will be the following.  Make that `OctopusPrintVariables` still does now appears, and it is only scoped to the deployment step.  Because `Development` doesn't exist the cloner is unable to create that scope.

![ignore mismatch](../img/ignore-mismatch.png)

Our recommendation is to leave the defaults as is unless there is a compelling reason to change.

## Variable Matching

The cloner defaults to leaving variables on the destination instance as-is.  **The space cloner will never overwrite a sensitive variable.**

The question then becomes "what exactly is a new variable?"  The space cloner matches variables by comparing:
- Names
- Sensitive Values vs Non Sensitive Values
- Environment Scoping
- Channel Scoping
- Process Scoping
- Machine Scoping
- Step Scoping
- Role Scoping

You can overwrite default behavior by setting `OverwriteExistingVariables` to one of these options:
- `True`: if a match is found then the value will be updated.  **The space cloner will never overwrite a sensitive variable.**
- `False`: Only copies over new items found.  All existing items are left as-is.
- `AddNewWithDefaultValue`: When a new item is found the value is set to `REPLACE ME` instead of the source value.

What makes scope matching tricky is when there are different environments in each instance.  Specifically when one instance is Dev/Test and the other is Stage/Prod.  When the variable scope option matching is set to either `IgnoreMismatch` or `IgnoreMismatchOnNewLeaveExistingAlone` that tells the matching logic to skip that scope option.  For example, if you set the variable environment scope matching parameter to `IgnoreMismatch`, that tells the matching logic to ignore any environment matching.  

For example: imagine on your source instance you had `Dev`, `Test`, and `Production`.  You have a variable value scoped to each environment.

- MyValue.Testing.Awesome
    - Awesome Dev - Scoped to `Development`
    - Awesome Test - Scoped to `Test`
    - Awesome Production - Scoped to `Production`

On the destination instance you had `Prod`.  You set the environment scoping match to `IgnoreMismatch`.  The result is the first item will be picked.

- MyValue.Testing.Awesome
    - Awesome Dev - No Scoping

If you set the `OverwriteExistingVariables` to `AddNewWithDefaultValue` that value will be:

- MyValue.Testing.Awesome
    - REPLACE ME - No Scoping

If you added a new value to the destination manually.

- MyValue.Testing.Awesome
    - REPLACE ME - No Scoping
    - Awesome Prod - Scoped to `Prod`

Any subsequent runs would leave those values as-is.  

## Deployment and Runbook Process Cloning

SpaceCloner assumes that when you clone a deployment process, you want to add missing steps but leave existing steps.

I have a deployment process on my source, where I added a new step.

![](../img/process-source-added-step.png)

My destination deployment process has a new step on the end that is not in the source.

![](../img/destination-deployment-process-before-sync.png)

After the sync is finished, the new step was added, and the additional step was left as is.

![](../img/destination-deployment-process-after-sync.png)

The rules for cloning a deployment process are:

- Clone steps not found in the destination process
- Leave existing steps as is
- The source process is the source of truth for step order.  It will ensure the destination deployment process order matches.  It will then add additional steps found in the deployment process not found in the source to the end of the deployment process.

The parameter, `ProcessCloningOption` controls this.  The options are: 
    - `KeepAdditionalDestinationSteps` - default.  Does the above process.
    - `SourceOnly` - any steps in the destination not on the source to be removed.

### Step Scoping

As you saw above, process steps can be scoped to Environments, Channels and Tenant Tags.  If you have completely separate environments, channels or tenant tags then setting the appropriate command line switch to `IgnoreMismatchOnNewLeaveExistingAlone` will leave all existing scoping as-is.