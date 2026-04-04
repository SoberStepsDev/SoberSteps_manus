class FutureLetter {
  final String id;
  final String userId;
  final String content;
  final DateTime deliverAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;

  FutureLetter({
    required this.id,
    required this.userId,
    required this.content,
    required this.deliverAt,
    this.deliveredAt,
    required this.createdAt,
  });

  bool get isDelivered => deliveredAt != null || DateTime.now().isAfter(deliverAt);

  factory FutureLetter.fromJson(Map<String, dynamic> json) => FutureLetter(
        id: json['id'],
        userId: json['user_id'],
        content: json['content'],
        deliverAt: DateTime.parse(json['deliver_at']),
        deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'content': content,
        'deliver_at': deliverAt.toIso8601String().split('T')[0],
      };
}
