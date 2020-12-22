from flask import Blueprint, send_file

resources_blueprint = Blueprint('resources', __name__)


@resources_blueprint.route('/images', methods=['GET'])
def get_images():
    pass


@resources_blueprint.route('/images', methods=['POST'])
def post_image():
    pass


@resources_blueprint.route('/images', methods=['DELETE'])
def delete_image():
    pass


def allowed_file(filename):
    """Auxiliary function for validating sent file extensions"""
    pass
