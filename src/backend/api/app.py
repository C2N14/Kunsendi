from flask import Flask
from .blueprints import auth, resources
import os
from http import HTTPStatus

from . import MAX_CONTENT_LENGTH


def create_app():
    app = Flask(__name__)

    app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

    with app.app_context():

        if os.getenv("FLASK_DEBUG") == '1':
            from .debugger import initialize_debugger
            initialize_debugger()

        app.register_error_handler(HTTPStatus.INTERNAL_SERVER_ERROR,
                                   internal_error)

        app.register_blueprint(auth.auth_blueprint)
        app.register_blueprint(resources.resources_blueprint)

        return app


# TODO: Error/exception logging
def internal_error(e):
    pass
