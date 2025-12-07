import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(const AuthState()) {
    _loadCachedToken();
  }

  Future<void> _loadCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final expiryStr = prefs.getString('token_expiry');

      if (token != null && expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (expiry.isAfter(DateTime.now())) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            tokenExpiry: expiry,
          ));
          return;
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<String> getToken() async {
    // If we have a valid token, return it
    if (state.isAuthenticated) {
      return state.token!;
    }

    // Otherwise, fetch a new token
    return await authenticate();
  }

  Future<String> authenticate() async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final response = await authRepository.getAccessToken();

      final token = response['access_token'] as String;
      final expiresIn = response['expires_in'] as int;
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));

      // Cache the token
      await _cacheToken(token, expiry);

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        tokenExpiry: expiry,
        errorMessage: null,
      ));

      return token;
    } catch (e) {
      final errorMessage = 'Authentication failed: ${e.toString()}';
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      ));
      throw Exception(errorMessage);
    }
  }

  Future<void> _cacheToken(String token, DateTime expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('token_expiry', expiry.toIso8601String());
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('token_expiry');
    } catch (e) {
      // Ignore errors
    }

    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}