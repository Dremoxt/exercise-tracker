import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../config/environment.dart';
import 'secure_logger.dart';

/// Service class for all database operations with encrypted storage
class DatabaseService {
  // Use different box names for encrypted vs unencrypted to avoid conflicts
  static String get _categoriesBox =>
      EnvironmentConfig.isQA ? 'categories_qa' : 'categories_v2';
  static String get _recordsBox =>
      EnvironmentConfig.isQA ? 'records_qa' : 'records_v2';
  static String get _settingsBox =>
      EnvironmentConfig.isQA ? 'settings_qa' : 'settings_v2';
  static String get _weekdayGoalsBox =>
      EnvironmentConfig.isQA ? 'weekday_goals_qa' : 'weekday_goals_v2';
  static const String _keyBox = 'encryption_key';
  static const String _settingsKey = 'app_settings';
  static const String _weekdayGoalsKey = 'weekday_goals';

  late Box<ExerciseCategory> _categoriesBoxInstance;
  late Box<DailyRecord> _recordsBoxInstance;
  late Box<AppSettings> _settingsBoxInstance;
  late Box<WeekdayGoals> _weekdayGoalsBoxInstance;

  bool _isInitialized = false;
  HiveAesCipher? _cipher;

  /// Generate or retrieve the encryption key (production only)
  Future<Uint8List?> _getEncryptionKey() async {
    // Skip encryption in QA mode for simpler testing
    if (EnvironmentConfig.isQA) {
      return null;
    }

    try {
      final keyBox = await Hive.openBox<String>(_keyBox);

      String? storedKey = keyBox.get('key');
      if (storedKey == null) {
        // Generate a new 256-bit key
        final key = Hive.generateSecureKey();
        storedKey = base64Encode(key);
        await keyBox.put('key', storedKey);
        SecureLogger.info('DatabaseService', 'Generated new encryption key');
      }

      return base64Decode(storedKey);
    } catch (e, stackTrace) {
      SecureLogger.error('DatabaseService._getEncryptionKey', e, stackTrace);
      return null;
    }
  }

