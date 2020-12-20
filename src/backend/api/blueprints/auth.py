from flask import Blueprint

auth_blueprint = Blueprint('auth', __name__)


@auth_blueprint.route('/auth/users', methods=['POST'])
def register_user():
    pass


@auth_blueprint.route('/auth/users', methods=['DELETE'])
def delete_user():
    pass


@auth_blueprint.route('/auth/sessions', methods=['GET'])
def token_refresh():
    pass


@auth_blueprint.route('/auth/sessions', methods=['POST'])
def user_login():
    pass


@auth_blueprint.route('/auth/sessions', methods=['DELETE'])
def user_logout():
    pass
