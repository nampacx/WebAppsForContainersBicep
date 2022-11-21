
$MyResourceGroup = 'rg-webappcontainer-rbac'
$SubscriptionId = ''

az account set -s $SubscriptionId
# az group delete -n $MyResourceGroup
az group create --name $MyResourceGroup --location "westeurope"
az deployment group create -g $MyResourceGroup --template-file "../bicep/main.bicep" --parameters "../bicep/param-nginx.json" --mode Incremental