# Clone Space Script Examples
This script was written to solve the following use cases.  Please pick the use case which matches your scenario.

- As a user, I want to split my one massive default space into [multiple spaces on the same instance](UseCase-BreakUpSpace.md).
- As a user, I have two Octopus Deploy instances.  One for dev/test deployments.  Another for staging/prod deployments.  I have the [same set of projects I want to keep in sync](UseCase-KeepInstancesInSync.md).
- As a user, I want to clone a set of projects to a test instance to [verify an upgrade](UseCase-CopyToTestInstance.md).
- As a user, I have a set of "parent" projects.  I clone from that project when I need to create a new project.  However, when the process on the "parent" project is updated, I would like to [update the existing "child" projects](UseCase-ParentChildProjects.md).
- As a user, I would like to copy my projects from [self-hosted Octopus to Octopus Cloud](UseCase-MigrateFromSelfHostedToCloud.md).

## Possible but not recommended.

- As a user, I want to merge multiple Octopus Deploy instances into the same space on a new instance.  That scenario, merging multiple disparate instances into one massive space, is not recommended.  The chance of overwriting something meaningful is very high.  Just like steering a car with your knees, while possible, it is not recommended.