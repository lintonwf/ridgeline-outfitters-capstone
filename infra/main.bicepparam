using './main.bicep'

param location = 'westus3'
param appName = 'ridgeline'
param environment = 'prod'
param regionCode = 'wus3'
param ownerName = 'LintonFeitosa'
param costCenter = 'RO-IT-001'
param projectName = 'CPTR445-Capstone'
param sqlAdminLogin = 'ridgelineadmin'
// Supply password securely via CLI (--parameters sqlAdminPassword=...) or Key Vault reference
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD')
param appVersion = 'v0.2.0'
