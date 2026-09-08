/// Mirrors `Admin\UserResource` — `GET /admin/users`, `PATCH
/// /admin/users/{id}/status`, `PUT /admin/users/{id}/roles`. All fields are
/// plain-cast (no decimal columns here).
class AdminUser {
  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.roles,
    required this.agencies,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>? ?? const []).map((r) => r.toString()).toList(growable: false),
      agencies: (json['agencies'] as List<dynamic>? ?? const []).map((a) => a.toString()).toList(growable: false),
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String status; // active | suspended | pending
  final bool emailVerified;
  final bool phoneVerified;
  final List<String> roles;
  final List<String> agencies;
  final String createdAt;
}

/// The five role keys the roles editor offers, in display order.
const kAdminUserRoles = ['buyer', 'owner', 'agent', 'agency_admin', 'admin'];

/// The three status filter/values the users list and status toggle use.
const kAdminUserStatuses = ['active', 'suspended', 'pending'];
