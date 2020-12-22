import os

with open(os.environ['FLASK_SECRET_KEY']) as f:
    SECRET_KEY = f.read()

UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
