from datetime import datetime
from .. import START_TIME
from flask import Blueprint, jsonify

info_blueprint = Blueprint('info', __name__)


@info_blueprint.route('/api/v1/status', methods=['GET'])
def get_status():
    return jsonify({
        'uptime':
        (datetime.utcnow().timestamp() - START_TIME.timestamp()) * 1000
    })
