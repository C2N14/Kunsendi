import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import 'globals.dart';

// Class for simplifying API responses.
class ApiResponse {
  final int statusCode;
  final dynamic payload;
  const ApiResponse(this.statusCode, this.payload);

  factory ApiResponse.fromHttpResponse(http.Response response) {
    print(response.headers);
    return ApiResponse(
        response.statusCode,
        response.headers['content-type'] == 'application/json'
            ? json.decode(response.body)
            : response.body);
  }
}

// Exception for authentication related issues.
class ApiAuthException implements Exception {
  String cause;
  ApiAuthException(this.cause);
}

// Singleton class for accessing the API.
class ApiClient {
  static ApiClient? _instance;
  ApiClient._();
  static ApiClient getInstance() => _instance ??= ApiClient._();

  Timer? _sessionTimer;

  // Base function for generic HTTP request.
  Future<http.Response> _httpRequest(Function requestFun, String path,
      [bool? authRequired, Map<String, String>? headers, dynamic body]) async {
    return await retry(() async {
      // If authentication is required, try with the access token if not specified in the headers.
      if (authRequired ?? false) {
        headers ??= Map<String, String>();
        headers!['Authorization'] =
            'Bearer ${await AppGlobals.secureStorage!.read(key: 'access_token')}';
      }

      final target =
          Uri.parse('${AppGlobals.localStorage!.get('selected_api_uri')}$path');

      // Only try passing the body as argument if necessary
      final response = (body != null)
          ? await requestFun(target, headers: headers, body: body)
          : await requestFun(target, headers: headers);

      if (authRequired ?? false) {
        if (response.statusCode == HttpStatus.gone &&
            !await this.initSession()) {
          throw ApiAuthException('Expired refresh token');
        } else if (response.statusCode == HttpStatus.unauthorized) {
          throw ApiAuthException('Invalid authorization');
        }
      }
      return response;
    },
            retryIf: (e) => e is SocketException || e is TimeoutException,
            maxAttempts: 5)
        .timeout(Duration(seconds: 10));
  }

  // Specific HTTP requests.
  // GET request.
  Future<http.Response> _get(String path,
          {bool? authRequired, Map<String, String>? headers}) async =>
      this._httpRequest(http.get, path, authRequired, headers);
  // POST request.
  Future<http.Response> _post(String path,
          {bool? authRequired,
          Map<String, String>? headers,
          dynamic body}) async =>
      this._httpRequest(http.post, path, authRequired, headers, body);
  // DELETE request.
  Future<http.Response> _delete(String path,
          {bool? authRequired, Map<String, String>? headers}) async =>
      this._httpRequest(http.delete, path, authRequired, headers);

  // Tries using the stored refresh token to refresh both tokens.
  Future<bool> _refreshedSession() async {
    final refreshToken =
        await AppGlobals.secureStorage!.read(key: 'refresh_token');
    final response = await this._get(
      '/v1/auth/sessions',
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    final loggedIn = response.statusCode == HttpStatus.ok;

    if (loggedIn) {
      final payload = json.decode(response.body);
      await AppGlobals.secureStorage!
          .write(key: 'access_token', value: payload['access_token']);
      await AppGlobals.secureStorage!
          .write(key: 'refresh_token', value: payload['refresh_token']);
    }

    return loggedIn;
  }

  // Refreshes the tokens and sets up a timer to refresh tokens periodically.
  Future<bool> initSession() async {
    this._sessionTimer?.cancel();
    return await this._refreshedSession();
  }

  // Deletes the tokens.
  Future<void> endSession() async {
    if (this._sessionTimer?.isActive ?? false) {
      this._sessionTimer?.cancel();
    }
    await AppGlobals.secureStorage!.delete(key: 'refresh_token');
    await AppGlobals.secureStorage!.delete(key: 'access_token');
  }

  // By default gets the logged user's username and id.
  // Optionally can be used to search a specific username or id.
  Future<ApiResponse> getUserInfo({String? id, String? username}) async {
    final params = Uri(queryParameters: {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
    });
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/auth/users${params.toString()}',
    ));
  }

  // Registers a new account.
  Future<ApiResponse> register(
      String username, String email, String password) async {
    return ApiResponse.fromHttpResponse(await this._post(
      '/v1/auth/users',
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
      headers: {'Content-type': 'application/json'},
    ));
  }

  // Deletes the logged user's account.
  Future<ApiResponse> unregister() async {
    return ApiResponse.fromHttpResponse(await this._delete(
      '/v1/auth/users',
      authRequired: true,
    ));
  }

  // Finds if an username is available.
  Future<ApiResponse> getUsernameAvailable(String username) async {
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/auth/users/$username',
    ));
  }

  // Logs in and returns the appropiate tokens.
  Future<ApiResponse> login(String username, String password) async {
    return ApiResponse.fromHttpResponse(await this._post(
      '/v1/auth/sessions',
      body: json.encode({
        'username': username,
        'password': password,
      }),
      headers: {'Content-type': 'application/json'},
    ));
  }

  // By default gets a list of the last uploaded images.
  // Optionally can be used to search images by username, id, posted time range
  // and limit the number of results.
  Future<ApiResponse> listImages(
      {String? uploader,
      String? uploaderId,
      DateTime? from,
      DateTime? to,
      int? limit}) async {
    final params = Uri(queryParameters: {
      if (uploader != null) 'uploader': uploader,
      if (uploaderId != null) 'uploader_id': uploaderId,
      if (from != null) 'from': (from.millisecondsSinceEpoch / 1000).toString(),
      if (to != null) 'to': (to.millisecondsSinceEpoch / 1000).toString(),
      if (limit != null) 'limit': limit,
    });
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/images${params.toString()}',
      authRequired: true,
    ));
  }

  // Posts an image on behalf of the logged user.
  // This is an exception to the other methods in that it doesn't use this._post
  // to handle the request, since it's dealing with a Multipart file.
  Future<ApiResponse> postImage(File imageFile) async {
    final multipart = http.MultipartFile.fromPath('file', imageFile.path);

    // Special http function to handle multipart request.
    final multiPostFunc = (target, {Map<String, String>? headers}) async {
      var request = http.MultipartRequest('POST', target);
      request.files.add(await multipart);
      request.headers.addAll(headers ?? const {});

      final response = await request.send();
      return http.Response.fromStream(response);
    };

    // Use this function in the request.
    return ApiResponse.fromHttpResponse(await this._httpRequest(
      multiPostFunc,
      '/v1/images',
      true,
    ));
  }

  // Gets an image file by its filename.
  // NOTE: This is currently not used in favor of using CachedNetworkImage.
  Future<ApiResponse> getImage(
    String filename,
  ) async {
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/images/$filename',
      authRequired: true,
    ));
  }

  // Deletes an image by its filename.
  Future<ApiResponse> deleteImage(String filename) async {
    return ApiResponse.fromHttpResponse(await this._delete(
      '/v1/images/$filename',
      authRequired: true,
    ));
  }

  // Gets the server status.
  Future<ApiResponse> status() async {
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/status',
    ));
  }
}
