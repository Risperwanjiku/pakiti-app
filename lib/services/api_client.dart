import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final instance = ApiClient._();

  final _client = http.Client();
  String? token;

  Future<Map<String, dynamic>> get(String path) {
    return _send(() => _client.get(_url(path), headers: _headers()));
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic> body = const {},
  ]) {
    return _send(
      () => _client.post(_url(path), headers: _headers(), body: jsonEncode(body)),
    );
  }

  Uri _url(String path) => Uri.parse('$apiBaseUrl$path');

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;

    try {
      response = await request().timeout(const Duration(seconds: 15));
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
      throw ApiException(
        body['error'] as String? ?? 'Something went wrong. Please try again.',
        statusCode: response.statusCode,
      );
    }

    return body['data'] as Map<String, dynamic>;
  }
}