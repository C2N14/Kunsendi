from datetime import date, datetime
from flask import Blueprint, request, jsonify

from http import HTTPStatus
import imagesize

resources_blueprint = Blueprint('resources', __name__)

from .. import models, utils, ALLOWED_EXTENSIONS, UPLOAD_PATH


@resources_blueprint.route('/images', methods=['GET'])
@utils.token_required('access')
def get_images(**kwargs):
    try:
        now = datetime.now()

        # this also prioritizes the id arg to the name arg
        user_id_arg = request.args.get('uploader_id')
        username_arg = request.args.get('uploader')
        if username_arg is not None and user_id_arg is None:
            user_id = str(models.User.objects.get(username=username_arg).id)
        else:
            user_id = user_id_arg

        from_arg = request.args.get('from')
        if from_arg is not None:
            from_arg = datetime.utcfromtimestamp(float(from_arg))
        to_arg = datetime.utcfromtimestamp(
            float(request.args.get('to', now.timestamp())))

        limit_arg = request.args.get('limit')
        if limit_arg is None:
            limit_arg = 50
        elif (limit_arg := int(limit_arg)) > 100:
            limit_arg = 100

    except ValueError as e:
        return jsonify({'msg': 'Invalid parameter values', 'err': str(e)})

    except OSError as e:
        return jsonify({
            'msg': 'Invalid parameter values',
            'err': 'Invalid timestamp'
        })

    return jsonify([user_id, from_arg, to_arg, limit_arg])


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

        file.save(str(UPLOAD_PATH), str(image.id))

        image.width, image.height = imagesize.get(UPLOAD_PATH / str(image.id))
        image.save()

    except (TypeError, ValueError) as e:
        return jsonify({
            'msg': 'Invalid file',
            'err': str(e)
        }), HTTPStatus.BAD_REQUEST

    return jsonify({'image_id', str(image.id)}), HTTPStatus.CREATED


@resources_blueprint.route('/images/<image_id>', methods=['DELETE'])
@utils.token_required('access')
def delete_image(image_id, **kwargs):
    try:
        user_id = kwargs['token_payload']['sub']

        image = models.Image.objects.get(id=image_id)

        if str(image.uploader_id) != user_id:
            raise RuntimeError('Image doesn\'t belong to user')

        image.delete()

    except RuntimeError as e:
        return jsonify({
            'err': 'Can\'t delete image',
            'msg': str(e)
        }), HTTPStatus.FORBIDDEN

    return '', HTTPStatus.NO_CONTENT
