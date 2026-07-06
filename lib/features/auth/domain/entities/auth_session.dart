import 'package:equatable/equatable.dart';

/// The result of a successful login/register: the tokens the app persists.
/// Kept minimal until the real `/auth/login` response shape is captured — the
/// exact token field(s) are confirmed there, then mapped into this entity.
class AuthSession extends Equatable {
  final String accessToken;
  final String? refreshToken;

  const AuthSession({required this.accessToken, this.refreshToken});

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
