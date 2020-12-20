from flask import Blueprint

resources_blueprint = Blueprint('resources', __name__)


@resources_blueprint.route('/api/resources')
def test():
    return 'Resources blueprint'
