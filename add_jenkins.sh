source helper.sh

##### Install jenkins
c1_kctx
## pre-req for Jenkins
kubectl create namespace workers || true

### adding image
eval $(minikube docker-env -p cluster-1)
docker build --rm builder -t builder:v0

## jenkins installation
# helm repo add stable https://kubernetes-charts.storage.googleapis.com
# helm install demo stable/jenkins -f ./jenkins_values.yaml --version 1.17.2
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
helm install demo jenkinsci/jenkins -f ./jenkins_values.yaml --version 2.6.4

function setup_k8s_ns_aws_account (){
    ###### Setting up k8s workers namespace
    kubectl create namespace worker-$1 || true
    kubectl -n worker-$1 create sa $1
    kubectl -n worker-$1 apply -f jenkins-schedule-agents.yaml

    ###### Setup AWS backend for account
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

    vault secrets enable -namespace=cluster-1 -path=$1 aws  || true
    vault write -namespace=cluster-1 $1/config/root \
        access_key=$AWS_ACCESS_KEY_ID \
        secret_key=$AWS_SECRET_ACCESS_KEY \
        region=eu-west-2

    vault write -namespace=cluster-1 $1/config/lease lease=10m lease_max=30m
    vault write -namespace=cluster-1 $1/roles/ro-role \
        name=ric_vault_demo \
        credential_type=iam_user \
        policy_document=-<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "Stmt1426528957000",
        "Effect": "Allow",
        "Action": [
            "ec2:*"
        ],
        "Resource": [
            "*"
        ]
        }
    ]
}
EOF

    tee aws-policy-ro.hcl <<EOF
# For AWS secrets engine
path "$1/creds/ro-role" {
    capabilities = ["read"]
}

path "auth/token/lookup-self" {
    capabilities = ["read"]
}
EOF
    ###### Policy ensures the right aws account is targeted by the auth backend.
    vault policy write -namespace=cluster-1 $1-ro aws-policy-ro.hcl
    rm aws-policy-ro.hcl

    ###### Linking k8s auth with policy
    vault write -namespace=cluster-1 auth/kubernetes/role/$1 \
        bound_service_account_names=$1 \
        bound_service_account_namespaces=worker-$1 \
        policies=$1-ro ttl=5s
}

setup_k8s_ns_aws_account "aws-dev"
setup_k8s_ns_aws_account "aws-test"
setup_k8s_ns_aws_account "aws-prod"

kubectl wait --for=condition=available --timeout=30s deployment/demo-jenkins
minikube -p cluster-1 service list