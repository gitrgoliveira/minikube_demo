source helper.sh

################################################################
## Using consul-template with the exec pattern
## https://github.com/hashicorp/consul-template#exec-mode
################################################################

## build
eval $(minikube docker-env -p cluster-1)
docker build --rm webapp-template/app/ -t webapp-template:v1
eval $(minikube docker-env -p cluster-1 -u)

c1_kctl -n ns1 apply -f webapp-template/k8s/
c1_kctl -n ns1 wait --for=condition=available --timeout=20s deployment/webapp-template
minikube service webapp-template -n ns1 -p cluster-1
