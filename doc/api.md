# Specification for API methods

## HTTP Methods

| HTTP Method  | Relative URL    | Data sent                       | Requires JWT | Result                           | Data received                                              |
| ------------ | --------------- | ------------------------------- | :----------: | -------------------------------- | ---------------------------------------------------------- |
| `GET`      o | /auth/users     | _none_                          |     yes      | Returns information about a user | user_id, username                                          |
| `POST`     o | /auth/users     | `username`, `email`, `password` |      no      | Registers a new user             | `user_id`                                                  |
| `DELETE`   o | /auth/users     | _none_                          |     yes      | Deletes a user                   | _none_                                                     |
| `GET`      o | /auth/users/xxx | _none_                          |      no      | Checks if username is available  | `available`                                                |
| `GET`      o | /auth/sessions  | _none_                          |     yes*     | Refreshes the tokens             | `access_token`, `refresh_token`                            |
| `POST`     o | /auth/sessions  | `username`, `password`          |      no      | Returns both JWT tokens          | `access_token`, `refresh_token`                            |
| `GET`      o | /images         | _none_                          |     yes      | Returns information about images | [`filename`, `uploader`, `upload_date`, `width`, `height`] |
| `POST`     o | /images         | **multipart/form-data**         |     yes      | Uploads a new image              | `filename`                                                 |
| `GET`        | /images/xxx     | _none_                          |     yes      | Returns an image file            | **image/[jpg, png, gif]**                                  |
| `DELETE`     | /images/xxx     | _none_                          |     yes      | Deletes an image                 | _none_                                                     |


### Notes:
* The data sent and received must be in JSON format, unless specified.
* Session (*access* or *refresh*) JWTs must be sent in the Authorization header when necessary.
* The token in the header must be an *access* token, except when refreshing the tokens.
* *Access* tokens expire after 15 minutes and *refresh* tokens after 3 days.
* When querying images, an array of objects is returned in descending order by upload date.
* Getting and deleting images requires using the full filename, not just the id

## Restrictions on `POST` requests

### /auth/users
* `username` must be a string between 4 and 16 characters, alphanumeric (at least one), scores, underscores or dots, and it must be *unique*.
* `email` must be a string between 1 and 255 characters, with exactly one `@` sign.
* `password` must be a string between 8 and 128 characters.

### /images
* A file must be of `.jpg`, `.jpeg`, `.png` or `.gif` extension, no larger than 10MB.

## Query parameters of `GET` requests

### /auth/users
* `id` The user id.
* `username` The username.
If neither `id` nor `username` are specified, information about the user who sent the request is returned.

### /images
* `uploader` The username of the uploader.
* `uploader_id` The user id of the uploader.
* `from`An utc epoch/unix timestamp (in seconds) of the lower limit of upload date. If not specified, images from any starting time will be returned.
* `to` An utc epoch/unix timestamp (in seconds) of the upper limit of upload date. If not specified, images up to the current time will be returned.
* `limit` The maximum number of items to be returned, which can be any positive integer up to 100. If not specified, a maximum of 50 images will be returned.
If neither `uploader` nor `uploader_id` are specified, images from all users are returned.

## Status codes & error responses
If the request was successful, the response code will be according to the method of the request:
|  Method  | Success code |
| :------: | :----------: |
|  `GET`   |     `OK`     |
|  `POST`  |  `CREATED`   |
| `DELETE` | `NO CONTENT` |

If there was an error with the request itself, an object with `msg` and `err` detailing the cause of the failure will be returned, and sent with a client error status code (4XX).

Finally, in the case of a server error a 500 status code will be returned.
