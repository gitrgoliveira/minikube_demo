source helper.sh

################################################################
## When using envconsul, it does not reload the token written
## by the sidecar vault agent, hence the vault token lifetime
## needs to be the same as the application lifecyle.
################################################################
vault write -namespace=cluster-1 auth/kubernetes/role/env-example \
        bound_service_account_names=webapp \
        bound_service_account_namespaces=ns1 \
        policies=myapp-kv-ro token_num_uses=0 token_ttl=10s token_max_ttl=72h

## build
eval $(minikube docker-env -p cluster-1)
docker build --rm webapp-env/app/ -t webapp-env:v1
eval $(minikube docker-env -p cluster-1 -u)

c1_kctl -n ns1 apply -f webapp-env/k8s/
c1_kctl -n ns1 wait --for=condition=available --timeout=20s deployment/webapp-env
minikube service webapp-env -n ns1 -p cluster-1
