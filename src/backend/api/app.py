from flask import Flask
from .blueprints import auth, resources, info
import os
import mongoengine as db
from http import HTTPStatus

from . import MAX_CONTENT_LENGTH


def create_app(connect_to_mongo=True) -> Flask:
    app = Flask(__name__)

    app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

    if connect_to_mongo:
        with open(os.environ['MONGO_ROOT_USERNAME_FILE']) as user_f, \
            open(os.environ['MONGO_ROOT_PASSWORD_FILE']) as pass_f:
            # in Docker, the mongodb container is exposed with the hostname 'mongodb'
            db.connect(os.environ["MONGO_DATABASE"],
                       host='mongodb',
                       port=27017,
                       username=user_f.read(),
                       password=pass_f.read(),
                       authentication_source='admin')

    with app.app_context():

        if os.getenv('FLASK_DEBUG') == '1':
            from .debugger import initialize_debugger
            initialize_debugger()

        app.register_error_handler(HTTPStatus.INTERNAL_SERVER_ERROR,
                                   internal_error)

        app.register_blueprint(auth.auth_blueprint)
        app.register_blueprint(resources.resources_blueprint)
        app.register_blueprint(info.info_blueprint)

        return app


# TODO: Error/exception logging
def internal_error(e):
    pass
