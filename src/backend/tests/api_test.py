import json
import os
import shutil
import sys
import unittest
from datetime import datetime, timedelta
from http import HTTPStatus
from pathlib import Path

import imagesize
import jwt
from freezegun import freeze_time
from mongoengine import connect, disconnect

package_path = str(Path(__file__).parent.parent.parent)

if package_path not in sys.path:
    sys.path.append(package_path)

from backend.api import (ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION,
                         UPLOAD_PATH, models)
from backend.api.app import create_app
from backend.tests import package_path
from backend.tests.utils import token_to_header

fixtures_dir = package_path / 'fixtures'
starting_now = datetime.utcnow()
immediate_now = starting_now + timedelta(milliseconds=1)


class ApiTest:
    @classmethod
    def setUpClass(cls):
        cls.db = connect('api-test', host='mongomock://localhost')

        # this looks weird here, but if used in tearDown it doesn't quite work
        cls.db.drop_database('api-test')

        cls.setup_mock_data()

        cls.app = create_app(connect_to_mongo=False)
        cls.client = cls.app.test_client()

    @classmethod
    def tearDownClass(cls):
        disconnect()

    @classmethod
    def setup_mock_data(cls):
        with open(fixtures_dir / 'mock_users.json') as f:
            cls.mock_users = json.load(f)
            for mock_user_data in cls.mock_users:
                models.User(**mock_user_data).save()
            # save the last user for testing
            cls.mock_user_example = mock_user_data


class AuthenticatedApiTest(ApiTest):
    # this is WET code (test_user_login) but I'm not sure how to fix this...
    @classmethod
    @freeze_time(starting_now)
    def setUpClass(cls):
        super().setUpClass()

        response = cls.client.post('/auth/sessions',
                                   json={
                                       'username':
                                       cls.mock_user_example['username'],
                                       'password':
                                       cls.mock_user_example['password']
                                   })
        cls.tokens = json.loads(response.data)
        cls.token_payloads = {
            k: jwt.decode(cls.tokens[k], algorithms=['HS256'], verify=False)
            for k in cls.tokens
        }


class AuthenticationBasicTest(ApiTest, unittest.TestCase):
    """Test case for URLs that don't require tokens"""
    def test_get_user_available(self):
        url = '/auth/users/'
        method = self.client.get

        users = ('ale_tuls', 'mock.user', 'John.Doe')
        result_data = (False, True, False)

        for user, expected_data in zip(users, result_data):
            with self.subTest(user=user, expected=expected_data):
                response = method(f'{url}{user}')
                self.assertEqual(response.status_code, HTTPStatus.OK)
                payload = json.loads(response.data)
                self.assertEqual(payload, {'available': expected_data})

    def test_user_register(self):
        url = '/auth/users'
        method = self.client.post

        payloads = ( \
            {
                'username': 'new.mock-user',
                'email': 'mymail@example.com',
                'password': 'NonSecurePass'
            },
            {
                'username': 'missing.params',
                'password': 'DoesntMatter'
            },
            {
                'username': 'inv',
                'email': 'invalid.example.com',
                'password': 'invalid'
            },
            self.mock_user_example,
            {
                **self.mock_user_example,
                'email': 'different@example.com'
            }
        )
        result_codes = (HTTPStatus.CREATED, HTTPStatus.BAD_REQUEST,
                        HTTPStatus.BAD_REQUEST, HTTPStatus.BAD_REQUEST,
                        HTTPStatus.BAD_REQUEST)

        for payload, expected_code in zip(payloads, result_codes):
            with self.subTest(payload=payload, expected=expected_code):
                response = method(url, json=payload)
                self.assertEqual(response.status_code, expected_code)

        # see that the user has been saved
        self.assertEqual(
            json.loads(self.client.get(f'{url}/new.mock-user').data),
            {'available': False})

    @freeze_time(starting_now)
    def test_user_login(self):
        url = '/auth/sessions'
        method = self.client.post

        # test for bad payloads
        bad_payloads = (
            {
                'username': self.mock_user_example['username'],
                'password':
                self.mock_user_example['password'] + 'Wrong:Password'
            },
            {
                'username': 'nonexisting_user',
                'password': 'DoesntMatter'
            },
            {
                'username': 'missing.params'
            },
        )
        result_codes = (HTTPStatus.UNAUTHORIZED, HTTPStatus.UNAUTHORIZED,
                        HTTPStatus.BAD_REQUEST)

        for bad_payload, expected_code in zip(bad_payloads, result_codes):
            with self.subTest(payload=bad_payload, expected=expected_code):
                response = self.client.post(url, json=bad_payload)
                self.assertEqual(response.status_code, expected_code)

        # test for good payload
        good_payload = {
            'username': self.mock_user_example['username'],
            'password': self.mock_user_example['password']
        }
        response = method(url, json=good_payload)
        self.assertEqual(response.status_code, HTTPStatus.CREATED)

        # confirm successful login and valid tokens
        # first, validate the tokens locally
        tokens = json.loads(response.data)
        token_payloads = {
            k: jwt.decode(tokens[k], algorithms=['HS256'], verify=False)
            for k in tokens
        }

        self.assertIn('access_token', token_payloads)
        self.assertIn('refresh_token', token_payloads)

        for token_type, token_payload in token_payloads.items():
            with self.subTest(token_type=token_type,
                              token_payload=token_payload):
                self.assertLess(token_payload['iat'], token_payload['exp'])

        # finally, ask the server for confirmation and compare to token
        response = self.client.get('/auth/users',
                                   headers=token_to_header(
                                       tokens['access_token']))
        self.assertEqual(response.status_code, HTTPStatus.OK)
        self.assertEqual(
            json.loads(response.data), {
                'user_id': token_payload['sub'],
                'username': self.mock_user_example['username']
            })


