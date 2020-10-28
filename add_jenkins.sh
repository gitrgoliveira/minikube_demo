source helper.sh

##### Install jenkins
c1_kctx
## pre-req for Jenkins
kubectl create namespace workers || true

### adding image
eval $(minikube docker-env -p cluster-1)
docker build --rm builder -t builder:v0
eval $(minikube docker-env -p cluster-1 -u)
## jenkins installation
# helm repo add stable https://kubernetes-charts.storage.googleapis.com
# helm install demo stable/jenkins -f ./jenkins_values.yaml --version 1.17.2
helm repo add jenkinsci https://charts.jenkins.io
# helm repo update
helm install jenkins jenkinsci/jenkins -f ./jenkins_values.yaml --version 2.6.4

function setup_k8s_ns (){
    ###### Setting up k8s workers namespace
    kubectl create namespace worker-$1 || true
    kubectl -n worker-$1 create sa $1
    kubectl -n worker-$1 apply -f jenkins-schedule-agents.yaml

    ###### Policy ensures the right secrets are targeted by the correct auth backend.
    tee pki-policy-ro.hcl <<EOF
# For PKI secrets engine
path "$1/issue/*" {
    capabilities = ["read"]
}

path "auth/token/lookup-self/" {
    capabilities = ["read"]
}
EOF
    vault policy write -namespace=cluster-1 $1-ro pki-policy-ro.hcl
    rm pki-policy-ro.hcl

    ###### Linking k8s auth with policy
    vault write -namespace=cluster-1 auth/kubernetes/role/$1 \
        bound_service_account_names=$1 \
        bound_service_account_namespaces=worker-$1 \
        policies=$1-ro ttl=5s
}


function setup_vault_secrets (){
    vault secrets enable -namespace=cluster-1 -path=$1 pki  || true
    vault write -namespace=cluster-1 $1/root/generate/internal \
        common_name=$1.example.com

    vault write -namespace=cluster-1 $1/config/urls \
        issuing_certificates="http://127.0.0.1:8200/v1/$1/ca" \
        crl_distribution_points="http://127.0.0.1:8200/v1/$1/crl"

    vault write -namespace=cluster-1 $1/roles/example-dot-com \
        allowed_domains=$1.example.com \
        allow_subdomains=true

}

setup_k8s_ns "dev"
setup_k8s_ns "test"
setup_k8s_ns "prod"
setup_vault_secrets "dev"
setup_vault_secrets "test"
setup_vault_secrets "prod"
kubectl wait --for=condition=available --timeout=30s deployment/jenkins
kubectl apply -f jenkins-schedule-agents.yaml
minikube -p cluster-1 service list