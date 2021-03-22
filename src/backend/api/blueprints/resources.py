import os
from datetime import datetime
from http import HTTPStatus
from pathlib import Path

import imagesize
from flask import Blueprint, jsonify, request
from flask.helpers import send_from_directory
from mongoengine.errors import DoesNotExist

resources_blueprint = Blueprint('resources', __name__)

from math import trunc

from .. import ALLOWED_EXTENSIONS, UPLOAD_PATH, models, utils

PROJECT_PIPELINE = {
    '_id': False,
    'filename': {
        '$concat': [{
            '$toString': '$_id'
        }, '.', '$extension']
    },
    'uploader': True,
    'upload_date': {
        '$toLong': '$upload_date'
    },
    'width': True,
    'height': True,
}


@resources_blueprint.route('/api/v1/images', methods=['GET'])
@utils.token_required('access')
def get_image_info(**kwargs):
    try:
        now = utils.truncate_microseconds(datetime.utcnow())

        query = {}

        # to_arg is in milliseconds, must be converted to seconds
        # (note that truncate_microseconds is not needed)
        to_arg = request.args.get('to')
        if to_arg is not None:
            query['upload_date__lte'] = datetime.utcfromtimestamp(
                trunc(float(to_arg)) / 1000)
        else:
            query['upload_date__lte'] = now

        # prioritizes the id arg to the name arg
        user_id_arg = request.args.get('uploader_id')
        username_arg = request.args.get('uploader')
        if user_id_arg is not None:
            query['uploader_id'] = user_id_arg
        elif username_arg is not None:
            query['uploader'] = username_arg

        # from_arg is also in milliseconds
        from_arg = request.args.get('from')
        if from_arg is not None:
            query['upload_date__gte'] = datetime.utcfromtimestamp(
                trunc(float(from_arg)) / 1000)

        limit_arg = request.args.get('limit')
        if limit_arg is None:
            limit = 50
        elif not (0 < (limit := int(limit_arg)) < 100):
            limit = 100

        pipeline = [{'$project': PROJECT_PIPELINE}]

        # execute the query
        results = models.Image.objects(
            **query).order_by('-upload_date')[:limit].aggregate(pipeline)

    except ValueError as e:
        return jsonify({
            'msg': 'Invalid parameter values',
            'err': str(e)
        }), HTTPStatus.BAD_REQUEST

    except OSError as e:
        return jsonify({
            'msg': 'Invalid parameter values',
            'err': 'Invalid timestamp'
        }), HTTPStatus.BAD_REQUEST

    return jsonify(list(results)), HTTPStatus.OK


@resources_blueprint.route('/api/v1/images', methods=['POST'])
@utils.token_required('access')
def post_image(**kwargs):
    try:
        if 'file' not in request.files:
            raise TypeError('No file part in request')

        file = request.files['file']
        if not file or file.filename == '':
            raise TypeError('No selected file in request')

        file_path = Path(file.filename)
        extension = file_path.suffix

        # the walrus operator is neat to reduce code duplication, but I'm
        # not sure it's the most readable
        if not extension or (extension :=
                             extension.lower()) not in ALLOWED_EXTENSIONS:
            raise TypeError('Invalid file extension')

        user_id = kwargs['token_payload']['sub']
        username = models.User.objects.get(id=user_id).username
        image = models.Image(extension=extension[1:],
                             uploader=username,
                             uploader_id=user_id)
        image.save()

        file_path = UPLOAD_PATH / f'{image.id}{extension}'
        file.save(file_path)

        image.width, image.height = imagesize.get(file_path)
        image.save()

    except (TypeError, ValueError) as e:
        return jsonify({
            'msg': 'Invalid file',
            'err': str(e)
        }), HTTPStatus.BAD_REQUEST

    return jsonify({'filename': f'{image.id}{extension}'}), HTTPStatus.CREATED


@resources_blueprint.route('/api/v1/images/<filename>', methods=['GET'])
@utils.token_required('access')
def get_image(filename, **kwargs):
    try:
        return send_from_directory(UPLOAD_PATH, filename, as_attachment=True)

    except OSError:
        return jsonify({
            'msg': 'Can\'t find specified image',
            'err': 'Filename not found'
        }), HTTPStatus.NOT_FOUND


@resources_blueprint.route('/api/v1/images/<filename>', methods=['DELETE'])
@utils.token_required('access')
def delete_image(filename, **kwargs):
    try:
        user_id = kwargs['token_payload']['sub']

        image_path = UPLOAD_PATH / filename

        if not image_path.is_file():
            raise TypeError('Can\'t find image file for specified filename')

        image = models.Image.objects.get(id=image_path.stem)
        if str(image.uploader_id) != user_id:
            raise RuntimeError('Image doesn\'t belong to user')

        image.delete()
        os.remove(image_path)

    except (DoesNotExist, TypeError) as e:
        return jsonify({
            'msg': 'Image not found',
            'err': str(e)
        }), HTTPStatus.NOT_FOUND

    except RuntimeError as e:
        return jsonify({
            'msg': 'Can\'t delete image',
            'err': str(e)
        }), HTTPStatus.FORBIDDEN

    return '', HTTPStatus.NO_CONTENT