class AuthenticationSecondaryTest(AuthenticatedApiTest, unittest.TestCase):
    def test_tokens_and_expirations(self):
        token_types = ('access', 'refresh')
        expirations = (ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION)
        urls = ('/auth/users', '/auth/sessions')

        for token_type, expiration, url in zip(token_types, expirations, urls):
            # first, no token at all
            response = self.client.get(url)
            self.assertEqual(response.status_code, HTTPStatus.UNAUTHORIZED)

            # then, a valid token
            with freeze_time(immediate_now) as frozen, self.subTest(
                    token=token_type,
                    time=str(frozen.time_to_freeze),
                    issued=str(starting_now)):
                response = self.client.get(
                    url,
                    headers=token_to_header(
                        self.tokens[f'{token_type}_token']))
                self.assertEqual(response.status_code, HTTPStatus.OK)

            # finally, an expired token
            with freeze_time(immediate_now + expiration +
                             timedelta(seconds=1)) as frozen, self.subTest(
                                 token=token_type,
                                 time=str(frozen.time_to_freeze),
                                 issued=str(starting_now)):
                response = self.client.get(
                    url,
                    headers=token_to_header(
                        self.tokens[f'{token_type}_token']))
                self.assertEqual(response.status_code, HTTPStatus.GONE)

    @freeze_time(immediate_now + ACCESS_TOKEN_EXPIRATION + timedelta(seconds=1)
                 )
    def test_refresh_token(self):
        url = '/auth/sessions'
        method = self.client.get

        response = method(url,
                          headers=token_to_header(
                              self.tokens['refresh_token']))
        self.assertEqual(response.status_code, HTTPStatus.OK)

        new_tokens = json.loads(response.data)
        response = self.client.get('/auth/users',
                                   headers=token_to_header(
                                       new_tokens['access_token']))
        self.assertEqual(response.status_code, HTTPStatus.OK)

    @freeze_time(immediate_now)
    def test_get_user_info(self):
        url = '/auth/users'
        token_header = token_to_header(self.tokens['access_token'])

        # first, try with no token
        response = self.client.get(url)
        self.assertEqual(response.status_code, HTTPStatus.UNAUTHORIZED)

        # then, try just with no parameters
        response = self.client.get(url, headers=token_header)
        self.assertEqual(response.status_code, HTTPStatus.OK)
        response_payload = json.loads(response.data)
        self.assertEqual(response_payload['username'],
                         self.mock_user_example['username'])

        # finally, verify that querying with the returned id and username works
        parameters = ('id', 'username')
        keys = ('user_id', 'username')
        for parameter, key in zip(parameters, keys):
            with self.subTest(query_parameter=parameter, payload_key=key):
                r = self.client.get(
                    f'{url}?{parameter}={response_payload[key]}',
                    headers=token_header)
                self.assertEqual(r.status_code, HTTPStatus.OK)
                self.assertEqual(
                    json.loads(r.data)['username'],
                    self.mock_user_example['username'])


