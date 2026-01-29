import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/exercise_provider.dart';
import '../config/theme.dart';
import '../models/models.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  
  const HistoryScreen({super.key, this.onNavigateToHome});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _selectedMonth;
  
  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        final summary = provider.getMonthlySummary(
          _selectedMonth.year,
          _selectedMonth.month,
        );
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
          ),
          body: Column(
            children: [
              // Month selector
              _buildMonthSelector(context),
              
              // Monthly summary card
              _buildMonthlySummaryCard(context, summary),
              
              // Calendar grid
              Expanded(
                child: _buildCalendarGrid(context, provider, summary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          GestureDetector(
            onTap: () => _selectMonth(context),
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth.isBefore(DateTime(
              DateTime.now().year,
              DateTime.now().month,
            )) ? () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context, MonthlySummary summary) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            value: '${summary.averagePercentage.toStringAsFixed(1)}%',
            label: 'Average',
            icon: Icons.trending_up,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildSummaryItem(
            context,
            value: '${summary.daysTracked}',
            label: 'Days Active',
            icon: Icons.calendar_today,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildSummaryItem(
            context,
            value: '${summary.totalStrokes}',
            label: 'Total Sets',
            icon: Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    ExerciseProvider provider,
    MonthlySummary summary,
  ) {
    final theme = Theme.of(context);
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    // Adjust for Monday start (weekday 1 = Monday means offset 0)
    final startOffset = firstWeekday - 1;
    
    final totalDays = lastDayOfMonth.day;
    final totalCells = startOffset + totalDays;
    final rows = (totalCells / 7).ceil();
    
    // Create a map of date -> record for quick lookup
    final recordMap = <int, DailyRecord>{};
    for (final record in summary.dailyRecords) {
      recordMap[record.date.day] = record;
    }
    
    return Column(
      children: [
        // Day headers - Monday first
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        
        // Calendar grid
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rows,
            itemBuilder: (context, rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    final dayNumber = cellIndex - startOffset + 1;
                    
                    if (dayNumber < 1 || dayNumber > totalDays) {
                      return const SizedBox(width: 40, height: 40);
                    }
                    
                    final record = recordMap[dayNumber];
                    final percentage = record?.achievementPercentage ?? 0;
                    final isToday = _isToday(dayNumber);
                    final isFuture = _isFuture(dayNumber);
                    
                    return GestureDetector(
                      onTap: isFuture ? null : () {
                        provider.selectDate(DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month,
                          dayNumber,
                        ));
                        _showDayDetails(context, provider, dayNumber, record);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? Colors.transparent
                              : _getDayColor(percentage),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: AppTheme.primaryColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: isFuture
                                  ? theme.textTheme.bodyMedium?.color?.withOpacity(0.3)
                                  : percentage > 50
                                      ? Colors.white
                                      : theme.textTheme.bodyLarge?.color,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
        
        // Legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, '0%', Colors.grey.shade200),
              _buildLegendItem(context, '25%', AppTheme.getProgressColor(25)),
              _buildLegendItem(context, '50%', AppTheme.getProgressColor(50)),
              _buildLegendItem(context, '75%', AppTheme.getProgressColor(75)),
              _buildLegendItem(context, '100%', AppTheme.getProgressColor(100)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Color _getDayColor(double percentage) {
    if (percentage == 0) return Colors.grey.shade200;
    return AppTheme.getProgressColor(percentage);
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
           _selectedMonth.month == now.month &&
           day == now.day;
  }

  bool _isFuture(int day) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    return date.isAfter(DateTime.now());
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _showDayDetails(
    BuildContext context,
    ExerciseProvider provider,
    int day,
    DailyRecord? record,
  ) {
    final theme = Theme.of(context);
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  '${(record?.achievementPercentage ?? 0).toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.getProgressColor(
                      record?.achievementPercentage ?? 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (record != null && record.totalStrokes > 0) ...[
              ...record.categoryProgress.map((cp) {
                final category = provider.categories.firstWhere(
                  (c) => c.id == cp.categoryId,
                  orElse: () => ExerciseCategory(
                    id: cp.categoryId,
                    name: cp.categoryId,
                    icon: 'fitness_center',
                    displayOrder: 0,
                  ),
                );
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        AppTheme.getCategoryIcon(category.icon),
                        size: 20,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          record.targetSetsPerCategory,
                          (index) => Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < cp.strokesCompleted
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No activity recorded',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  provider.selectDate(date);
                  Navigator.pop(context);
                  // Navigate to home tab
                  if (widget.onNavigateToHome != null) {
                    widget.onNavigateToHome!();
                  }
                },
                child: const Text('Edit This Day'),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
