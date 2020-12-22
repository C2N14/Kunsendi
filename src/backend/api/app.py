from flask import Flask
from .blueprints import auth, resources
import os
from http import HTTPStatus


def create_app():
    app = Flask(__name__)

    # Limit payload to 10MB
    app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024

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