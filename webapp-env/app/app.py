import os
import logging
import random
import string
import json

from flask import Flask, session
from flask.logging import default_handler
from flask_session import Session
from json2html import json2html



def hello_world():
    env_json = json.dumps(dict(os.environ), ensure_ascii=False, sort_keys=True)
    output = "Kubernetes node {node}</br>\
            </br>\
            Kubernetes namespace {namespace}</br>\
            </br>\
            Kubernetes ServiceAccount \"{svcacc}\" authorised to access Vault </br>\
            </br>\
            Values injected into the environment, using envconsul:</br>\
            {env}</br>\
            </br>\
            ".format( node=os.environ.get('MY_NODE_NAME'),
                namespace=os.environ.get('MY_POD_NAMESPACE'),
                svcacc=os.environ.get('MY_POD_SERVICE_ACCOUNT'),
                env=json2html.convert(json=env_json))

    return output

def create_app():
    app = Flask(__name__)
    app.secret_key = ''.join(random.choice(string.ascii_lowercase) for i in range(256))
    app.config['SESSION_TYPE'] = 'filesystem'
    sess = Session()
    sess.init_app(app)

    @app.route('/')
    def default():
        return hello_world()

    return app

if __name__ == '__main__':
    create_app().run(host='0.0.0.0')
