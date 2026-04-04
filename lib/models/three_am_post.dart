class ThreeAmPost {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? outcomeText;
  final bool isVisible;

  ThreeAmPost({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.resolvedAt,
    this.outcomeText,
    this.isVisible = false,
  });

  bool get isResolved => resolvedAt != null;

  factory ThreeAmPost.fromJson(Map<String, dynamic> json) => ThreeAmPost(
        id: json['id'],
        userId: json['user_id'],
        createdAt: DateTime.parse(json['created_at']),
        resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
        outcomeText: json['outcome_text'],
        isVisible: json['is_visible'] ?? false,
      );
}
