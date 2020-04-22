source helper.sh

minikube start --cpus=4 -p cluster-1
CL1IP=$(minikube ip -p cluster-1)

minikube start --cpus=2 -p cluster-2
CL2IP=$(minikube ip -p cluster-2)

mkdir -p ./vault.volume/file
mkdir -p ./vault.volume/logs

docker-compose up -d
sleep 2
vault operator init -status > /dev/null
if [ $? -eq 2 ]; then
vault operator init > keys.txt
fi

#   The exit code reflects the seal status:
#       - 0 - unsealed
#       - 1 - error
#       - 2 - sealed
vault status
if [ $? -eq 2 ]; then
vault operator unseal $(grep -h 'Unseal Key 1' keys.txt | awk '{print $NF}')
vault operator unseal $(grep -h 'Unseal Key 2' keys.txt | awk '{print $NF}')
vault operator unseal $(grep -h 'Unseal Key 3' keys.txt | awk '{print $NF}')
fi
# login
vault login $(grep -h 'Initial Root Token' keys.txt | awk '{print $NF}') > /dev/null
vault audit enable file file_path=/vault/logs/$(date "+%Y%m%d%H%M.%S").log.json
# vault write /sys/license text=$(cat ~/Documents/vault_v2lic.hclic)
