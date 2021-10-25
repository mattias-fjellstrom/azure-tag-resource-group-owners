param scriptUri string
param utcValue string = utcNow('yyyy-MM-ddT23:59:00')

var namePostfix = uniqueString(resourceGroup().id)
var psModuleBaseUrl = 'https://psg-prod-eastus.azureedge.net/packages'
var psModules = {
  'Az.Accounts': '${psModuleBaseUrl}/az.accounts.2.5.3.nupkg'
  'Az.Monitor': '${psModuleBaseUrl}/az.monitor.2.7.0.nupkg'
  'Az.Resources': '${psModuleBaseUrl}/az.resources.4.3.1.nupkg'
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: 'automation-${namePostfix}'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Free'
    }
  }

  resource azAccountsModule 'modules' = {
    name: 'Az.Accounts'
    properties: {
      contentLink: {
        uri: psModules['Az.Accounts']
      }
    }
  }

  resource azMonitorModule 'modules' = {
    name: 'Az.Monitor'
    dependsOn: [
      automationAccount::azAccountsModule
    ]
    properties: {
      contentLink: {
        uri: psModules['Az.Monitor']
      }
    }
  }

  resource azResourcesModule 'modules' = {
    name: 'Az.Resources'
    dependsOn: [
      automationAccount::azAccountsModule
    ]
    properties: {
      contentLink: {
        uri: psModules['Az.Resources']
      }
    }
  }

  resource schedule 'schedules' = {
    name: 'OncePerDay'
    properties: {
      interval: 1
      frequency: 'Day'
      startTime: utcValue
    }
  }

  resource runbook 'runbooks@2019-06-01' = {
    name: 'add-owner-tags-to-resource-groups'
    location: resourceGroup().location
    properties: {
      description: 'Set the Owner tag to the name of the creator for resource groups'
      runbookType: 'PowerShell'
      logProgress: true
      logVerbose: true
      publishContentLink: {
        version: '1.0.0.0'
        uri: scriptUri
      }
    }
  }

  resource jobSchedule 'jobSchedules' = {
    name: '${guid(resourceGroup().id, 'triggerScriptEveryDay')}'
    properties: {
      runbook: {
        name: automationAccount::runbook.name
      }
      schedule: {
        name: automationAccount::schedule.name
      }
    }
  }
}

output principalId string = automationAccount.identity.principalId
