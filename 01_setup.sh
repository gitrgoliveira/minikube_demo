source helper.sh

#############################################
#   Installing external Vault
#############################################

VAULT_HELM_VERSION=0.23.0
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

c1_kctx
helm install vault hashicorp/vault --version $VAULT_HELM_VERSION \
    --set "injector.externalVaultAddr=$VAULT_ADDR" \
    --set injector.logLevel=debug

kubectl wait --for=condition=available --timeout=20s deployment/vault-agent-injector


tee myapp-kv-ro.hcl > /dev/null <<EOF
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

# allowing client to read their own token
path "auth/token/lookup-self" {
    capabilities = ["read"]
}
EOF

function setup_k8s (){
    # Creating Vault namespace
    vault namespace create $1

    kubectl config use-context $1
    
    # Service account for applications
    kubectl create serviceaccount webapp -n ns1
    kubectl create serviceaccount webapp -n ns2

    # kubectl apply -f vault-auth-service-account.yml

    vault policy write -namespace=$1 myapp-kv-ro myapp-kv-ro.hcl

    vault secrets enable -namespace=$1 -path=secret kv
    vault kv put -namespace=$1 secret/myapp/config username='appuser' password='suP3rsec(et!' ttl='2s' cluster=$1
    vault kv put -namespace=$1 secret/myapp/tf_config ttl='2s' tf_server='app.terraform.io' tf_token='example.swasdfs14UyfU0CJQ.atlasv2.AAbddAffk1236yJsGDz0PvrM'

    # Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-token
  annotations:
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token
EOF
    
    vault auth enable -namespace=$1 kubernetes

    TOKEN_REVIEW_JWT=$(kubectl get secret vault-token --output='go-template={{ .data.token }}' | base64 --decode)
    # TOKEN_REVIEW_JWT=$(kubectl create token vault --duration=120h)
    KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
    KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)

    vault write -namespace=$1 auth/kubernetes/config \
        token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
        kubernetes_host="$KUBE_HOST" \
        kubernetes_ca_cert="$KUBE_CA_CERT"  \
        issuer="https://kubernetes.default.svc.cluster.local"

    # Create a role named, 'example' to map Kubernetes Service Account to
    # Vault policies and default token TTL
    # https://www.vaultproject.io/api-docs/auth/kubernetes/#create-role
    vault write -namespace=$1 auth/kubernetes/role/example \
        bound_service_account_names=webapp \
        bound_service_account_namespaces=ns1 \
        alias_name_source=serviceaccount_name \
        policies=myapp-kv-ro ttl=5s
}

c1_kctl create ns ns1
c1_kctl create ns ns2

setup_k8s "cluster-1"

rm myapp-kv-ro.hcl
#############################################

# curl -ki \
#     --request POST \
#     --data '{"jwt": "$SA_JWT_TOKEN", "role": "vault"}' \
#     https://127.0.0.1:58347/v1/auth/kubernetes/login
#     https://127.0.0.1:58347/apis/authentication.k8s.io/v1/tokenreviews