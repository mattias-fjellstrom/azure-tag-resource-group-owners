targetScope = 'subscription'

param deploymentDateTime string = utcNow()

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-automation-${uniqueString(deployment().name)}'
  location: deployment().location
}

module scriptStorage 'scriptStorage.bicep' = {
  name: '${deploymentDateTime}-script-storage-deployment'
  scope: rg
}

module automation 'automation.bicep' = {
  name: '${deploymentDateTime}-automation-deployment'
  scope: rg
  dependsOn: [
    scriptStorage
  ]
  params: {
    scriptUri: scriptStorage.outputs.scriptUri
  }
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#tag-contributor
var tagContributorRoleId = '4a9ae827-6dc8-4573-8ac7-8239d42aa03f'
resource tagContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().id, 'tagContributor')
  scope: subscription()
  properties: {
    principalId: automation.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', tagContributorRoleId)
  }
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#monitoring-reader
var monitorReaderRoleId = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
resource monitorReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().id, 'activityLogReader')
  scope: subscription()
  properties: {
    principalId: automation.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitorReaderRoleId)
  }
}
