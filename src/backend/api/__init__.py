import os
from pathlib import Path

with open(os.environ['FLASK_SECRET_KEY']) as f:
    SECRET_KEY = f.read()

UPLOAD_PATH = Path('static/uploads')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10MB

# in minutes
ACCESS_TOKEN_EXPIRATION = 15

# in days
REFRESH_TOKEN_EXPIRATION = 3
