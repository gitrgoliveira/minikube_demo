import os
import logging
import random
import string

from flask import Flask, session
from flask.logging import default_handler
from flask_session import Session


def hello_world():
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

    output = "Kubernetes node {node}</br>\
            </br>\
            Kubernetes namespace {namespace}</br>\
            </br>\
            Kubernetes ServiceAccount \"{svcacc}\" authorised to access Vault </br>\
            </br>\
            Displaying secrets read from FILE in {storage_path} </br>\
            </br>\
            Values in Vault path \"secret/myapp/config\"></br>\
            {data}</br>\
            </br>\
            Rendered template from Vault path \"secret/myapp/tf_config\":</br>\
            {tf_file}</br>\
            </br>\
            </br>\
            ".format( node=os.environ.get('MY_NODE_NAME'),
                namespace=os.environ.get('MY_POD_NAMESPACE'),
                svcacc=os.environ.get('MY_POD_SERVICE_ACCOUNT'),
                data=data,
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
