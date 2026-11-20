import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/services/api_client.dart';

class AuthService {
  AuthService({ApiClient? api, FlutterSecureStorage? storage})
      : _api = api ?? ApiClient.instance,
        _storage = storage ?? FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<StaffUser> login(String phone, String password) async {
    final data = await _api.post('/auth/login', {
      'phone': phone,
      'password': password,
    });

    final token = data['token'] as String;
    await _storage.write(key: _tokenKey, value: token);
    _api.token = token;

    return StaffUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<StaffUser?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      return null;
    }

    _api.token = token;

    try {
      final data = await _api.get('/auth/me');
      return StaffUser.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearToken();
        return null;
      }
      rethrow;
    }
  }

  // a wrong current password comes back as an ApiException with a 'current_password' field error
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post('/auth/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // The server is told without waiting for it, so Log out is quick even with no signal.
  // The request already has the token, so clearing it straight after is fine.
  Future<void> logout() async {
    unawaited(
      _api.post('/auth/logout').then<void>(
        (_) {},
        onError: (Object error) => debugPrint('Server logout failed: $error'),
      ),
    );
    await _clearToken();
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: _tokenKey);
    _api.token = null;
  }
}