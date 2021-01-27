# Use Case: Point a Tentacle to Two Octopus Deploy Instances
A tentacle establishes a two-way trust with an Octopus Deploy server by exchanging certificate thumbprints.  This is a security feature to ensure a tentacle won't accept commands from servers it doesn't trust, nor with the server accept connections from tentacles it doesn't trust.  

There exists use cases where it makes sense to have the same VM registered in multiple spaces or instances.

- Breaking up a large space into several smaller spaces.  Each space has a unique tentancle registration.
- Wanting to set up a test Octopus Deploy instance but reuse the same Development VMs.  Each instance has a unique tentacle registration.
- Migrating from self-hosted to cloud.  The tentacle might be running on a VM with a private IP address.  A new instance needs to be created as a polling tentacle.  

The script `CloneTentacleInstance.ps1` was designed to solve those use cases.  It will go through all the target and worker registrations for the tentacle and clone them for you.

**Please Note**: You must run `CloneTentacleInstance.ps1` as an administrator or sudo or it will not work.  It is calling the `Tentacle.exe` to make changes on your machine.

# Examples

Below are some examples to help you run `CloneTentacleInstance.ps1`.

## Create a new tentacle instance in a new space on the same instance

In this example, the tentacle is being cloned for a new space on the same instance.  It is taking whatever is on the source space and cloning it.  If it is polling tentacle on the source space, it will be a polling tentacle on the destination space.

```PowerShell
    CloneTentacleInstance.ps1 `
        -SourceOctopusUrl "https://myinstance.com" `
        -SourceOctopusApiKey "API KEY" `
        -SourceSpaceName "Default"`
        -DestinationOctopusUrl "https://myinstance.com" `
        -DestinationOctopusApiKey "API KEY" `
        -DestinationSpaceName "Demo" `
        -DestinationOctopusServerThumbprint "THUMBPRINT" `
        -ClonedTentacleType "AsIs"
```

## Clone a listening tentacle as a polling tentacle to a new cloud instance

In this example, the tentacle is being cloned for a new space from a self-hosted instance to a cloud instance.  It is forcing the new tentacle to be a polling tentacle.

```PowerShell
    CloneTentacleInstance.ps1 `
        -SourceOctopusUrl "https://myinstance.com" `
        -SourceOctopusApiKey "API KEY" `
        -SourceSpaceName "Default"`
        -DestinationOctopusUrl "https://yourcloud.octopus.app" `
        -DestinationOctopusApiKey "API KEY" `
        -DestinationSpaceName "Demo" `
        -DestinationOctopusServerThumbprint "THUMBPRINT" `
        -ClonedTentacleType "Polling"
```


## Clone a polling tentacle as a listening tentacle to new instance

In this example, the tentacle is being cloned for a new space from a self-hosted instance to a cloud instance.  It is forcing the new tentacle to be a listening tentacle.

```PowerShell
    CloneTentacleInstance.ps1 `
        -SourceOctopusUrl "https://myinstance.com" `
        -SourceOctopusApiKey "API KEY" `
        -SourceSpaceName "Default" `
        -DestinationOctopusUrl "https://secondinstance" `
        -DestinationOctopusApiKey "API KEY" `
        -DestinationSpaceName "Demo" `
        -DestinationOctopusServerThumbprint "THUMBPRINT" `
        -ClonedTentacleType "Listening"
```
