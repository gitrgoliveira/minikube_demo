FROM python:3.7
WORKDIR /app
COPY ./requirements.txt /app/requirements.txt
RUN pip install --upgrade pip;\
    pip install -r requirements.txt
RUN curl -o envconsul.zip https://releases.hashicorp.com/envconsul/0.9.2/envconsul_0.9.2_linux_amd64.zip ; yes | unzip envconsul.zip; mv envconsul /usr/local/bin/
COPY . /app

# hardcoded Vault Namespace required for EnvConsul
ENV VAULT_NAMESPACE=cluster-1
ENTRYPOINT [ "/usr/local/bin/envconsul", "-log-level=debug", \
    "-config=/app/config/envconsul.hcl", "-upcase", "-sanitize", \
    "-secret", "secret/myapp/config", \
    "-secret", "secret/myapp/tf_config", \
    "python"]

CMD ["app.py"]
