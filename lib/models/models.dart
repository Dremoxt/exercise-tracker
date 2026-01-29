import 'package:hive/hive.dart';

part 'models.g.dart';

/// Represents a body part category (e.g., Chest, Back, Legs)
@HiveType(typeId: 0)
class ExerciseCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon; // Icon name from Material Icons

  @HiveField(3)
  int displayOrder;

  @HiveField(4)
  bool isActive;

  ExerciseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.displayOrder,
    this.isActive = true,
  });

  ExerciseCategory copyWith({
    String? id,
    String? name,
    String? icon,
    int? displayOrder,
    bool? isActive,
  }) {
    return ExerciseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Represents the strokes/sets completed for a single category on a specific day
@HiveType(typeId: 1)
class CategoryProgress extends HiveObject {
  @HiveField(0)
  String categoryId;

  @HiveField(1)
  int strokesCompleted;

  CategoryProgress({
    required this.categoryId,
    this.strokesCompleted = 0,
  });

  CategoryProgress copyWith({
    String? categoryId,
    int? strokesCompleted,
  }) {
    return CategoryProgress(
      categoryId: categoryId ?? this.categoryId,
      strokesCompleted: strokesCompleted ?? this.strokesCompleted,
    );
  }
}

/// Represents a full day's exercise record
@HiveType(typeId: 2)
class DailyRecord extends HiveObject {
  @HiveField(0)
  String id; // Format: yyyy-MM-dd

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<CategoryProgress> categoryProgress;

  @HiveField(3)
  int targetSetsPerCategory; // Stored for historical accuracy

  @HiveField(4)
  int totalCategories; // Stored for historical accuracy

  @HiveField(5)
  bool hasGoal; // Whether this day had a goal set

  DailyRecord({
    required this.id,
    required this.date,
    required this.categoryProgress,
    required this.targetSetsPerCategory,
    required this.totalCategories,
    this.hasGoal = true,
  });

  /// Calculate the achievement percentage for this day
  double get achievementPercentage {
    if (!hasGoal || categoryProgress.isEmpty || targetSetsPerCategory == 0) return 0.0;
    
    int totalStrokes = categoryProgress.fold(0, (sum, cp) => sum + cp.strokesCompleted);
    int maxStrokes = totalCategories * targetSetsPerCategory;
    
    if (maxStrokes == 0) return 0.0;
    return (totalStrokes / maxStrokes) * 100;
  }

  /// Get total strokes completed
  int get totalStrokes {
    return categoryProgress.fold(0, (sum, cp) => sum + cp.strokesCompleted);
  }

  /// Get maximum possible strokes
  int get maxStrokes => hasGoal ? totalCategories * targetSetsPerCategory : 0;

  DailyRecord copyWith({
    String? id,
    DateTime? date,
    List<CategoryProgress>? categoryProgress,
    int? targetSetsPerCategory,
    int? totalCategories,
    bool? hasGoal,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      targetSetsPerCategory: targetSetsPerCategory ?? this.targetSetsPerCategory,
      totalCategories: totalCategories ?? this.totalCategories,
      hasGoal: hasGoal ?? this.hasGoal,
    );
  }
}

/// Weekday goals configuration
/// Days: 1 = Monday, 7 = Sunday
@HiveType(typeId: 4)
class WeekdayGoals extends HiveObject {
  @HiveField(0)
  bool useWeekdayGoals; // If false, use same goal for all days

  @HiveField(1)
  int defaultSetsPerCategory; // Used when useWeekdayGoals is false

  @HiveField(2)
  Map<int, int> weekdaySets; // Day (1-7) -> sets per category (0 = rest day)

  WeekdayGoals({
    this.useWeekdayGoals = false,
    this.defaultSetsPerCategory = 4,
    Map<int, int>? weekdaySets,
  }) : weekdaySets = weekdaySets ?? {
    1: 4, // Monday
    2: 4, // Tuesday
    3: 4, // Wednesday
    4: 4, // Thursday
    5: 4, // Friday
    6: 4, // Saturday
    7: 4, // Sunday
  };

  /// Get target sets for a specific weekday (1 = Monday, 7 = Sunday)
  int getSetsForWeekday(int weekday) {
    if (!useWeekdayGoals) return defaultSetsPerCategory;
    return weekdaySets[weekday] ?? defaultSetsPerCategory;
  }

  /// Check if a weekday has a goal (sets > 0)
  bool hasGoalForWeekday(int weekday) {
    return getSetsForWeekday(weekday) > 0;
  }

  /// Get target sets for a specific date
  int getSetsForDate(DateTime date) {
    return getSetsForWeekday(date.weekday);
  }

  /// Check if a date has a goal
  bool hasGoalForDate(DateTime date) {
    return hasGoalForWeekday(date.weekday);
  }

  WeekdayGoals copyWith({
    bool? useWeekdayGoals,
    int? defaultSetsPerCategory,
    Map<int, int>? weekdaySets,
  }) {
    return WeekdayGoals(
      useWeekdayGoals: useWeekdayGoals ?? this.useWeekdayGoals,
      defaultSetsPerCategory: defaultSetsPerCategory ?? this.defaultSetsPerCategory,
      weekdaySets: weekdaySets ?? Map.from(this.weekdaySets),
    );
  }
}

/// App settings - configurable by user
@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  int targetSetsPerCategory; // Legacy - now use WeekdayGoals

  @HiveField(1)
  int repsPerSet; // For reference/display, not used in calculations

  @HiveField(2)
  bool darkMode;

  @HiveField(3)
  DateTime? lastSyncDate; // For future cloud sync

  AppSettings({
    this.targetSetsPerCategory = 4,
    this.repsPerSet = 25,
    this.darkMode = false,
    this.lastSyncDate,
  });

  AppSettings copyWith({
    int? targetSetsPerCategory,
    int? repsPerSet,
    bool? darkMode,
    DateTime? lastSyncDate,
  }) {
    return AppSettings(
      targetSetsPerCategory: targetSetsPerCategory ?? this.targetSetsPerCategory,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      darkMode: darkMode ?? this.darkMode,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
    );
  }
}

/// Category statistics for a month
class CategoryMonthlyStats {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int totalSetsCompleted;
  final int totalSetsTarget;
  final double averagePercentage;
  final int daysWithActivity;

  CategoryMonthlyStats({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.totalSetsCompleted,
    required this.totalSetsTarget,
    required this.averagePercentage,
    required this.daysWithActivity,
  });
}

/// Monthly summary for quick access
class MonthlySummary {
  final int year;
  final int month;
  final double averagePercentage;
  final int daysTracked;
  final int daysWithGoals; // Days that had goals set
  final int totalStrokes;
  final List<DailyRecord> dailyRecords;
  final int daysInMonth;
  final List<CategoryMonthlyStats> categoryStats;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.averagePercentage,
    required this.daysTracked,
    required this.totalStrokes,
    required this.dailyRecords,
    this.daysInMonth = 30,
    this.daysWithGoals = 0,
    this.categoryStats = const [],
  });

  String get monthName {
    return DateTime(year, month).toString();
  }
}
