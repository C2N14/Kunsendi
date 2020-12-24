import os
from pathlib import Path
from datetime import timedelta

with open(os.environ['FLASK_SECRET_KEY']) as f:
    SECRET_KEY = f.read()

UPLOAD_PATH = Path('static/uploads')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10MB

ACCESS_TOKEN_EXPIRATION = timedelta(minutes=15)
REFRESH_TOKEN_EXPIRATION = timedelta(days=3)
