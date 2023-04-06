source helper.sh

minikube start --cpus=4 -p cluster-1 #--vm=true --driver=hyperkit
minikube -p cluster-1 addons enable metrics-server
CL1IP=$(minikube ip -p cluster-1)

vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200 &

####
# TODO: docker-compose is not working. disabling it until I can make it work.
####

# mkdir -p ./vault.volume/file
# mkdir -p ./vault.volume/logs
# docker-compose up -d

# while ! curl $VAULT_ADDR/sys/health -s --show-error; do
#   echo "Waiting for Vault to be ready"
#   sleep 2
# done

# vault operator init -status > /dev/null
# if [ $? -eq 2 ]; then
# vault operator init > keys.txt
# fi

# #   The exit code reflects the seal status:
# #       - 0 - unsealed
# #       - 1 - error
# #       - 2 - sealed
# vault status
# if [ $? -eq 2 ]; then
# vault operator unseal $(grep -h 'Unseal Key 1' keys.txt | awk '{print $NF}')
# vault operator unseal $(grep -h 'Unseal Key 2' keys.txt | awk '{print $NF}')
# vault operator unseal $(grep -h 'Unseal Key 3' keys.txt | awk '{print $NF}')
# fi
# # login
# vault login $(grep -h 'Initial Root Token' keys.txt | awk '{print $NF}') > /dev/null
# vault audit enable file file_path=/vault/logs/$(date "+%Y%m%d%H%M.%S").log.json

open $VAULT_ADDR