class CommunityPost {
  final String id;
  final String userId;
  final String category;
  final String content;
  final int likesCount;
  final bool isFlagged;
  final int flagCount;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.category,
    required this.content,
    this.likesCount = 0,
    this.isFlagged = false,
    this.flagCount = 0,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'],
        userId: json['user_id'],
        category: json['category'],
        content: json['content'],
        likesCount: json['likes_count'] ?? 0,
        isFlagged: json['is_flagged'] ?? false,
        flagCount: json['flag_count'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'category': category,
        'content': content,
      };
}
