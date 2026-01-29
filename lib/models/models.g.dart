// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseCategoryAdapter extends TypeAdapter<ExerciseCategory> {
  @override
  final int typeId = 0;

  @override
  ExerciseCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String,
      displayOrder: fields[3] as int,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseCategory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.displayOrder)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryProgressAdapter extends TypeAdapter<CategoryProgress> {
  @override
  final int typeId = 1;

  @override
  CategoryProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryProgress(
      categoryId: fields[0] as String,
      strokesCompleted: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryProgress obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.categoryId)
      ..writeByte(1)
      ..write(obj.strokesCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 2;

  @override
  DailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      categoryProgress: (fields[2] as List).cast<CategoryProgress>(),
      targetSetsPerCategory: fields[3] as int,
      totalCategories: fields[4] as int,
      hasGoal: fields.containsKey(5) ? fields[5] as bool : true,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.categoryProgress)
      ..writeByte(3)
      ..write(obj.targetSetsPerCategory)
      ..writeByte(4)
      ..write(obj.totalCategories)
      ..writeByte(5)
      ..write(obj.hasGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      targetSetsPerCategory: fields[0] as int,
      repsPerSet: fields[1] as int,
      darkMode: fields[2] as bool,
      lastSyncDate: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.targetSetsPerCategory)
      ..writeByte(1)
      ..write(obj.repsPerSet)
      ..writeByte(2)
      ..write(obj.darkMode)
      ..writeByte(3)
      ..write(obj.lastSyncDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeekdayGoalsAdapter extends TypeAdapter<WeekdayGoals> {
  @override
  final int typeId = 4;

  @override
  WeekdayGoals read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeekdayGoals(
      useWeekdayGoals: fields[0] as bool,
      defaultSetsPerCategory: fields[1] as int,
      weekdaySets: (fields[2] as Map).cast<int, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, WeekdayGoals obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.useWeekdayGoals)
      ..writeByte(1)
      ..write(obj.defaultSetsPerCategory)
      ..writeByte(2)
      ..write(obj.weekdaySets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekdayGoalsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
