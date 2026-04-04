import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/pending_sync.dart';
import 'crash_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  static const _queueKey = 'sync_queue_v1';
  static const _maxRetries = 5;
  bool _processing = false;
  bool _listening = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void init() => startListening();

  Future<void> addToQueue(
    String table,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    final queue = await _readQueue();
    queue.add(
      PendingSync(
        id: const Uuid().v4(),
        tableName: table,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
    await _writeQueue(queue);
  }

  void startListening() {
    if (_listening) return;
    _listening = true;
    processQueue();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        processQueue();
      }
    });
  }

  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = await _readQueue();
      if (queue.isEmpty) return;
      final client = Supabase.instance.client;
      final remaining = <PendingSync>[];
      for (final item in queue) {
        try {
          switch (item.operation) {
            case 'insert':
            case 'update':
              await client.from(item.tableName).upsert(item.payload);
              break;
            case 'delete':
              final id = item.payload['id'];
              if (id == null || '$id'.isEmpty) {
                throw const FormatException('Missing id for delete');
              }
              await client.from(item.tableName).delete().eq('id', id);
              break;
            default:
              throw FormatException('Unknown operation: ${item.operation}');
          }
        } catch (e, st) {
          final retried = item.copyWith(retryCount: item.retryCount + 1);
          if (retried.retryCount <= _maxRetries) {
            remaining.add(retried);
          } else {
            await CrashService.recordError(e, st);
          }
        }
      }
      await _writeQueue(remaining);
    } finally {
      _processing = false;
    }
  }

  Future<List<PendingSync>> _readQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(PendingSync.fromJson).toList();
  }

  Future<void> _writeQueue(List<PendingSync> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(queue.map((e) => e.toJson()).toList()));
  }

  void dispose() {
    _connectivitySub?.cancel();
    _listening = false;
  }
}
