import '../../../../neighborhoods/data/models/community_note.dart';

/// The `neighborhood` relation embedded on the admin list resource — a
/// flattened `{id, name}` ref, distinct from the full `NeighborhoodWardRef`.
class AdminCommunityNoteNeighborhoodRef {
  AdminCommunityNoteNeighborhoodRef({required this.id, required this.name});

  factory AdminCommunityNoteNeighborhoodRef.fromJson(Map<String, dynamic> json) {
    return AdminCommunityNoteNeighborhoodRef(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Extends the consumer-side `CommunityNote` (imported, unmodified) with the
/// two relations `Admin\CommunityNoteResource` eager-loads that the public
/// resource never returns: `submitted_by` and `neighborhood`.
class AdminCommunityNote extends CommunityNote {
  AdminCommunityNote({
    required super.id,
    required super.neighborhoodId,
    required super.category,
    required super.body,
    required super.status,
    super.rejectionReason,
    required super.createdAt,
    this.submittedByName,
    this.neighborhood,
  });

  factory AdminCommunityNote.fromJson(Map<String, dynamic> json) {
    final base = CommunityNote.fromJson(json);
    final submittedBy = json['submitted_by'] as Map<String, dynamic>?;
    final neighborhood = json['neighborhood'] as Map<String, dynamic>?;
    return AdminCommunityNote(
      id: base.id,
      neighborhoodId: base.neighborhoodId,
      category: base.category,
      body: base.body,
      status: base.status,
      rejectionReason: base.rejectionReason,
      createdAt: base.createdAt,
      submittedByName: submittedBy?['name'] as String?,
      neighborhood: neighborhood != null ? AdminCommunityNoteNeighborhoodRef.fromJson(neighborhood) : null,
    );
  }

  final String? submittedByName;
  final AdminCommunityNoteNeighborhoodRef? neighborhood;
}
