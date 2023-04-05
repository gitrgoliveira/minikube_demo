# Minikube Vault demos

This repo has some demos for HashiCorp Vault, using minikube clusters as clients.

*Note: This is an advanced topic using a time limited public image of Vault Enterprise.*

- [Kubernetes auth](#kubernetes-auth)
  - [Overview](#overview)
  - [Setup steps](#setup-steps)
- [Jenkins workflow](#jenkins-workflow)
  - [Overview](#overview-1)
  - [Setup steps](#setup-steps-1)
- [Envconsul workflow](#envconsul-workflow)
  - [Setup steps](#setup-steps-2)

### Requirements

*This demo environment was setup in MacOSX.*
*You will need to know bash to debug if something goes wrong*

* Minikube
* Helm
* docker and docker-compose
* kubectl
* Vault cli
* Vault Enterprise license in `./vault.volume/config/license.hclic`


## Kubernetes auth

### Overview

The objective with this demo is to demonstrate how to isolate the access to Vault secrets between applications running in Kubernetes.

![Kubernetes auth](/graphics/k8s-auth.svg)

The above image illustrates three use cases:
1. The happy path: an application running on `ns1` k8s namespace is able to authenticate to `cluster-1` Vault Namespace and retrieve a *KV* secret.
   * *Vault Namespace isolation ensures the authentication backend is not able to povide access to the `cluster-2` secrets, because the token provided is scoped to `cluster-1` namespace.*

2. Fail path 1: An application running on `ns2` k8s namespace  tries to authenticate to `cluster-1` Vault Namespace, but fails, because k8s namespace `ns2` is not authorized.

3. Fail path 2: An application running on `ns1` k8s namespace  tries to authenticate to `cluster-1` Vault Namespace, but fails, because the cluster is not the one configured in Vault Kubernetes auth backend.

### Setup steps
1. Run `00_start.sh`
2. Run `01_setup.sh`
3. Run `02_deploy.sh`

To work with this setup you can `source helper.sh`, which provides you with some helper commands and setup.

To clear your machine, just run `99_teardown.sh`

## Jenkins workflow

### Overview

The main objective of this workflow is to provide a way for Jenkins to securely retrieve dynamic Vault and Cloud credentials, to submit these to Terraform Enterprise via an API call.

To achieve this, we have set the following targets:
 * Reduce the value of the auth credential used to access Vault, in case of a leak
 * Reduce the secret sprawl, by removing secrets from the Jenkins credential store
 * Isolate the pipeline code used as much as possible
 * Use a credential to access Vault that can be rotated.

![Jenkins workflow](/graphics/jenkins-k8s-auth.svg)


### Setup steps
1. Run `00_start.sh`
2. Run `01_setup.sh`
3. Run `add_jenkins.sh`

To work with this setup you can `source helper.sh`, which provides you with some helper commands and setup.

To clear your machine, just run `03_teardown.sh`


## Envconsul workflow

Sometimes it's difficult to adapt an application do read variables from a file, instead of using environment variables. For these use cases, there are a few options:

**Option one** is to have Vault agent inject a variable file in the right format and modify the docker entry point to wrap binary into `export $(cat envfile | xargs) && webapp`

The advantage here is that the changes are minimum, but it's also a *one-shot* injection, with no refresh ability.

**Option two** same as above, but the script also watches for file changes and restarts the process.

**Option three** is to use `envconsul`, to keep track of changes in Vault and restart the `webapp` process accordingly.

This last option requires many changes, for example:
 * Vault namespace specified in Dockerfile
 * Vault secrets path specified in Dockerfile
 * envconsul becomes a dependency
 * Management of envconsul.hcl configuration file
 * Vault token TTL needs to be increased, since envconsul will not refresh the token from the file.

### Setup steps
1. Run `00_start.sh`
2. Run `01_setup.sh`
3. Run `add_webapp-env.sh`