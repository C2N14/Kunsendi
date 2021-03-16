// import 'package:flutter/material.dart';

import 'globals.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:retry/retry.dart';

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> payload;
  const ApiResponse(this.statusCode, this.payload);

  factory ApiResponse.fromHttpResponse(http.Response response) {
    return ApiResponse(
        response.statusCode,
        response.headers['Content-type'] ?? '' == 'application/json'
            ? json.decode(response.body)
            : response.body);
  }
}

// This is a singleton class for accesing the API.
class ApiClient {
  static ApiClient _instance;
  ApiClient._();
  static ApiClient getInstance() => _instance ??= ApiClient._();

  Timer _sessionTimer;

  // Base function for generic HTTP request.
  Future<http.Response> _httpRequest(Function requestFun, String path,
      [Map<String, String> headers, dynamic body]) async {
    return await retry(
            requestFun(
                '${AppGlobals.localStorage.get('selected_api_uri')}$path',
                headers: headers,
                body: body),
            retryIf: (e) => e is SocketException || e is TimeoutException,
            maxAttempts: 5)
        .timeout(Duration(seconds: 10));
  }

  // Specific HTTP requests.
  Future<http.Response> _get(String path,
          {Map<String, String> headers}) async =>
      this._httpRequest(http.get, path, headers);
  Future<http.Response> _post(String path,
          {Map<String, String> headers, dynamic body}) async =>
      this._httpRequest(http.post, path, headers, body);
  Future<http.Response> _delete(String path,
          {Map<String, String> headers}) async =>
      this._httpRequest(http.delete, path, headers);

  // Tries using the stored information to refresh the access and refresh tokens.
  Future<bool> refreshedSession() async {
    final refreshToken =
        await AppGlobals.secureStorage.read(key: 'refresh_token');
    final response = await this._get('/v1/auth/sessions',
        headers: {'Authorization': 'Bearer $refreshToken'});

    final loggedIn = response.statusCode == HttpStatus.ok;

    if (loggedIn) {
      final payload = json.decode(response.body);
      await AppGlobals.secureStorage
          .write(key: 'access_token', value: payload['access_token']);
      await AppGlobals.secureStorage
          .write(key: 'refresh_token', value: payload['refresh_token']);
    }

    return loggedIn;
  }

  // Refreshes the tokens and sets up a timer to refresh tokens periodically.
  Future<void> initSession() async {
    this.refreshedSession();
    this._sessionTimer =
        Timer(Duration(minutes: 14), () async => await this.refreshedSession());
  }

  // Restarts the session if for any reason the session cycle stops working.
  Future<void> restartSession() async {
    if (this._sessionTimer?.isActive ?? false) {
      this._sessionTimer.cancel();
    }
    this.initSession();
  }

  // Deletes the tokens.
  Future<void> endSession() async {
    if (this._sessionTimer?.isActive ?? false) {
      this._sessionTimer.cancel();
    }
    await AppGlobals.secureStorage.delete(key: 'refresh_token');
    await AppGlobals.secureStorage.delete(key: 'access_token');
  }

  Future<ApiResponse> register(
      String username, String email, String password) async {
    return ApiResponse.fromHttpResponse(
      await this._post('/v1/auth/users',
          body: json.encode({
            'username': username,
            'email': email,
            'password': password,
          }),
          headers: {'Content-type': 'application/json'}),
    );
  }

  Future<ApiResponse> unregister() async {
    final accessToken =
        await AppGlobals.secureStorage.read(key: 'access_token');
    return ApiResponse.fromHttpResponse(
      await this._delete('/v1/auth/users',
          headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<ApiResponse> getUsernameAvailable(String username) async {
    return ApiResponse.fromHttpResponse(
      await this._get('/v1/auth/users/$username'),
    );
  }

  Future<ApiResponse> login(String username, String password) async {
    return ApiResponse.fromHttpResponse(
      await this._post('/v1/auth/sessions',
          body: json.encode({
            'username': username,
            'password': password,
          }),
          headers: {'Content-type': 'application/json'}),
    );
  }
}
