# TODO: set variables
$studentName = "richard"
$rgName = "$studentName-lc0820-ps-rg"
$vmName = "$studentName-lc0820-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn" -o tsv
$vmAdminUsername = "student"
$vmAdminPassword = "LaunchCode-@zure1"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# Set default location for Azure
echo "Set default location for Azure"
az configure --default location=eastus

# TODO: provision RG
echo "TODO: provision RG"
az group create -n $rgName
az configure --default group=$rgName


# TODO: provision VM
echo "TODO: provision VM"
$vmData = az vm create -n $vmName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password $vmAdminPassword --authentication-type password --assign-identity | ConvertFrom-Json


# TODO: capture the VM systemAssignedIdentity
echo "TODO: capture the VM systemAssignedIdentity"
$vmIp = $vmData.publicIpAddress 

echo "Setting created VM as the default VM for further config..."
az configure --default vm=$vmName

# TODO: open vm port 443
echo "TODO: open vm port 443"
az vm open-port --port 443


# provision KV
echo "provision KV"
az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true


# TODO: create KV secret (database connection string)
echo "TODO: create KV secret (database connection string)"
az keyvault secret set --vault-name $kvName --description 'connection string' --name $kvSecretName --value $kvSecretValue


# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
echo "TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)"
az keyvault set-policy --name $kvName --object-id $vmData.identity.systemAssignedIdentity --secret-permissions list get

echo "Run config script 1"
az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

echo "Run config script 2"
az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

echo "Run config script 3"
az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file
echo "Virtual machine is available at $vmData.ip"