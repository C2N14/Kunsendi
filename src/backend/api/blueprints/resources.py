from datetime import date, datetime
from http import HTTPStatus
from flask.helpers import send_file

import imagesize
from flask import Blueprint, jsonify, request

resources_blueprint = Blueprint('resources', __name__)

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
        '$divide': [{
            '$toLong': '$upload_date'
        }, 1000]
    },
    'width': True,
    'height': True,
}


@resources_blueprint.route('/images', methods=['GET'])
@utils.token_required('access')
def get_image_info(**kwargs):
    try:
        now = datetime.utcnow()

        to_arg = request.args.get('to')
        query = {
            'upload_date__lte':
            datetime.utcfromtimestamp(float(to_arg)) if to_arg else now
        }

        # prioritizes the id arg to the name arg
        user_id_arg = request.args.get('uploader_id')
        username_arg = request.args.get('uploader')
        if user_id_arg is not None:
            query['uploader_id'] = user_id_arg
        elif username_arg is not None:
            query['uploader'] = username_arg

        from_arg = request.args.get('from')
        if from_arg is not None:
            query['upload_date__gte'] = datetime.utcfromtimestamp(
                float(from_arg))

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
        return jsonify({'msg': 'Invalid parameter values', 'err': str(e)})

    except OSError as e:
        return jsonify({
            'msg': 'Invalid parameter values',
            'err': 'Invalid timestamp'
        })

    return jsonify(list(results)), HTTPStatus.OK


@resources_blueprint.route('/images', methods=['POST'])
@utils.token_required('access')
def post_image(**kwargs):
    try:
        if 'file' not in request.files:
            raise TypeError('No file part in request')

        file = request.files['file']
        if not file or file.filename == '':
            raise TypeError('No selected file in request')

        # tuple unpacking is quite strange here, but very useful
        # it will try splitting by the last dot in the filename, and if it succeds
        # 'extension' is set to a single element list with the extension, otherwise
        # an empty list
        _, *extension = file.filename.rsplit('.', 1)

        # the walrus operator is neat to reduce code duplication, but I'm
        # not sure it's the most readable
        if not extension or (extension :=
                             extension[0].lower()) not in ALLOWED_EXTENSIONS:
            raise TypeError('Invalid file extension')

        user_id = kwargs['token_payload']['sub']
        username = models.User.objects.get(id=user_id).username
        image = models.Image(extension=extension,
                             uploader=username,
                             uploader_id=user_id)
        image.save()

        file_path = UPLOAD_PATH / f'{image.id}.{extension}'
        file.save(file_path)

        image.width, image.height = imagesize.get(file_path)
        image.save()

    except (TypeError, ValueError) as e:
        return jsonify({
            'msg': 'Invalid file',
            'err': str(e)
        }), HTTPStatus.BAD_REQUEST

    return jsonify({'filename': str(image.id)}), HTTPStatus.CREATED


@resources_blueprint.route('/images/<filename>', methods=['GET'])
@utils.token_required('access')
def get_image(filename, **kwargs):
    try:
        return send_file(UPLOAD_PATH / filename, as_attachment=True)

    except OSError:
        return jsonify({
            'msg': 'Can\'t find specified image',
            'err': 'Filename not found'
        }), HTTPStatus.BAD_REQUEST


@resources_blueprint.route('/images/<filename>', methods=['DELETE'])
@utils.token_required('access')
def delete_image(filename, **kwargs):
    try:
        user_id = kwargs['token_payload']['sub']

        # TODO: fix this
        image = models.Image.objects.get(id=filename.split('.')[0])

        if str(image.uploader_id) != user_id:
            raise RuntimeError('Image doesn\'t belong to user')

        image.delete()

    except RuntimeError as e:
        return jsonify({
            'msg': 'Can\'t delete image',
            'err': str(e)
        }), HTTPStatus.FORBIDDEN

    return '', HTTPStatus.NO_CONTENT
