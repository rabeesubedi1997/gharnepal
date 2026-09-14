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
    this.agency,
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
      agency: json['agency'] != null ? AuthUserAgencyRef.fromJson(json['agency'] as Map<String, dynamic>) : null,
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
  // Just enough to decide whether to show the agency dashboard nav entry —
  // mirrors `UserResource::agency` (`only(['id','name','slug'])`). A user
  // can only ever have at most one membership handled anywhere in this
  // product yet (see AgencyDashboardController), so this is never a list.
  final AuthUserAgencyRef? agency;

  bool hasRole(String role) => roles.contains(role);

  /// A super admin has every admin permission plus a few reserved to it
  /// alone (granting/revoking admin access, payment refunds) — see
  /// AdminUsersScreen and AdminPaymentsScreen.
  bool get isAdmin => hasRole('admin') || hasRole('super_admin');

  bool get isSuperAdmin => hasRole('super_admin');
}

class AuthUserAgencyRef {
  AuthUserAgencyRef({required this.id, required this.name, required this.slug});

  factory AuthUserAgencyRef.fromJson(Map<String, dynamic> json) {
    return AuthUserAgencyRef(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  final int id;
  final String name;
  final String slug;
}