  /// Initialize Hive and open all boxes (encrypted in production, plain in QA)
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ExerciseCategoryAdapter());
    Hive.registerAdapter(CategoryProgressAdapter());
    Hive.registerAdapter(DailyRecordAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(WeekdayGoalsAdapter());

    // Get encryption key (null in QA mode)
    final encryptionKey = await _getEncryptionKey();
    if (encryptionKey != null) {
      _cipher = HiveAesCipher(encryptionKey);
    }

    // Open boxes (encrypted in production, plain in QA)
    _categoriesBoxInstance = await Hive.openBox<ExerciseCategory>(
      _categoriesBox,
      encryptionCipher: _cipher,
    );
    _recordsBoxInstance = await Hive.openBox<DailyRecord>(
      _recordsBox,
      encryptionCipher: _cipher,
    );
    _settingsBoxInstance = await Hive.openBox<AppSettings>(
      _settingsBox,
      encryptionCipher: _cipher,
    );
    _weekdayGoalsBoxInstance = await Hive.openBox<WeekdayGoals>(
      _weekdayGoalsBox,
      encryptionCipher: _cipher,
    );

    // Initialize default data if first launch
    await _initializeDefaultData();

    _isInitialized = true;
  }

  /// Initialize default categories and settings on first launch
  Future<void> _initializeDefaultData() async {
    // Initialize settings if not exists
    if (_settingsBoxInstance.get(_settingsKey) == null) {
      await _settingsBoxInstance.put(_settingsKey, AppSettings());
    }

    // Initialize weekday goals if not exists
    if (_weekdayGoalsBoxInstance.get(_weekdayGoalsKey) == null) {
      await _weekdayGoalsBoxInstance.put(_weekdayGoalsKey, WeekdayGoals());
    }

    // Initialize default categories if empty
    if (_categoriesBoxInstance.isEmpty) {
      final defaultCategories = [
        ExerciseCategory(id: 'chest', name: 'Chest', icon: 'fitness_center', displayOrder: 0),
        ExerciseCategory(id: 'back', name: 'Back', icon: 'accessibility_new', displayOrder: 1),
        ExerciseCategory(id: 'shoulders', name: 'Shoulders', icon: 'sports_gymnastics', displayOrder: 2),
        ExerciseCategory(id: 'biceps', name: 'Biceps', icon: 'front_hand', displayOrder: 3),
        ExerciseCategory(id: 'triceps', name: 'Triceps', icon: 'back_hand', displayOrder: 4),
        ExerciseCategory(id: 'legs', name: 'Legs', icon: 'directions_walk', displayOrder: 5),
        ExerciseCategory(id: 'abs', name: 'Abs', icon: 'self_improvement', displayOrder: 6),
        ExerciseCategory(id: 'cardio', name: 'Cardio', icon: 'directions_run', displayOrder: 7),
      ];

      for (final category in defaultCategories) {
        await _categoriesBoxInstance.put(category.id, category);
      }
    }
  }

  // ============ Settings Operations ============

  AppSettings getSettings() {
    return _settingsBoxInstance.get(_settingsKey) ?? AppSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsBoxInstance.put(_settingsKey, settings);
  }

  // ============ Weekday Goals Operations ============

  WeekdayGoals getWeekdayGoals() {
    return _weekdayGoalsBoxInstance.get(_weekdayGoalsKey) ?? WeekdayGoals();
  }

  Future<void> updateWeekdayGoals(WeekdayGoals goals) async {
    await _weekdayGoalsBoxInstance.put(_weekdayGoalsKey, goals);
  }

  /// Get target sets for a specific date based on weekday goals
  int getTargetSetsForDate(DateTime date) {
    final goals = getWeekdayGoals();
    return goals.getSetsForDate(date);
  }

  /// Check if a date has a goal
  bool hasGoalForDate(DateTime date) {
    final goals = getWeekdayGoals();
    return goals.hasGoalForDate(date);
  }

  // ============ Category Operations ============

  List<ExerciseCategory> getActiveCategories() {
    final categories = _categoriesBoxInstance.values
        .where((c) => c.isActive)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return categories;
  }

  List<ExerciseCategory> getAllCategories() {
    final categories = _categoriesBoxInstance.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return categories;
  }

  Future<void> addCategory(ExerciseCategory category) async {
    await _categoriesBoxInstance.put(category.id, category);
  }

  Future<void> updateCategory(ExerciseCategory category) async {
    await _categoriesBoxInstance.put(category.id, category);
  }

  Future<void> deleteCategory(String categoryId) async {
    final category = _categoriesBoxInstance.get(categoryId);
    if (category != null) {
      category.isActive = false;
      await category.save();
    }
  }

  Future<void> reorderCategories(List<String> categoryIds) async {
    for (int i = 0; i < categoryIds.length; i++) {
      final category = _categoriesBoxInstance.get(categoryIds[i]);
      if (category != null) {
        category.displayOrder = i;
        await category.save();
      }
    }
  }

  // ============ Daily Record Operations ============

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DailyRecord getTodayRecord() {
    final today = DateTime.now();
    return getOrCreateRecord(today);
  }

  DailyRecord getOrCreateRecord(DateTime date) {
    final dateKey = _getDateKey(date);
    var record = _recordsBoxInstance.get(dateKey);

    if (record == null) {
      final categories = getActiveCategories();
      final targetSets = getTargetSetsForDate(date);
      final hasGoal = hasGoalForDate(date);

      record = DailyRecord(
        id: dateKey,
        date: DateTime(date.year, date.month, date.day),
        categoryProgress: categories
            .map((c) => CategoryProgress(categoryId: c.id))
            .toList(),
        targetSetsPerCategory: targetSets,
        totalCategories: categories.length,
        hasGoal: hasGoal,
      );

      _recordsBoxInstance.put(dateKey, record);
    }

    return record;
  }

  DailyRecord? getRecord(DateTime date) {
    final dateKey = _getDateKey(date);
    return _recordsBoxInstance.get(dateKey);
  }

  Future<void> updateStrokes({
    required DateTime date,
    required String categoryId,
    required int strokes,
  }) async {
    final record = getOrCreateRecord(date);
    
    final progressIndex = record.categoryProgress
        .indexWhere((cp) => cp.categoryId == categoryId);

    if (progressIndex != -1) {
      record.categoryProgress[progressIndex].strokesCompleted = strokes;
      await record.save();
    } else {
      record.categoryProgress.add(CategoryProgress(
        categoryId: categoryId,
        strokesCompleted: strokes,
      ));
      await record.save();
    }
  }

  Future<void> incrementStrokes({
    required DateTime date,
    required String categoryId,
  }) async {
    final record = getOrCreateRecord(date);
    
    final progressIndex = record.categoryProgress
        .indexWhere((cp) => cp.categoryId == categoryId);

    if (progressIndex != -1) {
      final currentStrokes = record.categoryProgress[progressIndex].strokesCompleted;
      if (currentStrokes < record.targetSetsPerCategory) {
        record.categoryProgress[progressIndex].strokesCompleted = currentStrokes + 1;
        await record.save();
      }
    }
  }

  Future<void> decrementStrokes({
    required DateTime date,
    required String categoryId,
  }) async {
    final record = getOrCreateRecord(date);
    
    final progressIndex = record.categoryProgress
        .indexWhere((cp) => cp.categoryId == categoryId);

    if (progressIndex != -1) {
      final currentStrokes = record.categoryProgress[progressIndex].strokesCompleted;
      if (currentStrokes > 0) {
        record.categoryProgress[progressIndex].strokesCompleted = currentStrokes - 1;
        await record.save();
      }
    }
  }

  // ============ Statistics & History ============

  List<DailyRecord> getRecordsForMonth(int year, int month) {
    final records = _recordsBoxInstance.values
        .where((r) => r.date.year == year && r.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  /// Get records for a date range
  List<DailyRecord> getRecordsForDateRange(DateTime startDate, DateTime endDate) {
    final records = _recordsBoxInstance.values
        .where((r) => !r.date.isBefore(startDate) && !r.date.isAfter(endDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  /// Calculate category stats for a month
  /// Formula: completed sets / (days with goals in month × daily set goal)
  List<CategoryMonthlyStats> getCategoryStatsForMonth(int year, int month) {
    final records = getRecordsForMonth(year, month);
    final categories = getActiveCategories();
    final weekdayGoals = getWeekdayGoals();
    final stats = <CategoryMonthlyStats>[];

    // Calculate days with goals in this month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;
    
    int daysWithGoals = 0;
    int totalTargetSets = 0;
    
    for (int day = 1; day <= lastDay; day++) {
      final date = DateTime(year, month, day);
      if (weekdayGoals.hasGoalForDate(date)) {
        daysWithGoals++;
        totalTargetSets += weekdayGoals.getSetsForDate(date);
      }
    }

    for (final category in categories) {
      int totalCompleted = 0;
      int daysWithActivity = 0;

      for (final record in records) {
        final progress = record.categoryProgress.firstWhere(
          (cp) => cp.categoryId == category.id,
          orElse: () => CategoryProgress(categoryId: category.id),
        );

        totalCompleted += progress.strokesCompleted;
        
        if (progress.strokesCompleted > 0) {
          daysWithActivity++;
        }
      }

      // Formula: completed sets / (days with goals × daily target)
      final avgPercentage = totalTargetSets > 0 
          ? (totalCompleted / totalTargetSets) * 100 
          : 0.0;

      stats.add(CategoryMonthlyStats(
        categoryId: category.id,
        categoryName: category.name,
        categoryIcon: category.icon,
        totalSetsCompleted: totalCompleted,
        totalSetsTarget: totalTargetSets,
        averagePercentage: avgPercentage,
        daysWithActivity: daysWithActivity,
      ));
    }

    return stats;
  }

  /// Calculate category stats for multiple months
  /// periodMonths: 1, 3, 6, or 12 months
  List<CategoryMonthlyStats> getCategoryStatsForPeriod(int periodMonths) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - periodMonths + 1, 1);
    final endDate = now;
    
    final records = getRecordsForDateRange(startDate, endDate);
    final categories = getActiveCategories();
    final weekdayGoals = getWeekdayGoals();
    final stats = <CategoryMonthlyStats>[];

    // Calculate total days with goals in period
    int totalDaysWithGoals = 0;
    int totalTargetSets = 0;
    
    DateTime currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
      if (weekdayGoals.hasGoalForDate(currentDate)) {
        totalDaysWithGoals++;
        totalTargetSets += weekdayGoals.getSetsForDate(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (final category in categories) {
      int totalCompleted = 0;
      int daysWithActivity = 0;

      for (final record in records) {
        final progress = record.categoryProgress.firstWhere(
          (cp) => cp.categoryId == category.id,
          orElse: () => CategoryProgress(categoryId: category.id),
        );

        totalCompleted += progress.strokesCompleted;
        
        if (progress.strokesCompleted > 0) {
          daysWithActivity++;
        }
      }

      // Formula: completed sets / total target sets in period
      final avgPercentage = totalTargetSets > 0 
          ? (totalCompleted / totalTargetSets) * 100 
          : 0.0;

      stats.add(CategoryMonthlyStats(
        categoryId: category.id,
        categoryName: category.name,
        categoryIcon: category.icon,
        totalSetsCompleted: totalCompleted,
        totalSetsTarget: totalTargetSets,
        averagePercentage: avgPercentage,
        daysWithActivity: daysWithActivity,
      ));
    }

    // Sort by total completed (most active categories first)
    stats.sort((a, b) => b.totalSetsCompleted.compareTo(a.totalSetsCompleted));

    return stats;
  }

  /// Get weekly summary - Monday to Sunday, only counts days with goals
  double getWeeklySummary() {
    final now = DateTime.now();
    
    // Find Monday of current week (weekday 1 = Monday, 7 = Sunday)
    final daysFromMonday = now.weekday - 1; // 0 for Monday, 6 for Sunday
    final monday = DateTime(now.year, now.month, now.day - daysFromMonday);
    
    final weekdayGoals = getWeekdayGoals();
    
    int daysWithGoals = 0;
    double totalPercentage = 0;
    
    // Loop through Monday to today
    for (int i = 0; i <= daysFromMonday; i++) {
      final date = monday.add(Duration(days: i));
      
      // Skip if no goal for this day
      if (!weekdayGoals.hasGoalForDate(date)) continue;
      
      daysWithGoals++;
      
      final record = getRecord(date);
      if (record != null && record.hasGoal) {
        totalPercentage += record.achievementPercentage;
      }
    }
    
    return daysWithGoals > 0 ? totalPercentage / daysWithGoals : 0;
  }

  /// Get monthly summary - only counts days with goals
  MonthlySummary getMonthlySummary(int year, int month) {
    final records = getRecordsForMonth(year, month);
    final categories = getActiveCategories();
    
    // Get number of days in this month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    // For current month, only count up to today
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    
    // Count days with goals in this month
    int daysWithGoals = 0;
    final weekdayGoals = getWeekdayGoals();
    
    final lastDay = isCurrentMonth ? now.day : daysInMonth;
    for (int day = 1; day <= lastDay; day++) {
      final date = DateTime(year, month, day);
      if (weekdayGoals.hasGoalForDate(date)) {
        daysWithGoals++;
      }
    }
    
    if (records.isEmpty || daysWithGoals == 0) {
      return MonthlySummary(
        year: year,
        month: month,
        averagePercentage: 0,
        daysTracked: 0,
        totalStrokes: 0,
        dailyRecords: [],
        daysInMonth: lastDay,
        daysWithGoals: daysWithGoals,
        categoryStats: getCategoryStatsForMonth(year, month),
      );
    }

    // Only count days that have goals and activity
    final daysWithActivity = records.where((r) => r.hasGoal && r.totalStrokes > 0).toList();
    
    // Sum up percentages only for days with goals
    final totalPercentage = daysWithActivity.fold<double>(
      0,
      (sum, r) => sum + r.achievementPercentage,
    );

    final totalStrokes = records.fold<int>(
      0,
      (sum, r) => sum + r.totalStrokes,
    );

    // Divide by days with goals (not total days in month)
    return MonthlySummary(
      year: year,
      month: month,
      averagePercentage: daysWithGoals > 0 ? totalPercentage / daysWithGoals : 0,
      daysTracked: daysWithActivity.length,
      totalStrokes: totalStrokes,
      dailyRecords: records,
      daysInMonth: lastDay,
      daysWithGoals: daysWithGoals,
      categoryStats: getCategoryStatsForMonth(year, month),
    );
  }

  List<MonthlySummary> getAllMonthlySummaries() {
    final summaries = <MonthlySummary>[];
    final monthsSet = <String>{};

    for (final record in _recordsBoxInstance.values) {
      final monthKey = '${record.date.year}-${record.date.month}';
      if (!monthsSet.contains(monthKey)) {
        monthsSet.add(monthKey);
        summaries.add(getMonthlySummary(record.date.year, record.date.month));
      }
    }

    summaries.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return b.month.compareTo(a.month);
    });

    return summaries;
  }

  MonthlySummary? getPersonalBest() {
    final summaries = getAllMonthlySummaries()
        .where((s) => s.daysTracked > 0)
        .toList();
    
    if (summaries.isEmpty) return null;

    summaries.sort((a, b) => b.averagePercentage.compareTo(a.averagePercentage));
    return summaries.first;
  }

  /// Get all daily records (for cloud sync)
  List<DailyRecord> getAllRecords() {
    return _recordsBoxInstance.values.toList();
  }

  /// Import a record from cloud (overwrites if exists)
  Future<void> importRecord(DailyRecord record) async {
    await _recordsBoxInstance.put(record.id, record);
  }

  Future<void> close() async {
    await _categoriesBoxInstance.close();
    await _recordsBoxInstance.close();
    await _settingsBoxInstance.close();
    await _weekdayGoalsBoxInstance.close();
  }
}
