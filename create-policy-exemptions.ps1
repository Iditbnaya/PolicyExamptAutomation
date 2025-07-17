$tenantId = ''
Set-AzContext -Tenant $tenantId
$token = (az account get-access-token --resource https://management.azure.com | ConvertFrom-Json).accessToken
 
$subscriptions = az account list | ConvertFrom-Json | Where-Object { $_.tenantId -eq $tenantId }
foreach ($sub in $subscriptions) {
    if (![string]::IsNullOrWhiteSpace($sub.id)) {
        $exemptionName = "exempt-$($sub.id.Substring(0,4))"
        if (![string]::IsNullOrWhiteSpace($exemptionName)) {
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
            $assignment = az policy assignment show --name securitycenterbuiltin --scope /subscriptions/$($sub.id)
           
          #  az policy assignment show --name securitycenterbuiltin --scope "/subscriptions/3df24de0-89d4-45e0-a067-c806473ff034"
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

This email and the information contained herein is proprietary and confidential and subject to the Amdocs Email Terms of Service, which you may review at https://www.amdocs.com/about/email-terms-of-service
