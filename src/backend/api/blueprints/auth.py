from datetime import datetime
from http import HTTPStatus

import jwt
from flask import Blueprint, jsonify
from flask.globals import request
from mongoengine.errors import DoesNotExist, NotUniqueError, ValidationError
from werkzeug.security import check_password_hash

from .. import (ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION, SECRET_KEY,
                models, utils)

auth_blueprint = Blueprint('auth', __name__)


class WrongCredentialsError(Exception):
    """Exception to raise when login details are wrong"""
    pass


@auth_blueprint.route('/auth/users', methods=['GET'])
@utils.token_required('access')
def get_user_info(**kwargs):
    try:
        # query parameters
        id_arg = request.args.get('id')
        username_arg = request.args.get('username')

        # this strange structure gives priority to the id arg over the username
        # arg, and defaults to using the id of the jwt when needed
        if id_arg is None and username_arg is not None:
            username = username_arg
            user_id = str(models.User.objects.get(username=username_arg).id)

        else:
            if id_arg is not None:
                user_id = id_arg
            else:
                user_id = kwargs['token_payload']['sub']
            username = models.User.objects.get(id=user_id).username

    except DoesNotExist as e:
        return jsonify({
            'msg': 'User info not found',
            'err': str(e)
        }), HTTPStatus.NOT_FOUND

    return jsonify({'user_id': user_id, 'username': username}), HTTPStatus.OK


@auth_blueprint.route('/auth/users', methods=['POST'])
@utils.valid_json_payload({str: ('username', 'email', 'password')})
def register_user(**kwargs):
    try:
        payload = kwargs['payload']
        user = models.User(username=payload['username'],
                           email=payload['email'],
                           password=payload['password'])
        user.save()

    except ValidationError as e:
        return jsonify({
            'msg': 'Invalid parameters',
            'err': e.message
        }), HTTPStatus.BAD_REQUEST

    except NotUniqueError:
        return jsonify({
            'msg': 'Username not unique',
            'err': payload['username']
        }), HTTPStatus.BAD_REQUEST

    return jsonify({'user_id': str(user.id)}), HTTPStatus.CREATED


@auth_blueprint.route('/auth/users', methods=['DELETE'])
@utils.token_required('access')
def delete_user(**kwargs):
    try:
        token_payload = kwargs['token_payload']
        user = models.User.objects.get(id=token_payload['sub'])

        # delete user uploads
        models.Image.objects(uploader_id=user.id).delete()

        user.delete()

    except DoesNotExist as e:
        return jsonify({
            'msg': 'User doesn\'t exist anymore',
            'err': str(e)
        }), HTTPStatus.NOT_FOUND

    return '', HTTPStatus.NO_CONTENT


@auth_blueprint.route('/auth/users/<username>', methods=['GET'])
def get_username_available(username):
    try:
        models.User.objects.get(username=username)
    except DoesNotExist:
        available = True
    else:
        available = False

    return jsonify({'available': available}), HTTPStatus.OK


@auth_blueprint.route('/auth/sessions', methods=['GET'])
@utils.token_required('refresh')
def token_refresh(**kwargs):
    token_payload = kwargs['token_payload']
    tokens = generate_tokens(token_payload['sub'])

    return jsonify(tokens), HTTPStatus.OK


@auth_blueprint.route('/auth/sessions', methods=['POST'])
@utils.valid_json_payload({str: ('username', 'password')})
def user_login(**kwargs):
    try:
        payload = kwargs['payload']

        user = models.User.objects.get(username=payload['username'])
        if not check_password_hash(user.password, payload['password']):
            raise WrongCredentialsError

        tokens = generate_tokens(str(user.id))

    except (DoesNotExist, WrongCredentialsError):
        return jsonify({
            'msg':
            'Wrong credentials',
            'err':
            f'Couldn\'t verify identity for user {payload["username"]}'
        }), HTTPStatus.UNAUTHORIZED

    return jsonify(tokens), HTTPStatus.CREATED


# https://scotch.io/tutorials/the-anatomy-of-a-json-web-token#payload
def generate_tokens(user_id):
    """Auxiliary function for generating access and refresh tokens"""
    tokens = {}

    now = datetime.now()

    # base token from which to differentiate access and refresh
    base_payload = {
        'iat': now.timestamp(),
        'sub': user_id,
    }

    token_types = ('access', 'refresh')
    token_expirations = (ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION)

    for _type, expiration in zip(token_types, token_expirations):
        specific_payload = {
            'exp': (now + expiration).timestamp(),
            'type': _type
        }
        tokens[f'{_type}_token'] = jwt.encode(
            {
                **base_payload,
                **specific_payload
            },
            key=SECRET_KEY,
            algorithm='HS256').decode('utf-8')
        # access_payload = {
        #     'exp': (now + ACCESS_TOKEN_EXPIRATION).timestamp(),
        #     'type': 'access'
        # }
        # refresh_payload = {
        #     'exp': (now + REFRESH_TOKEN_EXPIRATION).timestamp(),
        #     'type': 'refresh'
        # }
        # tokens['access_token'] = jwt.encode({**base_payload, **access_payload}, \
        #                                     key=SECRET_KEY), algorithm='HS256'.decode('utf-8')
        # tokens['refresh_token'] = jwt.encode({**base_payload, **refresh_payload}, \
        #                                     key=SECRET_KEY, algorithm='HS256').decode('utf-8')

    return tokens
