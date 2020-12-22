from enum import unique
import os
from datetime import datetime
from uuid import uuid4 as file_uuid

import mongoengine as db
from mongoengine.errors import ValidationError
from werkzeug.security import generate_password_hash

# 7 days in seconds
SESSION_EXPIRATION = 604800

with open(os.environ['MONGO_ROOT_USERNAME_FILE']) as user_f, \
     open(os.environ['MONGO_ROOT_PASSWORD_FILE']) as pass_f:
    # In Docker, the mongodb container is exposed with the hostname 'mongodb'
    db.connect(os.environ["MONGO_DATABASE"],
               host='mongodb',
               port=27017,
               username=user_f.read(),
               password=pass_f.read(),
               authentication_source='admin')


class User(db.Document):
    """
    Model for User document.
    Password is specified as cleartext when the object is created, but validated and hashed once saved
    """

    username = db.StringField(required=True,
                              unique=True,
                              min_length=4,
                              max_length=16,
                              regex='^(?=.*[\w].*)([\w._-]*)$')
    email = db.StringField(required=True,
                           min_length=1,
                           max_length=255,
                           regex='^[^@]*@[^@]*$')
    password = db.StringField(required=True)

    def clean(self):
        if not (8 <= len(self.password) <= 128):
            raise ValidationError('Invalid password length.')

        self.password = generate_password_hash(self.password)


class Image(db.Document):
    """Model for Image document"""

    filename = db.StringField(required=True, default=file_uuid().hex)
    user_id = db.ObjectIdField(required=True)
    date = db.DateTimeField(required=True, default=datetime.utcnow())
