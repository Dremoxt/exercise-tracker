import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'secure_logger.dart';
import 'dart:async';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription? _recordsSubscription;
  StreamSubscription? _settingsSubscription;
  
  Function(List<DailyRecord>)? onRecordsChanged;
  Function(AppSettings)? onSettingsChanged;
  Function(WeekdayGoals)? onWeekdayGoalsChanged;
  Function(List<ExerciseCategory>)? onCategoriesChanged;

  /// Get current user ID (must be signed in)
  String? get userId => _auth.currentUser?.uid;
  
  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get user's data collection reference
  CollectionReference? _getUserCollection(String collection) {
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection(collection);
  }

  // ============ Real-time Listeners ============

  /// Start listening to changes (call after sign in)
  void startRealtimeSync() {
    if (userId == null) return;
    
    // Listen to daily records
    _recordsSubscription = _getUserCollection('daily_records')
        ?.snapshots()
        .listen((snapshot) {
      final records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _recordFromFirestore(data);
      }).toList();
      
      onRecordsChanged?.call(records);
    });
    
    // Listen to settings
    _settingsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      
      if (data['settings'] != null) {
        final settings = _settingsFromFirestore(data['settings']);
        onSettingsChanged?.call(settings);
      }
      
      if (data['weekdayGoals'] != null) {
        final goals = _weekdayGoalsFromFirestore(data['weekdayGoals']);
        onWeekdayGoalsChanged?.call(goals);
      }
    });
  }

  /// Stop listening (call on sign out)
  void stopRealtimeSync() {
    _recordsSubscription?.cancel();
    _settingsSubscription?.cancel();
    _recordsSubscription = null;
    _settingsSubscription = null;
  }

  // ============ Converters ============

  DailyRecord _recordFromFirestore(Map<String, dynamic> data) {
    return DailyRecord(
      id: data['id'],
      date: (data['date'] as Timestamp).toDate(),
      categoryProgress: (data['categoryProgress'] as List).map((cp) {
        return CategoryProgress(
          categoryId: cp['categoryId'],
          strokesCompleted: cp['strokesCompleted'],
        );
      }).toList(),
      targetSetsPerCategory: data['targetSetsPerCategory'],
      totalCategories: data['totalCategories'],
      hasGoal: data['hasGoal'] ?? true,
    );
  }

  AppSettings _settingsFromFirestore(Map<String, dynamic> data) {
    return AppSettings(
      targetSetsPerCategory: data['targetSetsPerCategory'] ?? 4,
      repsPerSet: data['repsPerSet'] ?? 25,
      darkMode: data['darkMode'] ?? false,
    );
  }

  WeekdayGoals _weekdayGoalsFromFirestore(Map<String, dynamic> data) {
    final weekdaySetsRaw = data['weekdaySets'] as Map<String, dynamic>?;
    
    Map<int, int> weekdaySets = {};
    if (weekdaySetsRaw != null) {
      weekdaySetsRaw.forEach((k, v) {
        weekdaySets[int.parse(k)] = v as int;
      });
    }
    
    return WeekdayGoals(
      useWeekdayGoals: data['useWeekdayGoals'] ?? false,
      defaultSetsPerCategory: data['defaultSetsPerCategory'] ?? 4,
      weekdaySets: weekdaySets.isEmpty ? null : weekdaySets,
    );
  }

  // ============ Sync Daily Records ============

  /// Upload a daily record to cloud (auto-called on changes)
  Future<void> syncDailyRecord(DailyRecord record) async {
    if (userId == null) return;
    
    try {
      final collection = _getUserCollection('daily_records');
      
      await collection?.doc(record.id).set({
        'id': record.id,
        'date': Timestamp.fromDate(record.date),
        'categoryProgress': record.categoryProgress.map((cp) => {
          'categoryId': cp.categoryId,
          'strokesCompleted': cp.strokesCompleted,
        }).toList(),
        'targetSetsPerCategory': record.targetSetsPerCategory,
        'totalCategories': record.totalCategories,
        'hasGoal': record.hasGoal,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.syncDailyRecord', e, stackTrace);
    }
  }

  /// Download all daily records from cloud
  Future<List<DailyRecord>> downloadDailyRecords() async {
    if (userId == null) return [];
    
    try {
      final collection = _getUserCollection('daily_records');
      final snapshot = await collection?.get();
      
      if (snapshot == null) return [];
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _recordFromFirestore(data);
      }).toList();
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.downloadDailyRecords', e, stackTrace);
      return [];
    }
  }

  // ============ Sync Categories ============

  /// Upload categories to cloud
  Future<void> syncCategories(List<ExerciseCategory> categories) async {
    if (userId == null) return;
    
    try {
      final collection = _getUserCollection('categories');
      
      for (final category in categories) {
        await collection?.doc(category.id).set({
          'id': category.id,
          'name': category.name,
          'icon': category.icon,
          'displayOrder': category.displayOrder,
          'isActive': category.isActive,
          'lastModified': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.syncCategories', e, stackTrace);
    }
  }

  /// Download categories from cloud
  Future<List<ExerciseCategory>> downloadCategories() async {
    if (userId == null) return [];
    
    try {
      final collection = _getUserCollection('categories');
      final snapshot = await collection?.orderBy('displayOrder').get();
      
      if (snapshot == null) return [];
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExerciseCategory(
          id: data['id'],
          name: data['name'],
          icon: data['icon'],
          displayOrder: data['displayOrder'],
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.downloadCategories', e, stackTrace);
      return [];
    }
  }

  // ============ Sync Settings ============

  /// Upload settings to cloud
  Future<void> syncSettings(AppSettings settings) async {
    if (userId == null) return;
    
    try {
      await _firestore.collection('users').doc(userId).set({
        'settings': {
          'targetSetsPerCategory': settings.targetSetsPerCategory,
          'repsPerSet': settings.repsPerSet,
          'darkMode': settings.darkMode,
          'lastModified': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.syncSettings', e, stackTrace);
    }
  }

  /// Download settings from cloud
  Future<AppSettings?> downloadSettings() async {
    if (userId == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists || doc.data()?['settings'] == null) return null;
      
      return _settingsFromFirestore(doc.data()!['settings']);
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.downloadSettings', e, stackTrace);
      return null;
    }
  }

  // ============ Sync Weekday Goals ============

  /// Upload weekday goals to cloud
  Future<void> syncWeekdayGoals(WeekdayGoals goals) async {
    if (userId == null) return;
    
    try {
      await _firestore.collection('users').doc(userId).set({
        'weekdayGoals': {
          'useWeekdayGoals': goals.useWeekdayGoals,
          'defaultSetsPerCategory': goals.defaultSetsPerCategory,
          'weekdaySets': goals.weekdaySets.map((k, v) => MapEntry(k.toString(), v)),
          'lastModified': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.syncWeekdayGoals', e, stackTrace);
    }
  }

  /// Download weekday goals from cloud
  Future<WeekdayGoals?> downloadWeekdayGoals() async {
    if (userId == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists || doc.data()?['weekdayGoals'] == null) return null;
      
      return _weekdayGoalsFromFirestore(doc.data()!['weekdayGoals']);
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.downloadWeekdayGoals', e, stackTrace);
      return null;
    }
  }

  // ============ Full Sync ============

  /// Sync all data to cloud
  Future<void> syncAllToCloud({
    required List<DailyRecord> records,
    required List<ExerciseCategory> categories,
    required AppSettings settings,
    required WeekdayGoals weekdayGoals,
  }) async {
    await syncSettings(settings);
    await syncWeekdayGoals(weekdayGoals);
    await syncCategories(categories);
    
    for (final record in records) {
      await syncDailyRecord(record);
    }
    
    await updateLastSyncTime();
  }

  /// Check if user has cloud data
  Future<bool> hasCloudData() async {
    if (userId == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    if (userId == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return null;
      
      final timestamp = doc.data()?['lastSync'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    if (userId == null) return;
    
    try {
      await _firestore.collection('users').doc(userId).set({
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      SecureLogger.error('CloudSyncService.updateLastSyncTime', e, stackTrace);
    }
  }
}
