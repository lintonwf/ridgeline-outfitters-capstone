targetScope = 'resourceGroup'

@description('Resource naming suffix')
param suffix string

@description('Exact built-in Azure Policy definition ID (SEC-8)')
param policyDefinitionId string

@description('Required tag name enforced by Azure Policy (SEC-8)')
param requiredTagName string = 'CostCenter'

// SEC-8: Enforce required CostCenter tag on all resources in the resource group
resource requireCostCenterTagPolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: take('pol-req-tag-${suffix}', 24)
  properties: {
    displayName: 'SEC-8: Require ${requiredTagName} tag on resources'
    description: 'Enforces ARC-9 tagging standard by requiring the ${requiredTagName} tag on resources.'
    policyDefinitionId: policyDefinitionId
    enforcementMode: 'Default'
    parameters: {
      tagName: {
        value: requiredTagName
      }
    }
  }
}

output policyAssignmentId string = requireCostCenterTagPolicy.id
output policyAssignmentName string = requireCostCenterTagPolicy.name
