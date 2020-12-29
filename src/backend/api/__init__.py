import os
from pathlib import Path
from datetime import timedelta

try:
    with open(os.environ['FLASK_SECRET_KEY']) as f:
        SECRET_KEY = f.read()
except KeyError:
    # TODO: warn about random secret

    import secrets
    SECRET_KEY = secrets.token_bytes(32)

UPLOAD_PATH = (Path(__file__).parent / 'static/uploads')
UPLOAD_PATH.mkdir(parents=True, exist_ok=True)
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10MB

ACCESS_TOKEN_EXPIRATION = timedelta(minutes=15)
REFRESH_TOKEN_EXPIRATION = timedelta(days=3)
