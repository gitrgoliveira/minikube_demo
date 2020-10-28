source helper.sh

# If you do not have access to the GitHub docker registry
# eval $(minikube docker-env -p cluster-1)
# docker build --rm webapp/app/ -t webapp:v1
# eval $(minikube docker-env -p cluster-2)
# docker build --rm webapp/app/ -t webapp:v1
# eval $(minikube docker-env -p cluster-2 -u)

c1_kctl -n ns1 apply -f webapp/k8s/
c1_kctl -n ns2 apply -f webapp/k8s/
c2_kctl -n ns1 apply -f webapp/k8s/

c1_kctl -n ns1 wait --for=condition=available --timeout=20s deployment/webapp

minikube service webapp -n ns1 -p cluster-1
minikube service webapp -n ns2 -p cluster-1
minikube service webapp -n ns1 -p cluster-2