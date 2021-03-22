from datetime import datetime
from .. import START_TIME
from flask import Blueprint, jsonify
from math import trunc

info_blueprint = Blueprint('info', __name__)


@info_blueprint.route('/api/v1/status', methods=['GET'])
def get_status():
    delta = datetime.utcnow() - START_TIME
    return jsonify({'uptime': trunc(delta.total_seconds() * 1000)})
