// lib/features/home/data/repositories/base_sync_repository.dart

import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:sync1_client/sync1_client.dart' as serverpod;
import '../datasources/local/tables/category_table.dart';

/// 2. Базовый класс, содержащий всю общую логику синхронизации
abstract class BaseSyncRepository<
    TEntity,
    TLocalCompanion extends UpdateCompanion,
    TLocalData extends DataClass,
    TServerModel extends serverpod.SerializableModel,
    TEvent> {
  
  final dynamic remoteDataSource;
  final dynamic syncMetadataDao;
  final dynamic localDao;
  final GeneratedDatabase db;
  final int userId;

  bool _isSyncing = false;
  bool _isDisposed = false;
  StreamSubscription? _eventStreamSubscription;
  int reconnectionAttempt = 0;

  BaseSyncRepository({
    required this.remoteDataSource,
    required this.syncMetadataDao,
    required this.localDao,
    required this.db,
    required this.userId,
  }) {
    initEventBasedSync();
  }

  // --- Абстрактные методы для реализации в дочерних классах ---
  
  String get entityType;
  
  // Методы конвертации
  TEntity localDataToEntity(TLocalData data);
  List<TEntity> localDataListToEntities(List<TLocalData> dataList);
  TLocalCompanion entityToCompanion(TEntity entity, SyncStatus status);
  
  // Методы для получения данных с локальных источников
  String getLocalDataId(TLocalData data);
  SyncStatus getLocalDataSyncStatus(TLocalData data);
  DateTime getLocalDataLastModified(TLocalData data);
  
  // Методы для работы с сервером
  Future<List<TServerModel>> fetchServerChanges(DateTime? since);
  Future<List<TLocalData>> getLocalChangesForPush();
  Future<void> handleSyncEvent(TEvent event);
  Stream<TEvent> watchRemoteEvents();
  
  // Методы для синхронизации с сервером
  Future<void> pushLocalChanges(List<TLocalData> changesToPush);
  Future<List<TLocalData>> reconcileChanges(List<TServerModel> serverChanges);

  // --- ОБЩАЯ ЛОГИКА СИНХРОНИЗАЦИИ ---
  
  Future<void> syncWithServer() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final lastSync = await syncMetadataDao.getLastSyncTimestamp(entityType, userId: userId);
      final serverChanges = await fetchServerChanges(lastSync);
      final localChangesToPush = await reconcileChanges(serverChanges);
      
      if (localChangesToPush.isNotEmpty) {
        await pushLocalChanges(localChangesToPush);
      }
      
      await syncMetadataDao.updateLastSyncTimestamp(entityType, DateTime.now().toUtc(), userId: userId);
      
    } catch (e) {
      // В продакшене здесь должно быть логирование через logger
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  // --- ОБЩАЯ ЛОГИКА ПОДПИСКИ НА СОБЫТИЯ ---
  
  void initEventBasedSync() {
    if (_isDisposed) return;
    _eventStreamSubscription?.cancel();
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    if (_isDisposed) return;
    
    _eventStreamSubscription = watchRemoteEvents().listen(
      (event) {
        if (reconnectionAttempt > 0) {
          reconnectionAttempt = 0;
        }
        handleSyncEvent(event);
      },
      onError: (error) => _scheduleReconnection(),
      onDone: () => _scheduleReconnection(),
      cancelOnError: true,
    );
  }

  void _scheduleReconnection() {
    if (_isDisposed) return;
    _eventStreamSubscription?.cancel();
    
    final delaySeconds = min(pow(2, reconnectionAttempt).toInt(), 60);
    
    Future.delayed(Duration(seconds: delaySeconds), () {
      reconnectionAttempt++;
      initEventBasedSync();
    });
  }

  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _eventStreamSubscription?.cancel();
    }
  }
}