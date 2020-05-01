FROM python:3.7

COPY . /app
WORKDIR /app

RUN pip install --upgrade pip;\
    pip install -r requirements.txt

RUN curl -o consul-template.zip https://releases.hashicorp.com/consul-template/0.24.1/consul-template_0.24.1_linux_amd64.zip ; yes | unzip consul-template.zip; mv consul-template /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/consul-template", "-log-level=debug", \
    "-template=/app/secrets.ctmpl:/app/secrets.conf" \
    "-config=/app/config/consul-template.hcl", \
    "-secret=secret/myapp/config", \
    "-secret=secret/myapp/tf_config", \
    "-exec='python app.py'"]