import 'package:flutter/material.dart';
import '../models/models.dart';
import '../config/theme.dart';

class CategoryCard extends StatelessWidget {
  final ExerciseCategory category;
  final int currentStrokes;
  final int targetStrokes;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CategoryCard({
    super.key,
    required this.category,
    required this.currentStrokes,
    required this.targetStrokes,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = currentStrokes >= targetStrokes;
    final progress = targetStrokes > 0 ? currentStrokes / targetStrokes : 0.0;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _getProgressColor(progress, isComplete, theme),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete
                ? AppTheme.accentColor
                : theme.brightness == Brightness.light
                    ? Colors.grey.shade200
                    : Colors.grey.shade800,
            width: isComplete ? 2 : 1,
          ),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Background progress indicator
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: progress * 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          (isComplete ? AppTheme.accentColor : AppTheme.primaryColor)
                              .withOpacity(0.15),
                          (isComplete ? AppTheme.accentColor : AppTheme.primaryColor)
                              .withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content - compact layout
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Icon and completion check
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isComplete ? AppTheme.accentColor : AppTheme.primaryColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(category.icon),
                          color: isComplete ? AppTheme.accentColor : AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  
                  // Category name
                  Text(
                    category.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Bottom row: Stroke dots and counter
                  Row(
                    children: [
                      // Stroke dots
                      Expanded(
                        child: Row(
                          children: List.generate(targetStrokes, (index) {
                            final isCompleted = index < currentStrokes;
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? (isComplete ? AppTheme.accentColor : AppTheme.primaryColor)
                                    : Colors.grey.shade300,
                                border: Border.all(
                                  color: isCompleted
                                      ? (isComplete ? AppTheme.accentColor : AppTheme.primaryColor)
                                      : Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      // Counter text
                      Text(
                        '$currentStrokes/$targetStrokes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isComplete ? AppTheme.accentColor : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, bool isComplete, ThemeData theme) {
    if (progress == 0) return theme.colorScheme.surface;

    final percentage = progress * 100;

    // 100% - Green
    if (isComplete) return const Color(0xFF22C55E).withOpacity(0.45);

    // 75-99% - Yellow
    if (percentage >= 75) return const Color(0xFFEAB308).withOpacity(0.8);

    // 51-74% - Amber
    if (percentage >= 51) return const Color(0xFFF59E0B).withOpacity(0.8);

    // 26-50% - Orange
    if (percentage >= 26) return const Color(0xFFF97316).withOpacity(0.8);

    // 0-25% - Red
    return const Color(0xFFEF4444).withOpacity(0.8);
  }
}