class AuthenticationFinalTest(AuthenticatedApiTest, unittest.TestCase):
    @freeze_time(immediate_now)
    def test_user_delete(self):
        url = '/auth/users'
        method = self.client.delete
        token_header = token_to_header(self.tokens['access_token'])

        # first, try without a token
        response = method(url)
        self.assertEqual(response.status_code, HTTPStatus.UNAUTHORIZED)

        # then, try with token
        response = method(url, headers=token_header)
        self.assertEqual(response.status_code, HTTPStatus.NO_CONTENT)

        # finally, make sure the user is gone
        response = self.client.get('/auth/users', headers=token_header)
        self.assertEqual(response.status_code, HTTPStatus.NOT_FOUND)


class ImagesTest(AuthenticatedApiTest, unittest.TestCase):
    @classmethod
    @freeze_time(immediate_now)
    def setUpClass(cls):
        super().setUpClass()

        # artificially upload images (1 to 3) as uploaded by the mock users
        cls.images_dir = fixtures_dir / 'images'
        cls.posted_delta = timedelta(seconds=1)

        for i, file in enumerate(cls.images_dir.glob('mock_image_[1-3].*')):
            user = models.User.objects.get(
                username=cls.mock_users[i]['username'])
            image = models.Image(
                upload_date=immediate_now + cls.posted_delta * i,
                uploader=user.username,
                uploader_id=user.id,
                extension=file.suffix[1:],
            )
            image.save()

            file_path = UPLOAD_PATH / f'{image.id}{file.suffix}'
            shutil.copy2(file, file_path)

            image.width, image.height = imagesize.get(file_path)
            image.save()

    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()

        # remove all the uploaded images
        for file in UPLOAD_PATH.glob('*'):
            os.remove(file)

    @freeze_time(immediate_now)
    def test_get_images(self):
        url = '/images'
        method = self.client.get
        token_header = token_to_header(self.tokens['access_token'])

        # first, try without token
        response = method(url)
        self.assertEqual(response.status_code, HTTPStatus.UNAUTHORIZED)

        # then, try getting all the images
        response = method(url, headers=token_header)
        self.assertEqual(response.status_code, HTTPStatus.OK)
        response_payload = json.loads(response.data)
        self.assertEqual(len(response_payload), 3)

        # then, try filtering by user and check for properties
        for mock_user in self.mock_users:
            with self.subTest(username=mock_user['username']):
                response = method(f'{url}?username={mock_user["username"]}',
                                  headers=token_header)
                self.assertEqual(response.status_code, HTTPStatus.OK)
                response_payload = json.loads(response.data)
                self.assertEqual(len(response_payload), 1)
                for key in ('filename', 'uploader', 'upload_date', 'width',
                            'height'):
                    self.assertIn(response_payload[0], key)

        # finally, filter by date
        response = method(
            url + '?from=' +
            (immediate_now + timedelta(milliseconds=1)).timestamp() + '&to=' +
            (immediate_now + self.posted_delta * 2 -
             timedelta(milliseconds=1)).timestamp(),
            headers=token_header)
        self.assertEqual(response.status_code, HTTPStatus.OK)
        response_payload = json.loads(response.data)
        self.assertEqual(len(response_payload), 1)
        self.assertEqual(response_payload[0]['username'],
                         self.mock_users[1]['username'])


if __name__ == '__main__':
    unittest.main()
