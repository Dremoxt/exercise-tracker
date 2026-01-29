import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import '../config/environment.dart';

/// Main state provider for the exercise tracker app
class ExerciseProvider extends ChangeNotifier {
  final DatabaseService _db;

  // Cloud services - only initialized in production mode
  CloudSyncService? _cloudSync;
  AuthService? _auth;
  
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSyncTime;
  
  // Current data
  List<ExerciseCategory> _categories = [];
  DailyRecord? _todayRecord;
  AppSettings _settings = AppSettings();
  WeekdayGoals _weekdayGoals = WeekdayGoals();
  DateTime _selectedDate = DateTime.now();
  
  // History data
  List<MonthlySummary> _monthlySummaries = [];
  MonthlySummary? _personalBest;

  ExerciseProvider(this._db);

  // ============ Getters ============
  
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<ExerciseCategory> get categories => _categories;
  DailyRecord? get todayRecord => _todayRecord;
  AppSettings get settings => _settings;
  WeekdayGoals get weekdayGoals => _weekdayGoals;
  DateTime get selectedDate => _selectedDate;
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  MonthlySummary? get personalBest => _personalBest;
  
  // Auth getters (always false/null in QA mode)
  bool get isSignedIn => _auth?.isSignedIn ?? false;
  String? get userName => _auth?.userName;
  String? get userEmail => _auth?.userEmail;
  String? get userPhotoUrl => _auth?.userPhotoUrl;

  // Check if cloud features are available
  bool get isCloudAvailable => !EnvironmentConfig.skipFirebase;

  /// Get target sets for selected date
  int get targetSetsForSelectedDate {
    return _weekdayGoals.getSetsForDate(_selectedDate);
  }

  /// Check if selected date has a goal
  bool get selectedDateHasGoal {
    return _weekdayGoals.hasGoalForDate(_selectedDate);
  }

  /// Get strokes for a specific category today
  int getStrokesForCategory(String categoryId) {
    if (_todayRecord == null) return 0;
    
    final progress = _todayRecord!.categoryProgress
        .firstWhere(
          (cp) => cp.categoryId == categoryId,
          orElse: () => CategoryProgress(categoryId: categoryId),
        );
    return progress.strokesCompleted;
  }

  /// Get today's achievement percentage
  double get todayPercentage {
    return _todayRecord?.achievementPercentage ?? 0;
  }

  /// Get current month summary
  MonthlySummary get currentMonthSummary {
    final now = DateTime.now();
    return _db.getMonthlySummary(now.year, now.month);
  }

  /// Get current week summary (Monday to Sunday)
  double get currentWeekPercentage {
    return _db.getWeeklySummary();
  }

  // ============ Initialization ============

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize cloud services only in production mode
      if (!EnvironmentConfig.skipFirebase) {
        _cloudSync = CloudSyncService();
        _auth = AuthService();
      }

      await _db.initialize();
      await _loadData();

      // Check if already signed in and start sync (production only)
      if (_auth?.isSignedIn ?? false) {
        _setupRealtimeSync();
        _lastSyncTime = await _cloudSync?.getLastSyncTime();
      }

