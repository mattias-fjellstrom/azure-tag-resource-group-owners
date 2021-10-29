# Automatically tag Azure resource groups with the name of who created it

This example demonstrates how you can automatically tag resource groups with the name and username of who created it using data available from the activity log. The tag applied to each resource group has the format:

```json
{
  "Key": "Owner",
  "Value": "Jane Doe"
},
{
  "Key": "Username",
  "Value": "janedoe"
}
```

The infrastructure consists of an automation account with a PowerShell runbook. The automation account has a system-assigned managed identity that is provided with two RBAC roles, [Tag Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#tag-contributor) and [Monitoring Reader](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#monitoring-reader). The PowerShell script is uploaded to a storage account as a publicly available blob and the automation runbook is created from this blob. Three PowerShell modules are installed into the automation account, [Az.Accounts](https://docs.microsoft.com/en-us/powershell/module/az.accounts/?view=azps-6.4.0), [Az.Monitor](https://docs.microsoft.com/en-us/powershell/module/az.monitor/?view=azps-6.4.0), and [Az.Resources](https://docs.microsoft.com/en-us/powershell/module/az.resources/?view=azps-6.4.0). These modules are required to run the script. A schedule is set up to run the automation runbook once per day, specifically at 23:59 UTC each day.

### Why do I want to use this solution?

If you have a subscription where many teams are working the number of resource groups will quickly increase. This is a way to keep track of who creates resource groups to simplify administration tasks.

### Why not use Azure Policy?

An alternative would be to use an Azure Policy to require that new resource groups set the Owner tag, however there is no way to enforce that reasonable values are provided as the value to this tag.

### Why not use an Azure Function?

Using an Azure function that is triggered on events from Event Grid is a valid alternative to this solution, especially if you require the tag to appear as soon as the resource group is created. Use the solution in this repository for less critical scenarios where bulk-tagging once per day is sufficient.

## Prerequisites

- Azure CLI ([install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Azure Bicep CLI (install with `az bicep install`)
- Set default subscription with `az account set --subscription <name or id>`
- You should be Owner of the subscription that you use because you will add role-assignments at the subscription scope

## Create Azure resources

Deploy `main.bicep` to the subscription scope.

```bash
az deployment sub create \
    --name <deployment name, e.g. my-deployment> \
    --template-file ./bicep/main.bicep \
    --location <azure location, e.g. northeurope>
```

A resource group with a name starting with `rg-automation-` is created where all resources are collected.

```bash
rgName=$(az group list --query "[?starts_with(name, 'rg-automation-')].name" -o tsv)
az group show --name $rgName
```

If you repeat the deployment the script will be uploaded with a different name and the runbook will be updated to use the new script. This allows you to make local changes to the PowerShell script and reapply it to the runbook by deploying the Bicep template again.

## Delete Azure resources

```bash
rgName=$(az group list --query "[?starts_with(name, 'rg-automation-')].name" -o tsv)
az lock delete --name resource-group-lock --resource-group $rgName
az group delete --name $rgName --yes --no-wait
```

## Limitations

To access the name of who created a resource group we must look at data from the activity log. The script is restricted to look at the previous 24 hours of data. This means that old resource groups will not be tagged. You could manually modify and run this script to include a longer time span.
