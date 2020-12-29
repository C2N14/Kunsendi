import os
from datetime import datetime

import mongoengine as db
from mongoengine.errors import ValidationError
from werkzeug.security import generate_password_hash


class User(db.Document):
    """
    Model for User document.
    Password is specified as cleartext when the object is created, but validated and hashed once saved.
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
            raise ValidationError('Invalid password length.',
                                  field_name='password')

        self.password = generate_password_hash(self.password)


class Image(db.Document):
    """Model for Image document"""

    upload_date = db.DateTimeField(required=True, default=datetime.utcnow)

    # denormalized data is still kinda weird for me!
    uploader = db.StringField(required=True)
    uploader_id = db.ObjectIdField(required=True)

    extension = db.StringField(required=True)
    width = db.IntField(min_value=0)
    height = db.IntField(min_value=0)
