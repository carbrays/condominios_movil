import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../api/api_client.dart';

enum ConnectivityState { online, offline, syncing }

class OfflineSyncService {
  final ApiClient apiClient;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  OfflineSyncService({required this.apiClient});

  /// Registra una operación localmente en SQLite
  Future<String> enqueueOperation({
    required String tipo,
    required int condominioId,
    required Map<String, dynamic> payload,
  }) async {
    final syncUuid = const Uuid().v4();
    await dbHelper.insertSyncItem({
      'sync_uuid': syncUuid,
      'tipo': tipo,
      'condominio_id': condominioId,
      'payload': jsonEncode(payload),
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Intentar sincronizar de inmediato en background si hay conexión
    syncPending(condominioId);

    return syncUuid;
  }

  /// Sincroniza todas las operaciones pendientes hacia el backend
  Future<int> syncPending(int condominioId) async {
    final pending = await dbHelper.getPendingItems(condominioId);
    if (pending.isEmpty) return 0;

    final batch = pending.map((item) {
      return {
        'sync_uuid': item['sync_uuid'],
        'tipo': item['tipo'],
        'payload': jsonDecode(item['payload'] as String),
      };
    }).toList();

    try {
      // Marcar como SYNCING
      for (final item in pending) {
        await dbHelper.updateItemStatus(item['sync_uuid'] as String, 'SYNCING');
      }

      final res = await apiClient.post('/conserjeria/offline/sync', {
        'operaciones': batch,
      });

      // Procesar confirmaciones
      if (res is List) {
        for (final r in res) {
          final syncUuid = r['sync_uuid'] as String?;
          final status = r['status'] as String? ?? 'SYNCED';
          final error = r['error'] as String?;
          if (syncUuid != null) {
            await dbHelper.updateItemStatus(syncUuid, status, errorMessage: error);
          }
        }
      }

      return pending.length;
    } catch (e) {
      // Volver a estado PENDING o ERROR para reintentar luego
      for (final item in pending) {
        await dbHelper.updateItemStatus(
          item['sync_uuid'] as String,
          'ERROR',
          errorMessage: e.toString(),
        );
      }
      return 0;
    }
  }

  Future<int> getPendingCount(int condominioId) async {
    return dbHelper.getPendingCount(condominioId);
  }
}
