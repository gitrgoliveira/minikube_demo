source helper.sh

c1_kctx
kubectl delete secret $(kubectl get secrets | grep "vault-auth-token" | awk '{print $1}')

VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
# Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

# Set K8S_HOST to minikube IP address
K8S_HOST=$(minikube ip -p cluster-1)

vault write -namespace=cluster-1 auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="https://$K8S_HOST:8443" \
    kubernetes_ca_cert="$SA_CA_CRT"
