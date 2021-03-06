import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import 'globals.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Class for simplifying API responses.
class ApiResponse {
  final int statusCode;
  final dynamic payload;
  final Map<String, String> headers;
  const ApiResponse(this.statusCode, this.payload, this.headers);

  factory ApiResponse.fromHttpResponse(http.Response response,
      {bool bytes = false}) {
    // debugPrint(response.headers.toString());
    return ApiResponse(
        response.statusCode,
        bytes
            ? response.bodyBytes
            : response.headers['content-type'] == 'application/json'
                ? json.decode(response.body)
                : response.body,
        response.headers);
  }
}

// Exception for authentication related issues.
class ApiAuthException implements Exception {
  String cause;
  ApiAuthException(this.cause);
}

/// Singleton class for accessing the API.
class ApiClient {
  static ApiClient? _instance;
  ApiClient._();
  static ApiClient getInstance() => _instance ??= ApiClient._();

  Timer? _sessionTimer;
  http.Client _client = http.Client();

  /// Base function for generic HTTP request.
  ///
  /// Returns either a [Response] or a [StreamedResponse].
  Future<dynamic> _httpRequest(
    Function requestFun,
    String path, [
    bool? authRequired,
    Map<String, String>? headers,
    dynamic body,
  ]) async {
    return await retry(() async {
      // If authentication is required, try with the access token if not specified in the headers.
      if (authRequired ?? false) {
        headers ??= {};
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

  // Special HTTP requests.

  /// GET request.
  ///
  /// Returns either [Response] or a [StreamedResponse].
  Future<dynamic> _get(
    String path, {
    bool? authRequired,
    Map<String, String>? headers,
  }) async =>
      this._httpRequest(this._client.get, path, authRequired, headers);

  /// POST request.
  ///
  /// Returns either [Response] or a [StreamedResponse].
  Future<dynamic> _post(
    String path, {
    bool? authRequired,
    Map<String, String>? headers,
    dynamic body,
  }) async =>
      this._httpRequest(this._client.post, path, authRequired, headers, body);

  /// DELETE request.
  ///
  /// Returns either [Response] or a [StreamedResponse].
  Future<dynamic> _delete(
    String path, {
    bool? authRequired,
    Map<String, String>? headers,
  }) async =>
      this._httpRequest(this._client.delete, path, authRequired, headers);

  /// Base function for Multipart HTTP requests.
  ///
  /// Returns either [Response] or a [StreamedResponse].
  ///
  /// This is needed since the mechanism for doing multipart requests is totally
  /// different from regular requests in Dart's http library.
  Future<dynamic> _multipartHttpRequest(
    String path, [
    String type = 'GET',
    bool? authRequired,
    Map<String, String>? multipartHeaders,
    http.MultipartFile? multipartFile,
    bool? streamed,
  ]) async {
    // Special http function to handle multipart request.
    final multiPostFunc =
        (Uri funTarget, {Map<String, String>? headers}) async {
      var request = http.MultipartRequest(type, funTarget);
      if (type == 'POST') {
        request.files.add(multipartFile!);
      }
      request.headers.addAll(headers ?? const {});

      final response = await request.send();

      if (!(streamed ?? false)) {
        return http.Response.fromStream(response);
      } else {
        return response;
      }
    };

    // Use the base HTTP request.
    return await this
        ._httpRequest(multiPostFunc, path, authRequired, multipartHeaders);
  }

  // Specific Multipart HTTP requests.

  /// Multipart GET request.
  ///
  /// Returns either [Response] or a [StreamedResponse].
  Future<dynamic> _multipartGet(
    String path, {
    bool? authRequired,
    Map<String, String>? headers,
    bool? streamed,
  }) async =>
      this._multipartHttpRequest(
          path, 'GET', authRequired, headers, null, streamed);

  /// Multipart POST request.
  ///
  /// Returns either [Response] or a [StreamedResponse].
  Future<dynamic> _multipartPost(
    String path,
    http.MultipartFile multipartFile, {
    bool? authRequired,
    Map<String, String>? headers,
    bool? streamed,
  }) async =>
      this._multipartHttpRequest(
          path, 'POST', authRequired, headers, multipartFile, streamed);

  /// Tries using the stored refresh token to refresh both tokens.
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

  /// Refreshes the tokens and sets up a timer to refresh tokens periodically.
  Future<bool> initSession() async {
    this._sessionTimer?.cancel();
    return await this._refreshedSession();
  }

  /// Deletes the tokens to end the session.
  Future<void> endSession() async {
    if (this._sessionTimer?.isActive ?? false) {
      this._sessionTimer?.cancel();
    }
    await AppGlobals.secureStorage!.delete(key: 'refresh_token');
    await AppGlobals.secureStorage!.delete(key: 'access_token');
  }

  /// By default gets the logged user's username and id.
  ///
  /// Optionally can be used to search a specific username or id.
  Future<ApiResponse> getUserInfo({String? id, String? username}) async {
    final params = Uri(queryParameters: {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
    });
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/auth/users${params.toString()}',
    ));
  }

  /// Registers a new account.
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

  /// Deletes the logged user's account.
  Future<ApiResponse> unregister() async {
    return ApiResponse.fromHttpResponse(await this._delete(
      '/v1/auth/users',
      authRequired: true,
    ));
  }

  /// Finds if a username is available.
  Future<ApiResponse> getUsernameAvailable(String username) async {
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/auth/users/$username',
    ));
  }

