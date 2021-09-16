<# Ensures you do not inherit an AzContext in your runbook #>
Disable-AzContextAutosave -Scope Process | Out-Null;

<# Connect using a Managed Service Identity #>

Connect-AzAccount -Identity;

<# 
    Perform the work:
    1. Fetch activity log entries for the past 24 hours (limits to at most 10000 logs)
    2. Filter out logs for creation of resource groups
    3. Select resource group id and the name of who created the group
    4. Filter our unique combinations of group id and creator name
    5. Update the tags on each resource group
#>
Get-AzLog -MaxRecord 10000 -StartTime (Get-Date).AddDays(-1) |
Where-Object {$_.Authorization.Action -like "Microsoft.Resources/subscriptions/resourceGroups/write"} |
Select-Object @{N="ResourceGroupID"; E={$_.Authorization.Scope}}, @{N="OwnerName"; E={$_.Claims.Content.name}} |
Get-Unique -AsString |
ForEach-Object -Process { Update-AzTag -ResourceId $_.ResourceGroupID -Tag @{"Owner"="$($_.OwnerName)"} -Operation Merge -ErrorAction SilentlyContinue }