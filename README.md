# Minikube demos

This repo has 2 demos for HashiCorp Vault, using minikube cluster as clients.

*Note: This is an advanced topic using the time limited public image of Vault Enterprise.*

### Requirements

*This demo environment was setup in MacOSX.*
*You will need to know bash to debug if something goes wrong*

* Minikube
* Helm
* docker and docker-compose
* kubectl
* Vault cli
* `aws` cli setup with an AWS account


## Kubernetes auth

### Overview

The objective with this demo is to demonstrate how to isolate the access to Vault secrets between applications running in kubernetes.

![Kubernetes auth](/graphics/k8s-auth.svg)

The above image illustrates three use cases:
1. The happy path: an application running on `ns1` k8s namespace is able to authenticate to `cluster-1` Vault namespace and retrieve a *KV* secret.
   * *Vault Namespace isolation ensures the authentication backend is not able to povide access to the `cluster-2` secrets, because the token provided is scoped to `cluster-1` namespace.*

2. Fail path 1: An application running on `ns2` k8s namespace  tries to authenticate to `cluster-1` Vault namespace, but fails, because the namespace `ns2` is not authorized.

3. Fail path 2: An application running on `ns1` k8s namespace  tries to authenticate to `cluster-1` Vault namespace, but fails, because the cluster is not the one configured in Vault kubernetes auth backend.

### Setup steps
1. Step one
2. Step two
3. Step three


## Jenkins workflow

### Overview

The main objective of this workflow is to provide a way for Jenkins to securily retrieve dynamic Vault and Cloud credentials, to submit these to Terraform Enterprise via an API call.

To achieve this we have set the following targets:
 * Reduce the value of the auth credential used to access Vault, in case of a leak.
 * Reduce the secret sprawl, by removing secrets from the Jenkins credential store.
 * Isolate the pipeline code used as much as possible.
 * Use a credential to access Vault that can be rotated.

![Jenkins workflow](/graphics/jenkins-k8s-auth.svg)


### Setup steps
1. Step one
2. Step two
3. Step three