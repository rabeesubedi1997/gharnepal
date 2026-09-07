/// Mirrors the `AuthUser` shape returned by `UserResource` on the backend
/// and consumed as `AuthUser` in frontend/src/lib/api/auth.ts.
class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.locale,
    required this.emailVerified,
    required this.phoneVerified,
    required this.roles,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      locale: json['locale'] as String? ?? 'en',
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String locale;
  final bool emailVerified;
  final bool phoneVerified;
  final List<String> roles;

  bool hasRole(String role) => roles.contains(role);

  bool get isAdmin => hasRole('admin');
}
