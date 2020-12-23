import os

from flask import Blueprint, jsonify
from mongoengine.errors import DoesNotExist, NotUniqueError, ValidationError
from http import HTTPStatus
from werkzeug.security import check_password_hash
from datetime import datetime, timedelta
import jwt

from .. import models, utils, SECRET_KEY, ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION

auth_blueprint = Blueprint('auth', __name__)


class WrongCredentialsError(Exception):
    """Exception to raise when login details are wrong"""
    pass


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
        }), HTTPStatus.FORBIDDEN

    except NotUniqueError:
        return jsonify({
            'msg': 'Username not unique',
            'err': payload['username']
        }), HTTPStatus.FORBIDDEN

    return jsonify({'user_id': str(user.id)}), HTTPStatus.CREATED


@auth_blueprint.route('/auth/users', methods=['DELETE'])
@utils.token_required('access')
def delete_user(**kwargs):
    token_payload = kwargs['token_payload']
    user = models.User.objects.get(id=token_payload['user_id'])

    # delete user uploads
    models.Image.objects(uploader_id=user.id).delete()

    user.delete()

    return '', HTTPStatus.NO_CONTENT


@auth_blueprint.route('/auth/users/<username>', methods=['GET'])
def get_username_available(username):
    available = not models.User.objects.get(username=username)
    return jsonify({'avaliable': available}), HTTPStatus.OK


@auth_blueprint.route('/auth/sessions', methods=['GET'])
@utils.token_required('refresh')
def token_refresh(**kwargs):
    token_payload = kwargs['token_payload']
    tokens = generate_tokens(token_payload['user_id'])

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
            f'Couldn\'t verify identity for user {payload["username"]}'  # nopep8
        }), HTTPStatus.FORBIDDEN

    return jsonify(tokens), HTTPStatus.CREATED


# https://scotch.io/tutorials/the-anatomy-of-a-json-web-token#payload
def generate_tokens(user_id):
    """Auxiliary function for generating access and refresh tokens"""
    tokens = {}

    now = datetime.now()

    payload = {
        'iat': now.timestamp(),
        'sub': user_id,
    }
    access_payload = {
        'exp': (now + timedelta(seconds=ACCESS_TOKEN_EXPIRATION)).timestamp(),
        'type': 'access'
    }
    refresh_payload = {
        'exp': (now + timedelta(seconds=REFRESH_TOKEN_EXPIRATION)).timestamp(),
        'type': 'refresh'
    }
    tokens['access_token'] = jwt.encode({**payload, **access_payload}, \
                                        key=SECRET_KEY).decode('utf-8')
    tokens['access_token'] = jwt.encode({**payload, **refresh_payload}, \
                                        key=SECRET_KEY).decode('utf-8')
