from flask import Flask
from .blueprints import auth, resources
import debugpy


def create_app():
    app = Flask(__name__)

    app.register_blueprint(auth.auth_blueprint)
    app.register_blueprint(resources.resources_blueprint)

    return app
