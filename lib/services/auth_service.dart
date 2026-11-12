import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/staff_user.dart';
import 'api_client.dart';

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
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException catch (e) {
      debugPrint('Server logout failed: ${e.message}');
    }
    await _clearToken();
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: _tokenKey);
    _api.token = null;
  }
}