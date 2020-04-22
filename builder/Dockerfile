FROM jenkins/jnlp-slave:4.3-4-alpine
# jenkins/jnlp-slave:3.27-1
USER root
RUN apk add jq curl python
RUN curl -o vault.zip https://releases.hashicorp.com/vault/1.4.0+ent/vault_1.4.0+ent_linux_amd64.zip ; yes | unzip vault.zip; mv vault /usr/local/bin/
USER jenkins