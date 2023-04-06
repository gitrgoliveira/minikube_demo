source helper.sh

c1_kctx
TOKEN_REVIEW_JWT=$(kubectl create token vault --duration=120h)
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
vault write -namespace=cluster-1 auth/kubernetes/config \
    token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
    kubernetes_host="$KUBE_HOST" \
    kubernetes_ca_cert="$KUBE_CA_CERT"  \
    issuer="https://kubernetes.default.svc.cluster.local"


# to test the Token review API call.

# WEBAPP=$(kubectl -n ns1 create token webapp)
# curl -k -X "POST" "$KUBE_HOST/apis/authentication.k8s.io/v1/tokenreviews" \
#      -H "Authorization: Bearer $TOKEN_REVIEW_JWT" \
#      -H 'Content-Type: application/json; charset=utf-8' \
#      -d "{
#   \"kind\": \"TokenReview\",
#   \"apiVersion\": \"authentication.k8s.io/v1\",
#   \"spec\": {
#     \"token\": \"${WEBAPP}\"	
#     }
# }"
