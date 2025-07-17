<#############
 PowerShell Script to Create Policy Exemptions for Azure Subscriptions
# This script retrieves all policy assignments in all scopes that were assigned by Security Center and creates exemptions

#createby: Idit Bnaya
#createdate: 2025-07-10
################>


# Set the tenant ID (update this value as needed)
$tenantId = ''

# Set the Azure context to the specified tenant
Set-AzContext -Tenant $tenantId

# Get an access token for Azure REST API calls
$token = (az account get-access-token --resource https://management.azure.com | ConvertFrom-Json).accessToken
 
# Get all subscriptions for the tenant
$subscriptions = az account list | ConvertFrom-Json | Where-Object { $_.tenantId -eq $tenantId }

# Loop through each subscription
foreach ($sub in $subscriptions) {
    # Check if the subscription ID is valid
    if (![string]::IsNullOrWhiteSpace($sub.id)) {
        # Generate an exemption name based on the subscription ID
        $exemptionName = "exempt-$($sub.id.Substring(0,4))"
        if (![string]::IsNullOrWhiteSpace($exemptionName)) {
            # Build the exemption request body
            $body = @{
                properties = @{
                    policyAssignmentId = "/subscriptions/$($sub.id)/providers/microsoft.authorization/policyassignments/securitycenterbuiltin"
                    policyDefinitionReferenceIds = @(
                        "windowsDefenderExploitGuardMonitoring",
                        "identityDesignateLessThanOwnersMonitoring",
                    )
                    exemptionCategory = "Mitigated"
                    displayName = "Autoexempt-$($sub.name)"
                    resourceSelectors = @()
                }
            } | ConvertTo-Json

            # Check if the 'securitycenterbuiltin' policy assignment exists for the subscription
            $assignment = az policy assignment show --name securitycenterbuiltin --scope /subscriptions/$($sub.id)
           
            # If assignment exists, create/update the policy exemption
            if ($assignment) {
                $url = "https://management.azure.com/subscriptions/$($sub.id)/providers/Microsoft.Authorization/policyExemptions/$exemptionName" + "?api-version=2022-07-01-preview"
                Write-Host "sub.id: $($sub.id)"
                Write-Host "exemptionName: $exemptionName"
                Write-Host "URL: $url"
                Write-Host "Calling: $url"
                Invoke-RestMethod -Method Put -Uri $url -Body $body -ContentType "application/json" -Headers @{Authorization = "Bearer $token"}
                # ...existing exemption code...
            } else {
                Write-Host "No 'securitycenterbuiltin' assignment found for subscription $($sub.id)"
            }
        }
        else {
            Write-Host "Skipping due to empty exemptionName for subscription $($sub.id)"
        }
    } else {
        Write-Host "No assignment found for subscription $($sub.id)"
    }
}
# End of script
# This script retrieves all policy assignments in all scopes that were assigned by Security Center and creates exemptions