      _isLoading = false;
    } catch (e) {
      _error = 'Failed to initialize: $e';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<void> _loadData() async {
    _categories = _db.getActiveCategories();
    _settings = _db.getSettings();
    _weekdayGoals = _db.getWeekdayGoals();
    _todayRecord = _db.getOrCreateRecord(_selectedDate);
    _monthlySummaries = _db.getAllMonthlySummaries();
    _personalBest = _db.getPersonalBest();
  }

  Future<void> refresh() async {
    await _loadData();
    notifyListeners();
  }

  // ============ Auth Operations ============

  Future<void> signInWithGoogle() async {
    if (_auth == null || _cloudSync == null) return; // Not available in QA mode

    try {
      _isSyncing = true;
      notifyListeners();

      final result = await _auth!.signInWithGoogle();

      if (result != null) {
        // Check if cloud has data
        final hasCloud = await _cloudSync!.hasCloudData();

        if (hasCloud) {
          // Download from cloud
          await syncFromCloud();
        } else {
          // Upload local data to cloud
          await syncToCloud();
        }

        // Start real-time sync
        _setupRealtimeSync();
        _lastSyncTime = DateTime.now();
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _error = 'Sign in failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_auth == null) return; // Not available in QA mode

    try {
      _cloudSync?.stopRealtimeSync();
      await _auth!.signOut();
      _lastSyncTime = null;
      notifyListeners();
    } catch (e) {
      _error = 'Sign out failed: $e';
      notifyListeners();
    }
  }

  void _setupRealtimeSync() {
    if (_cloudSync == null) return; // Not available in QA mode

    // Set up callbacks for real-time updates
    _cloudSync!.onRecordsChanged = (records) async {
      for (final record in records) {
        await _db.importRecord(record);
      }
      await _loadData();
      notifyListeners();
    };

    _cloudSync!.onSettingsChanged = (settings) async {
      await _db.updateSettings(settings);
      _settings = settings;
      notifyListeners();
    };

    _cloudSync!.onWeekdayGoalsChanged = (goals) async {
      await _db.updateWeekdayGoals(goals);
      _weekdayGoals = goals;
      notifyListeners();
    };

    _cloudSync!.startRealtimeSync();
  }

  // ============ Stroke Operations ============

  Future<void> addStroke(String categoryId) async {
    try {
      await _db.incrementStrokes(
        date: _selectedDate,
        categoryId: categoryId,
      );
      
      _todayRecord = _db.getOrCreateRecord(_selectedDate);
      _monthlySummaries = _db.getAllMonthlySummaries();
      _personalBest = _db.getPersonalBest();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn && _todayRecord != null) {
        _cloudSync?.syncDailyRecord(_todayRecord!);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add stroke: $e';
      notifyListeners();
    }
  }

  Future<void> removeStroke(String categoryId) async {
    try {
      await _db.decrementStrokes(
        date: _selectedDate,
        categoryId: categoryId,
      );
      
      _todayRecord = _db.getOrCreateRecord(_selectedDate);
      _monthlySummaries = _db.getAllMonthlySummaries();
      _personalBest = _db.getPersonalBest();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn && _todayRecord != null) {
        _cloudSync?.syncDailyRecord(_todayRecord!);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove stroke: $e';
      notifyListeners();
    }
  }

  Future<void> setStrokes(String categoryId, int strokes) async {
    try {
      final maxStrokes = _todayRecord?.targetSetsPerCategory ?? _weekdayGoals.getSetsForDate(_selectedDate);
      await _db.updateStrokes(
        date: _selectedDate,
        categoryId: categoryId,
        strokes: strokes.clamp(0, maxStrokes),
      );
      
      _todayRecord = _db.getOrCreateRecord(_selectedDate);
      _monthlySummaries = _db.getAllMonthlySummaries();
      _personalBest = _db.getPersonalBest();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn && _todayRecord != null) {
        _cloudSync?.syncDailyRecord(_todayRecord!);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set strokes: $e';
      notifyListeners();
    }
  }

  // ============ Date Selection ============

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _todayRecord = _db.getOrCreateRecord(_selectedDate);
    notifyListeners();
  }

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
           _selectedDate.month == now.month &&
           _selectedDate.day == now.day;
  }

  // ============ Settings Operations ============

  Future<void> updateTargetSets(int targetSets) async {
    try {
      final newSettings = _settings.copyWith(targetSetsPerCategory: targetSets);
      await _db.updateSettings(newSettings);
      _settings = newSettings;
      
      // Also update weekday goals default
      if (!_weekdayGoals.useWeekdayGoals) {
        final newGoals = _weekdayGoals.copyWith(defaultSetsPerCategory: targetSets);
        await _db.updateWeekdayGoals(newGoals);
        _weekdayGoals = newGoals;
      }
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncSettings(_settings);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update settings: $e';
      notifyListeners();
    }
  }

  Future<void> updateRepsPerSet(int reps) async {
    try {
      final newSettings = _settings.copyWith(repsPerSet: reps);
      await _db.updateSettings(newSettings);
      _settings = newSettings;
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncSettings(_settings);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update settings: $e';
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode() async {
    try {
      final newSettings = _settings.copyWith(darkMode: !_settings.darkMode);
      await _db.updateSettings(newSettings);
      _settings = newSettings;
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncSettings(_settings);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle dark mode: $e';
      notifyListeners();
    }
  }

  // ============ Weekday Goals Operations ============

  Future<void> updateWeekdayGoals(WeekdayGoals goals) async {
    try {
      await _db.updateWeekdayGoals(goals);
      _weekdayGoals = goals;
      
      // Refresh today's record with new goals
      _todayRecord = _db.getOrCreateRecord(_selectedDate);
      _monthlySummaries = _db.getAllMonthlySummaries();
      _personalBest = _db.getPersonalBest();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncWeekdayGoals(_weekdayGoals);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update weekday goals: $e';
      notifyListeners();
    }
  }

  Future<void> toggleUseWeekdayGoals(bool value) async {
    try {
      final newGoals = _weekdayGoals.copyWith(useWeekdayGoals: value);
      await updateWeekdayGoals(newGoals);
    } catch (e) {
      _error = 'Failed to toggle weekday goals: $e';
      notifyListeners();
    }
  }

  Future<void> setWeekdaySets(int weekday, int sets) async {
    try {
      final newWeekdaySets = Map<int, int>.from(_weekdayGoals.weekdaySets);
      newWeekdaySets[weekday] = sets;
      final newGoals = _weekdayGoals.copyWith(weekdaySets: newWeekdaySets);
      await updateWeekdayGoals(newGoals);
    } catch (e) {
      _error = 'Failed to set weekday sets: $e';
      notifyListeners();
    }
  }

  // ============ Category Operations ============

  Future<void> addCategory({
    required String name,
    required String icon,
  }) async {
    try {
      final id = name.toLowerCase().replaceAll(' ', '_');
      final newCategory = ExerciseCategory(
        id: id,
        name: name,
        icon: icon,
        displayOrder: _categories.length,
      );
      
      await _db.addCategory(newCategory);
      _categories = _db.getActiveCategories();
      _todayRecord = _db.getOrCreateRecord(_selectedDate);
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncCategories(_categories);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add category: $e';
      notifyListeners();
    }
  }

  Future<void> updateCategory(ExerciseCategory category) async {
    try {
      await _db.updateCategory(category);
      _categories = _db.getActiveCategories();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncCategories(_categories);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _db.deleteCategory(categoryId);
      _categories = _db.getActiveCategories();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncCategories(_categories);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
    }
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    try {
      final categoryIds = _categories.map((c) => c.id).toList();
      
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      final item = categoryIds.removeAt(oldIndex);
      categoryIds.insert(newIndex, item);
      
      await _db.reorderCategories(categoryIds);
      _categories = _db.getActiveCategories();
      
      // Auto-sync to cloud if signed in
      if (isSignedIn) {
        _cloudSync?.syncCategories(_categories);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reorder categories: $e';
      notifyListeners();
    }
  }

  // ============ History Operations ============

  MonthlySummary getMonthlySummary(int year, int month) {
    return _db.getMonthlySummary(year, month);
  }

  /// Get category stats for a period (1, 3, 6, or 12 months)
  List<CategoryMonthlyStats> getCategoryStatsForPeriod(int periodMonths) {
    return _db.getCategoryStatsForPeriod(periodMonths);
  }

  DailyRecord? getRecordForDate(DateTime date) {
    return _db.getRecord(date);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============ Cloud Sync Operations ============

  /// Upload all data to cloud
  Future<void> syncToCloud() async {
    if (!isSignedIn || _cloudSync == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final allRecords = _db.getAllRecords();

      await _cloudSync!.syncAllToCloud(
        records: allRecords,
        categories: _categories,
        settings: _settings,
        weekdayGoals: _weekdayGoals,
      );

      _lastSyncTime = DateTime.now();

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _error = 'Sync failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Download all data from cloud
  Future<void> syncFromCloud() async {
    if (!isSignedIn || _cloudSync == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Download settings
      final cloudSettings = await _cloudSync!.downloadSettings();
      if (cloudSettings != null) {
        await _db.updateSettings(cloudSettings);
        _settings = cloudSettings;
      }

      // Download weekday goals
      final cloudGoals = await _cloudSync!.downloadWeekdayGoals();
      if (cloudGoals != null) {
        await _db.updateWeekdayGoals(cloudGoals);
        _weekdayGoals = cloudGoals;
      }

      // Download categories
      final cloudCategories = await _cloudSync!.downloadCategories();
      if (cloudCategories.isNotEmpty) {
        for (final category in cloudCategories) {
          await _db.addCategory(category);
        }
        _categories = _db.getActiveCategories();
      }

      // Download daily records
      final cloudRecords = await _cloudSync!.downloadDailyRecords();
      for (final record in cloudRecords) {
        await _db.importRecord(record);
      }

      // Refresh local data
      await _loadData();

      _lastSyncTime = await _cloudSync!.getLastSyncTime();

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _error = 'Download failed: $e';
      notifyListeners();
      rethrow;
    }
  }
}
