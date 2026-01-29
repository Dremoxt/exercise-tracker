import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/exercise_provider.dart';
import '../config/theme.dart';
import '../widgets/category_card.dart';
import '../widgets/progress_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final hasGoal = provider.selectedDateHasGoal;
        final categories = provider.categories;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              // Header with date and progress
              _buildHeader(context, provider),
              
              // Rest day message or category cards
              if (!hasGoal)
                _buildRestDayMessage(context)
              else
                // Build category cards directly in the list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(categories.length, (index) {
                      final category = categories[index];
                      final strokes = provider.getStrokesForCategory(category.id);
                      final targetStrokes = provider.todayRecord?.targetSetsPerCategory ?? 
                                           provider.targetSetsForSelectedDate;
                      
                      return SizedBox(
                        width: (MediaQuery.of(context).size.width - 42) / 2,
                        height: 100,
                        child: CategoryCard(
                          category: category,
                          currentStrokes: strokes,
                          targetStrokes: targetStrokes,
                          onTap: () => _handleTap(context, provider, category.id),
                          onLongPress: () => _handleLongPress(context, provider, category.id, strokes),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestDayMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement,
            size: 64,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Rest Day',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No goals set for this day.\nEnjoy your rest!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ExerciseProvider provider) {
    final theme = Theme.of(context);
    final isToday = provider.isToday;
    final hasGoal = provider.selectedDateHasGoal;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single row: Today/Date, This Month, This Week, Circle
          Row(
            children: [
              // Today with date
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _selectDate(context, provider),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat('EEEE').format(provider.selectedDate),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(provider.selectedDate),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // This Month
              _buildStatChip(
                context,
                icon: Icons.calendar_month,
                label: '${provider.currentMonthSummary.averagePercentage.toStringAsFixed(0)}%',
                sublabel: 'This month',
              ),

              const SizedBox(width: 8),

              // This Week
              _buildStatChip(
                context,
                icon: Icons.date_range,
                label: '${provider.currentWeekPercentage.toStringAsFixed(0)}%',
                sublabel: 'This week',
              ),

              const SizedBox(width: 8),

              // Daily status circle
              if (hasGoal)
                ProgressRing(
                  percentage: provider.todayPercentage,
                  size: 64,
                  strokeWidth: 6,
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: const Center(
                    child: Icon(Icons.bedtime, size: 28, color: Colors.grey),
                  ),
                ),
            ],
          ),

          if (hasGoal) ...[
            const SizedBox(height: 8),
            // Instruction text
            Text(
              'Tap to add set • Long press to adjust',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge,
          ),
          Text(
            sublabel,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, ExerciseProvider provider, String categoryId) {
    final currentStrokes = provider.getStrokesForCategory(categoryId);
    final targetStrokes = provider.todayRecord?.targetSetsPerCategory ?? 
                         provider.targetSetsForSelectedDate;
    
    if (currentStrokes < targetStrokes) {
      provider.addStroke(categoryId);
      HapticFeedback.lightImpact();
      
      // Show completion feedback
      if (currentStrokes + 1 == targetStrokes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 8),
                Text('Category complete! 🎉'),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Already complete! Long press to adjust.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleLongPress(
    BuildContext context,
    ExerciseProvider provider,
    String categoryId,
    int currentStrokes,
  ) {
    HapticFeedback.mediumImpact();
    
    final targetStrokes = provider.todayRecord?.targetSetsPerCategory ?? 
                         provider.targetSetsForSelectedDate;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => _StrokeAdjustSheet(
        categoryId: categoryId,
        currentStrokes: currentStrokes,
        maxStrokes: targetStrokes,
        onStrokesChanged: (strokes) {
          provider.setStrokes(categoryId, strokes);
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ExerciseProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      provider.selectDate(picked);
    }
  }
}

/// Bottom sheet for adjusting strokes
class _StrokeAdjustSheet extends StatefulWidget {
  final String categoryId;
  final int currentStrokes;
  final int maxStrokes;
  final Function(int) onStrokesChanged;

  const _StrokeAdjustSheet({
    required this.categoryId,
    required this.currentStrokes,
    required this.maxStrokes,
    required this.onStrokesChanged,
  });

  @override
  State<_StrokeAdjustSheet> createState() => _StrokeAdjustSheetState();
}

class _StrokeAdjustSheetState extends State<_StrokeAdjustSheet> {
  late int _strokes;

  @override
  void initState() {
    super.initState();
    _strokes = widget.currentStrokes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Adjust Sets',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          
          // Stroke indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.maxStrokes, (index) {
              final isCompleted = index < _strokes;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _strokes = index + 1;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
                    border: Border.all(
                      color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCompleted ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _strokes = 0;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onStrokesChanged(_strokes);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
