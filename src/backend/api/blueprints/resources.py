from flask import Blueprint, request
from flask import jsonify

from http import HTTPStatus

resources_blueprint = Blueprint('resources', __name__)

from .. import models, utils, ALLOWED_EXTENSIONS, UPLOAD_PATH


@resources_blueprint.route('/images', methods=['GET'])
@utils.token_required('access')
def get_images(**kwargs):
    pass


@resources_blueprint.route('/images', methods=['POST'])
@utils.token_required('access')
def post_image(**kwargs):
    try:
        if 'file' not in request.files:
            raise TypeError('No file part in request')

        file = request.files['file']
        if not file or file.filename == '':
            raise TypeError('No selected file in request')

        _, *extension = file.filename.rsplit('.', 1)

        if not extension or (extension :=
                             extension[0].lower()) not in ALLOWED_EXTENSIONS:
            raise TypeError('Invalid file extension')

        user_id = kwargs['token_payload']['sub']
        image = models.Image(extension=extension, uploader_id=user_id)

        file.save(str(UPLOAD_PATH), str(image.id))
        image.save()

    except TypeError as e:
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
