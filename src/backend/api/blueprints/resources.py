from flask import Blueprint

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
