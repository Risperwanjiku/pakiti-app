class AuthService {
  Future<bool> login(String phone, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    return false;
  }
}