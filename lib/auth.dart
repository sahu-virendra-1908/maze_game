import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  String? _token;
  String? _userData;

  AuthProvider() {
    _loadAuthData();
  }

  // Load auth data from storage
  Future<void> _loadAuthData() async {
    _token = await _storage.read(key: _tokenKey);
    _userData = await _storage.read(key: _userDataKey);
    notifyListeners();
  }

  // Store token
  Future<void> storeToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
    notifyListeners();
  }

  // Get token
  String? get token => _token;
  
  Future<String?> getToken() async {
    return _token ?? await _storage.read(key: _tokenKey);
  }

  // Store user data
  Future<void> storeUserData(String userData) async {
    _userData = userData;
    await _storage.write(key: _userDataKey, value: userData);
    notifyListeners();
  }

  // Get user data
  String? get userData => _userData;
  
  Future<String?> getUserData() async {
    return _userData ?? await _storage.read(key: _userDataKey);
  }

  // Clear all auth data (logout)
  Future<void> clearAuthData() async {
    _token = null;
    _userData = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userDataKey);
    notifyListeners();
  }

  // Check if user is logged in
  bool get isLoggedIn => _token != null;
  
  Future<bool> checkLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}