# How Variable Matching Works

The cloner defaults to leaving variables on the destination instance as-is.  **The space cloner will never overwrite a sensitive variable.**

The question then becomes "what exactly is a new variable?"



On your source space you have the variable `Testing.Variable` and it is set to `Test`.  On the destination instance that same variable exists and it is set to `Super Test`.  By default the cloner will leave the value on the destination instance as `Super Test`.  To update that value to match the source you will have to set the parameter `OverwriteExistingVariables` to `$true`.  

**The default for the paramter `OverwriteExistingVariables` is `$false`.**  

The space cloner matches variables by comparing:
- Names
- Sensitive Values vs Non Sensitive Values
- Environment Scoping
- Channel Scoping
- Process Scoping
- Machine Scoping
- Step Scoping
- Role Scoping

If you add a scope, the space cloner will see that as a new variable value and add it.  Same is true for changing from sensitive to non-sensitive or vice versa.