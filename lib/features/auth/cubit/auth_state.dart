import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final DateTime? tokenExpiry;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.tokenExpiry,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
          token != null &&
          (tokenExpiry?.isAfter(DateTime.now()) ?? false);

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    DateTime? tokenExpiry,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, token, tokenExpiry, errorMessage];
}