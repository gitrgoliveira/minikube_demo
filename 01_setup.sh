source helper.sh

tee myapp-kv-ro.hcl <<EOF
# For K/V v1 secrets engine
path "secret/myapp/*" {
    capabilities = ["read", "list"]
}
# For K/V v2 secrets engine
path "secret/data/myapp/*" {
    capabilities = ["read", "list"]
}
# For AWS secrets engine
path "aws/creds/my-role" {
    capabilities = ["read"]
}

EOF

function setup_k8s (){
    # Creating Vault namespace
    vault namespace create $1

    kubectl config use-context $1
    # Service Account for Vault access to the k8s API
    kubectl create serviceaccount vault-auth
    # Service account for applications
    kubectl create serviceaccount webapp -n ns1
    kubectl create serviceaccount webapp -n ns2

    kubectl apply -f vault-auth-service-account.yml

    vault policy write -namespace=$1 myapp-kv-ro myapp-kv-ro.hcl

    vault secrets enable -namespace=$1 -path=secret kv
    vault kv put -namespace=$1 secret/myapp/config username='appuser' password='suP3rsec(et!' ttl='2s' cluster=$1
    vault kv put -namespace=$1 secret/myapp/tf_config ttl='2s' tf_server='app.terraform.io' tf_token='example.swasdfs14UyfU0CJQ.atlasv2.AAbddAffk1236yJsGDz0PvrM'

    VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
    # Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
    SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
    # Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
    SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

    # Set K8S_HOST to minikube IP address
    K8S_HOST=$(minikube ip -p $1)
    vault auth enable -namespace=$1 kubernetes

    vault write -namespace=$1 auth/kubernetes/config \
        token_reviewer_jwt="$SA_JWT_TOKEN" \
        kubernetes_host="https://$K8S_HOST:8443" \
        kubernetes_ca_cert="$SA_CA_CRT"

    # Create a role named, 'example' to map Kubernetes Service Account to
    # Vault policies and default token TTL
    # https://www.vaultproject.io/api-docs/auth/kubernetes/#create-role
    vault write -namespace=$1 auth/kubernetes/role/example \
        bound_service_account_names=webapp \
        bound_service_account_namespaces=ns1 \
        policies=myapp-kv-ro ttl=5s
}

c1_kctl create ns ns1
c1_kctl create ns ns2
c2_kctl create ns ns1
c2_kctl create ns ns2

setup_k8s "cluster-1"
setup_k8s "cluster-2"

rm myapp-kv-ro.hcl
#############################################
# Apply
#############################################
rm -rf manifests
mkdir -p manifests

helm fetch --untar  https://github.com/hashicorp/vault-helm/archive/v0.5.0.tar.gz
helm template --set injector.externalVaultAddr=http://$(ipconfig getifaddr en0):8200/ \
    --set fullnameOverride=vault \
    --set injector.logLevel=debug \
    ./vault/ --output-dir ./manifests

c1_kctl apply -f manifests/vault/templates
c2_kctl apply -f manifests/vault/templates

c1_kctl wait --for=condition=available --timeout=20s deployment/vault-agent-injector
c2_kctl wait --for=condition=available --timeout=20s deployment/vault-agent-injector
