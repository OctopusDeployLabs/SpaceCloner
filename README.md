# Space Cloner
Sample PowerShell script to help you clone a space using the Octopus Deploy Restful API.

# This cloning process is provided as is
This script was developed internally for the Customer Success team at Octopus Deploy to solve specific use cases we encounter each day.  We are sharing this script to help other users of Octopus Deploy.  To cover as many use cases as we run into as possible, the script has a set of generic comparisons in place.  It matches by name, order is tracked via a simple index, etc.  We work in Octopus all day every day.  As such, we are okay with a script that accomplishes 80-90% of a clone, and then spending a bit of time doing some manual work.  

It would be impossible for us to write a script such as this to match your hyper-specific use.  For example, you might store a number of your variables in a key store, with Octopus storing the credentials.  You could update the script so when it comes across a specific variable name the credentials are inserted into the variable value instead of pulling from the source instance.

 This repository is [licensed](license) under the MIT license.  You are free to fork the repo and add whatever feature you wish.  Think of this script as a starting point in your process.  We encourage you to fork it, test it out on an empty space or empty instance, look at the results and modify the script to meet your needs.  It is possible for the script to work for your use cases without modification.

# Use cases
This script was written for the following use cases.

- As a user, I want to split my one massive default space into [multiple spaces on the same instance](docs/UseCase-BreakUpSpace.md).
- As a user, I have two Octopus Deploy instances.  One for dev/test deployments.  Another for staging/prod deployments.  I have the [same set of projects I want to keep in sync](docs/UseCase-KeepInstancesInSync.md).
- As a user, I want to clone a set of projects to a test instance to [verify an upgrade](docs/UseCase-CopyToTestInstance.md).
- As a user, I have a set of "parent" projects.  I clone from that project when I need to create a new project.  However, when the process on the "parent" project is updated, I would like to [update the existing "child" projects](docs/UseCase-ParentChildProjects.md).
- As a user, I would like to copy my projects from [self-hosted Octopus to Octopus Cloud](docs/UseCase-MigrateFromSelfHostedToCloud.md).

## Possible but not recommended

- As a user, I want to merge multiple Octopus Deploy instances into the same space on a new instance.  That scenario, merging multiple disparate instances into one massive space, is not recommended.  The chance of overwriting something meaningful is very high.  Just like steering a car with your knees, while possible, it is not recommended.

# How the space cloner workers
Please see the [how it works page](docs/HowItWorks.md).

# Sensitive variables
Please see the page [sensitive variables](docs/SensitiveVariables.md) to see how sensitive variables are handled.

# Debugging and logging
Please see the [debugging and logging page](docs/Debugging.md).

# Reference
Please see [parameter reference page](docs/ParameterReference.md).

# Examples
Please see the [example page](docs/Examples.md).

# FAQ
Below are questions and answers to common questions we've gotten about this project.

### Why was this script created?
The Customer Success at Octopus Deploy team developed this script.  We use it to clone items for our [samples instance](https://samples.octopus.app).

### Will you fix my bug?  
Sorry, but no.  This repository is under the Octopus Samples organization instead of Octopus Deploy.  Issues are not monitored.  This script is meant as a starting point for your process.  This repository is [licensed](license) under the MIT license.  You are free to fork the repo and fix your specific issue.  

### What about feature requests?
No.  We won't accept feature requests for the script.  This repository is [licensed](license) under the MIT license.  You are free to fork the repo and add whatever feature you wish.  The Customer Success team plans on keeping this script up to date with the latest version of Octopus Deploy.  If you do fork this repo, you might want to keep up to date on the latest changes.

### Do you accept pull requests?
Yes!  If you want to improve this script, please submit a pull request!

### Can I use this to migrate from self-hosted to the cloud?
Yes.  However, this script is not a full migration.  It will jump-start your migration.  This script hits the API, meaning it won't have access to your sensitive variables.  See the [how it works](docs/HowItWorks.md) page for details on what it will and won't clone.  

### Is this the space migration / self-hosted to Octopus Cloud migrator tool that has been teased in the past?
No.  It was designed for specific use cases, and the limits placed on it were intentional.  For example, it can't access your Master Key, and without that, it cannot decrypt your sensitive data.  It should get you 80-90% of the way there.  You are free to fork this repo to modify the scripts to help get you another 5% of the way there.  

### What version of Octopus Deploy does this script support?
It _should_ work with any Octopus version `3.4` or higher.  It was developed by testing against a version running `2020.x`.  You will notice some version checks being run in the script.  This is to prevent the script from calling specific API endpoints when it shouldn't.

### Can I use this script to migrate from 2018.10 to 2020.2?
No.  The script compares the major and minor versions of the source and destination.  

**Unless the source and destination [major].[minor] versions are the same; the script will not proceed.**

### What permissions should the users tied to the API keys have?
For the source instance, a user with read-only permissions to all objects copied is required.  It will never write anything back to the source.

For the destination instance, we recommend a user with `Space Manager` or higher.  You can go through and lock down permissions as you see fit, but `Space Manager` will get you going.

### Can I use this in an Octopus Deploy runbook?
Yes!  It is a PowerShell script.  It calls the APIs, so you should be fine in using it in an Octopus Deploy runbook.

### Why doesn't this script create the destination space?
Honestly, it's a security concern.  There are two built-in roles that provide the space create permission, `System Manager` and `System Administrator`.  We recommend using the API key of a [service account user](https://octopus.com/docs/security/users-and-teams/service-accounts) when running the script.  That service account user would either need to be added to `Octopus Managers` or `Octopus Administrators` teams.  That user would also have permissions to create users and update other settings on your instance.  We want you to feel comfortable using the script as-is.  Requiring elevated permissions is a concern, and it isn't something we felt good about asking our users to do.

Yes, you can create a custom role and assign the service account user to that role.  The goal of this script is it should "just work" with a minimal amount of configuration on your end.  Once you start diving into permissions and custom roles, it is going to be much harder to get working.  

### Does the script clone users, teams, and roles?

This script does _**NOT**_ clone users, roles, or system teams.  You can tell it to clone space-specific teams only. 

When it attempts to set up scoping for a team, it will see if the role exists on the destination; if the role does not exist on the destination instance the scoping will be skipped.  

Teams that are created have the external groups cleared.  

In other words, the clone team functionality will only assign existing users and roles to space teams.  It will not attempt to create anything new, which might compromise your security.  