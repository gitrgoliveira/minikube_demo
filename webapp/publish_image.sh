#!/usr/bin/env bash

cat ~/.GH_DOCKER_TOKEN | docker login ghcr.io -u gitrgoliveira --password-stdin
docker build --rm app/ -t ghcr.io/gitrgoliveira/minikube_demo/webapp:v1
docker push ghcr.io/gitrgoliveira/minikube_demo/webapp:v1