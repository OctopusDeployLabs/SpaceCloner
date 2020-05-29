# Sensitive Variables

The script accesses the Octopus API.  As such, it cannot access your sensitive variables.  However, we need to save _something_ into that data.

Here is a break down of all the areas where the script will insert dummy data.  Every one of these replacements is logged in `CleanUpLog.txt` to make them easier to find.

- Variables
    - Library Variable Sets -> Set sensitive variables to `Dummy Value`
    - Project Variables -> Set sensitive variables to `Dummy Value`
    - Process which uses a step template with sensitive variables. -> Set value to `Dummy Value`.
- Feeds
    - All usernames and passwords are cleared
- Accounts
    - Azure Accounts: 
        - SubscriptionNumber = New-Guid
        - ClientId = New-Guid
        - TenantId = New-Guid        
        - Key = "DUMMY VALUE DUMMY VALUE"  
    - AWS Accounts:
        - AccessKey = "AKIABCDEFGHI3456789A"        
        - SecretKey = "DUMMY VALUE DUMMY VALUE"    
    - Token Accounts:
        - Token = "DUMMY VALUE"
    - SSH Accounts:
        - PFX File: uploads a dummy file with the word "test" in it.

These dummy values are only _inserted_ on POST or creation.  All existing items on the destination space are left as is.
    