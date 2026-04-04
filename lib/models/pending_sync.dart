/// Offline-first pending sync queue — local only
class PendingSync {
  final String id;
  final String tableName;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  PendingSync({
    required this.id,
    required this.tableName,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory PendingSync.fromJson(Map<String, dynamic> j) => PendingSync(
        id: j['id'],
        tableName: j['table_name'],
        operation: j['operation'],
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        createdAt: DateTime.parse(j['created_at']),
        retryCount: j['retry_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_name': tableName,
        'operation': operation,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  PendingSync copyWith({
    int? retryCount,
  }) {
    return PendingSync(
      id: id,
      tableName: tableName,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