  /// Logs in and returns the appropriate tokens.
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

  /// By default gets a list of the last uploaded images.
  ///
  /// Optionally can be used to search images by username, id, posted time range
  ///
  /// and limit the number of results.
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
      if (limit != null) 'limit': limit.toString(),
    });
    final resp = await this._get(
      '/v1/images${params.toString()}',
      authRequired: true,
    );
    final tmp = ApiResponse.fromHttpResponse(resp);
    // debugPrint(tmp.payload.toString());
    return tmp;
  }

  /// Posts an image on behalf of the logged user.
  ///
  /// One of the two multipart requests in the client.
  Future<ApiResponse> postImage(File imageFile) async {
    return ApiResponse.fromHttpResponse(
        await this._multipartPost(
          '/v1/images',
          await http.MultipartFile.fromPath('file', imageFile.path),
          authRequired: true,
        ),
        bytes: true);
  }

  /// Gets an image file by its filename.
  ///
  /// One of the two multipart requests in the client, and currently not used since
  /// CachedNetworkImage needs its own FileService that generates StreamedResponse's.
  Future<ApiResponse> getImage(
    String filename,
  ) async {
    return ApiResponse.fromHttpResponse(
        await this._multipartGet(
          '/v1/images',
          authRequired: true,
        ),
        bytes: true);
  }

  /// Deletes an image by its filename.
  Future<ApiResponse> deleteImage(String filename) async {
    return ApiResponse.fromHttpResponse(await this._delete(
      '/v1/images/$filename',
      authRequired: true,
    ));
  }

  /// Gets the server status.
  Future<ApiResponse> status() async {
    return ApiResponse.fromHttpResponse(await this._get(
      '/v1/status',
    ));
  }
}

/// [FileService] exclusive for image API requests.
///
/// Used to override requests on CachedNetworkImage's.
class ApiFileService extends HttpFileService {
  ApiClient _client = ApiClient.getInstance();

  /// Where the magic occurs.
  @override
  Future<FileServiceResponse> get(String filename,
      {Map<String, String>? headers}) async {
    return HttpGetResponse(await _client._multipartGet(
      '/v1/images/$filename',
      authRequired: true,
      streamed: true,
    ));
  }
}

/// Custom [CacheManager] for use on [CachedNetworkImage].
///
/// Pretty much an equivalent to [DefaultCacheManager], but with a different key
/// and [ApiFileService]
class ApiCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'kunsendiCachedImageData';

  static final ApiCacheManager _instance = ApiCacheManager._();
  factory ApiCacheManager() {
    return _instance;
  }

  ApiCacheManager._()
      : super(Config(
          key,
          fileService: ApiFileService(),
        ));
}
