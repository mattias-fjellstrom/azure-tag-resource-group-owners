param utcValue string = utcNow()

var filename = '${utcValue}.ps1'
var namePostfix = uniqueString(resourceGroup().id)

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'st${namePostfix}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource blobService 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: 'scripts'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

resource uploadScriptToBlobStorage 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'blobUpload${utcValue}'
  location: resourceGroup().location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: stg.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: stg.listKeys().keys[0].value
      }
      {
        name: 'FILE_CONTENT'
        value: loadTextContent('../script/tagResourceGroups.ps1')
      }
    ]
    scriptContent: 'echo $FILE_CONTENT > ${filename} && az storage blob upload -f ${filename} -c ${stg::blobService::container.name} -n ${filename}'
  }
}

output scriptUri string = '${stg.properties.primaryEndpoints.blob}${stg::blobService::container.name}/${filename}'
