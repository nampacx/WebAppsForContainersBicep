
$MyResourceGroup = 'rg-webappcontainer-d'
$SubscriptionId = 'a5bcaba6-98a3-411a-88a6-bbe5a5ae97a6'

az account set -s $SubscriptionId
# az group delete -n $MyResourceGroup
az group create --name $MyResourceGroup --location "westeurope"
az deployment group create -g $MyResourceGroup --template-file "../bicep/main.bicep" --parameters "../bicep/param-nginx.json" --mode Incremental