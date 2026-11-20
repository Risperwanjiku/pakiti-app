import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import 'package:pakiti_app/config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  // one message per field, using the same names as the API, like 'receiver_phone'
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._(this._client);

  static final instance = ApiClient._(http.Client());

  // lets tests answer the requests themselves, without a server
  @visibleForTesting
  factory ApiClient.withClient(http.Client client) => ApiClient._(client);

  final http.Client _client;
  String? token;

  Future<Map<String, dynamic>> get(String path) {
    return _send(() => _client.get(url(path), headers: _headers()));
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic> body = const {},
  ]) {
    return _send(
      () => _client.post(url(path), headers: _headers(), body: jsonEncode(body)),
    );
  }

  // for requests with a file, like the parcel photo
  Future<Map<String, dynamic>> postForm(
    String path, {
    required Map<String, String> fields,
    Map<String, String> files = const {},
  }) {
    return _send(
      () async {
        final request = http.MultipartRequest('POST', url(path))
          ..headers.addAll(_headers(json: false))
          ..fields.addAll(fields);

        for (final file in files.entries) {
          request.files.add(await http.MultipartFile.fromPath(file.key, file.value));
        }

        return http.Response.fromStream(await _client.send(request));
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // Images load through their own requests, so they need the address and the token from here.
  Uri url(String path) => Uri.parse('$apiBaseUrl$path');

  Map<String, String> get authHeader {
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Map<String, String> _headers({bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...authHeader,
    };
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final http.Response response;

    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('The server is taking too long. Please try again.');
    } on http.ClientException {
      throw const ApiException("Can't reach the server. Check your connection and try again.");
    }

    final Object? body;

    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server sent a reply the app could not read.',
        statusCode: response.statusCode,
      );
    }

    if (body is! Map<String, dynamic>) {
      throw ApiException(
        'The server sent a reply the app could not read.',
        statusCode: response.statusCode,
      );
    }

    if (body['ok'] != true) {
      final errors = body['errors'];

      throw ApiException(
        body['error'] as String? ?? 'Something went wrong. Please try again.',
        statusCode: response.statusCode,
        fieldErrors: errors is Map<String, dynamic>
            ? errors.map((field, message) => MapEntry(field, '$message'))
            : const {},
      );
    }

    return body['data'] as Map<String, dynamic>;
  }
}