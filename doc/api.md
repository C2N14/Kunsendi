# Specification for API methods

## HTTP Methods

| HTTP Method | Relative URL   | Data sent                 | Requires JWT | Result               | Data received                      |
| ----------- | -------------- | ------------------------- | :----------: | -------------------- | ---------------------------------- |
| POST        | /auth/users    | username, email, password |      no      | Registers a new user | user_id                            |
| DELETE      | /auth/users    | _none_                    |     yes      | Deletes the user     | _none_                             |
| GET         | /auth/sessions | _none_                    |     yes      | Refreshes the token  | *text/plain*                       |
| POST        | /auth/sessions | username, password        |      no      | Returns a JWT token  | *text/plain*                       |
| DELETE      | /auth/sessions | _none_                    |     yes      | Deletes the session  | _none_                             |
| GET         | /images        | _none_                    |     yes      | Returns images       | [uploader, url, date, title, size] |
| POST        | /images        | *multipart/form-data*     |     yes      | Uploads a new image  | image_id                           |
| DELETE      | /images        | image_id                  |     yes      | Deletes the image    | _none_                             |


### Notes:
* The data sent and received must be in JSON format, unless specified
* Session JWTs must be sent in the Authorization header when necessary
* JWTs expire after 15 minutes but can be refreshed within 7 days
