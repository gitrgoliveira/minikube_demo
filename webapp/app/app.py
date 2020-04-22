import os
import logging
import random
import string

from flask import Flask, session
from flask.logging import default_handler
from flask_session import Session


def hello_world():
    vault_path = 'secret/myapp/config'
    storage_path = '/vault/secrets/myapp'
    data = ""
    tf_file = ""
    try:
        with open(storage_path) as fp:
            for line in fp:
                data = data + "%s</br>" % (line)
        with open("/root/.terraformrc") as fp:
            for line in fp:
                tf_file = tf_file + "%s</br>" % (line)
    except:
        data = "no secret available"

    output = "node {node}</br>\
            </br>\
            </br>\
            Running on namespace {namespace}</br>\
            </br>\
            Using service account \"{svcacc}\" to access vault </br>\
            </br>\
            reading {vault_path} from {storage_path} </br>\
            </br>\
            Value:</br>\
            {value}</br>\
            </br>\
            </br>\
            Terraform configuration:</br>\
            {tf_file}</br>\
            </br>\
            ".format( node=os.environ.get('MY_NODE_NAME'),
                namespace=os.environ.get('MY_POD_NAMESPACE'),
                svcacc=os.environ.get('MY_POD_SERVICE_ACCOUNT'),
                value=data,
                vault_path=vault_path,
                storage_path=storage_path,
                tf_file=tf_file)

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
