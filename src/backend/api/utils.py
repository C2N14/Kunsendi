from datetime import datetime
from functools import wraps
from http import HTTPStatus

import jwt
from flask import jsonify, request

from . import SECRET_KEY


class InvalidTokenTypeError(Exception):
    """Exception raised when trying to pass and invalid token type for the specified action"""
    pass


def token_required(token_type):
    def decorator(f):
        """
        Decorator for methods that require a valid JWT token.
        Must specify if an access or refresh token is required.

        If successful, this passes the decoded token to the function's kwargs.
        """
        @wraps(f)
        def wrapper(*args, **kwargs):
            try:
                auth_header = request.headers.get('Authorization')

                if auth_header is None:
                    raise RuntimeError('No Authorization header specified')

                if not auth_header.startswith('Bearer '):
                    raise TypeError('Invalid header type')

                kwargs['token_payload'] = jwt.decode(auth_header[7:],
                                                     key=SECRET_KEY,
                                                     algorithms=['HS256'],
                                                     verify=True)

                if kwargs['token_payload']['type'] != token_type:
                    raise InvalidTokenTypeError(
                        f'Expected {token_type} got {kwargs["token_payload"]["type"]}'
                    )

            except (RuntimeError, TypeError) as e:
                return jsonify({
                    'msg': 'Invalid Authorization header',
                    'err': str(e)
                }), HTTPStatus.UNAUTHORIZED

            except jwt.DecodeError:
                return jsonify({
                    'msg': 'Malformed token',
                    'err': 'Couldn\'t decode token'
                }), HTTPStatus.UNAUTHORIZED

            except InvalidTokenTypeError as e:
                return jsonify({
                    'msg': 'Invalid token',
                    'err': str(e)
                }), HTTPStatus.UNAUTHORIZED

            except jwt.ExpiredSignatureError:
                return jsonify({
                    'msg': 'Invalid token',
                    'err': 'Token has expired'
                }), HTTPStatus.GONE

            return f(*args, **kwargs)

        return wrapper

    return decorator


def valid_json_payload(fields_dict):
    """
    Decorator for validating JSON POST data.
    A dictionary of types and fields to be verified must be passed, such as:
    {<<type1>>: <<list of fields/keys>>, <<type2>>: <<list of fields/keys>>, ...}
    
    E. g.
    @valid_json_payload({str: ['username', 'password'], int: ['age']})

    If successful, this passes the payload to the function's kwargs.
    """
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            try:
                payload = request.get_json()
                kwargs['payload'] = payload

                if type(payload) is not dict:
                    raise TypeError('Invalid JSON object or mimetype')

                for field_type, fields in fields_dict.items():
                    for field in fields:
                        if field not in payload:
                            raise TypeError(f'"{field}" field required')
                        if type(payload[field]) is not field_type:
                            raise TypeError(
                                f'"{field}" not a {field_type.__name__}')

            except TypeError as e:
                return jsonify({
                    'msg': 'Malformed JSON data',
                    'err': str(e)
                }), HTTPStatus.BAD_REQUEST

            return f(*args, **kwargs)

        return wrapper

    return decorator


def truncate_microseconds(original_datetime: datetime) -> datetime:
    """
    For compatibility reasons (working with Dart and Mongo), it is much better
    to just deal up to milliseconds when working with datetimes.

    As such, this truncates the microsecond data up to its first digit.
    """
    return original_datetime.replace(
        microsecond=(original_datetime.microsecond // 1000) * 1000)
