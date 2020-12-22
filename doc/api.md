# Specification for API methods

## HTTP Methods

| HTTP Method | Relative URL    | Data sent                       | Requires JWT | Result                          | Data received                                                     |
| ----------- | --------------- | ------------------------------- | :----------: | ------------------------------- | ----------------------------------------------------------------- |
| `GET`       | /auth/users/xxx | _none_                          |      no      | Checks if username is available | `available`                                                       |
| `POST`      | /auth/users     | `username`, `email`, `password` |      no      | Registers a new user            | `user_id`                                                         |
| `DELETE`    | /auth/users     | _none_                          |     yes      | Deletes the user                | _none_                                                            |
| `GET`       | /auth/sessions  | _none_                          |     yes*     | Refreshes the tokens            | `access_token`, `refresh_token`                                   |
| `POST`      | /auth/sessions  | `username`, `password`          |      no      | Returns both JWT tokens         | `access_token`, `refresh_token`                                   |
| `GET`       | /images         | _none_                          |     yes      | Returns images                  | [`uploader`, `url`, `date`, `title`, `size`: [`width`, `height`]] |
| `POST`      | /images         | **multipart/form-data**         |     yes      | Uploads a new image             | `image_id`                                                        |
| `DELETE`    | /images         | `image_id`                      |     yes      | Deletes the image               | _none_                                                            |


### Notes:
* The data sent and received must be in JSON format, unless specified.
* Session (*access* or *refresh*) JWTs must be sent in the Authorization header when necessary.
* The token in the header must be an *access* token, except when refreshing the tokens.
* *Access* tokens expire after 15 minutes and *refresh* tokens after 3 days.
* When querying images, an array of objects is returned

## Restrictions on `POST` requests

### /auth/users
* `username` must be a string between 4 and 16 characters, alphanumeric (at least one), scores, underscores or dots, and it must be *unique*.
* `email` must be a string between 1 and 255 characters, with exactly one `@` sign.
* `password` must be a string between 8 and 128 characters.

### /images
* A file must be of `.jpg`, `.jpeg`, `.png` or `.gif` extension, no larger than 10MB.

## Query parameters of `GET` requests

### /images
* TODO
