import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../config/theme.dart';
import '../models/models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goals Section
                Text(
                  'Goals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Use weekday-specific goals toggle
                _buildSwitchCard(
                  context,
                  title: 'Different Goals per Weekday',
                  subtitle: 'Set different targets for each day of the week',
                  value: provider.weekdayGoals.useWeekdayGoals,
                  onChanged: (value) => provider.toggleUseWeekdayGoals(value),
                ),
                
                const SizedBox(height: 8),
                
                // Show either simple setting or weekday config
                if (!provider.weekdayGoals.useWeekdayGoals)
                  _buildSettingCard(
                    context,
                    title: 'Sets per Category',
                    subtitle: 'Target number of sets for each exercise',
                    value: '${provider.weekdayGoals.defaultSetsPerCategory}',
                    onTap: () => _showNumberPicker(
                      context,
                      title: 'Sets per Category',
                      currentValue: provider.weekdayGoals.defaultSetsPerCategory,
                      min: 1,
                      max: 6,
                      onChanged: (value) {
                        final newGoals = provider.weekdayGoals.copyWith(
                          defaultSetsPerCategory: value,
                        );
                        provider.updateWeekdayGoals(newGoals);
                      },
                    ),
                  )
                else
                  _buildWeekdayGoalsCard(context, provider),
                
                const SizedBox(height: 24),
                
                // Categories Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddCategoryDialog(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.categories.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderCategories(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return _buildCategoryTile(
                      context,
                      key: ValueKey(category.id),
                      category: category,
                      onEdit: () => _showEditCategoryDialog(context, provider, category),
                      onDelete: () => _showDeleteConfirmation(context, provider, category),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Appearance Section
                Text(
                  'Appearance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildSwitchCard(
                  context,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  value: provider.settings.darkMode,
                  onChanged: (value) => provider.toggleDarkMode(),
                ),
                
                const SizedBox(height: 24),
                
                // Cloud Sync Section
                Text(
                  'Cloud Sync',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildSyncCard(context, provider),
                
                const SizedBox(height: 24),
                
                // About Section
                Text(
                  'About',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildInfoCard(
                  context,
                  title: 'Move Now',
                  subtitle: 'Version 2.0.0',
                  icon: Icons.info_outline,
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekdayGoalsCard(BuildContext context, ExerciseProvider provider) {
    final theme = Theme.of(context);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sets per Weekday',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              'Set to 0 for rest days (won\'t count in monthly average)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Weekday grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1; // 1 = Monday
                final sets = provider.weekdayGoals.weekdaySets[weekday] ?? 4;
                final isRestDay = sets == 0;
                
                return GestureDetector(
                  onTap: () => _showWeekdaySetsPicker(
                    context,
                    provider,
                    weekday,
                    weekdays[index],
                    sets,
                  ),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isRestDay 
                          ? Colors.grey.shade200 
                          : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRestDay 
                            ? Colors.grey.shade300 
                            : AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdays[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isRestDay ? Colors.grey : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRestDay ? '—' : '$sets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isRestDay ? Colors.grey : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeekdaySetsPicker(
    BuildContext context,
    ExerciseProvider provider,
    int weekday,
    String weekdayName,
    int currentSets,
  ) {
    int selectedValue = currentSets;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$weekdayName Sets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Set to 0 for rest day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: selectedValue > 0
                        ? () => setState(() => selectedValue--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    selectedValue == 0 ? 'Rest' : '$selectedValue',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    onPressed: selectedValue < 6
                        ? () => setState(() => selectedValue++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        provider.setWeekdaySets(weekday, selectedValue);
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
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context, ExerciseProvider provider) {
    final theme = Theme.of(context);
    
    // Show sign-in card if not signed in
    if (!provider.isSignedIn) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_off_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cloud Sync', style: theme.textTheme.titleMedium),
                        Text(
                          'Sign in to sync across devices',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: provider.isSyncing
                      ? null
                      : () => _signInWithGoogle(context, provider),
                  icon: provider.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 18,
                          height: 18,
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
                        ),
                  label: Text(provider.isSyncing ? 'Signing in...' : 'Sign in with Google'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show sync card if signed in
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: provider.userPhotoUrl != null
                      ? NetworkImage(provider.userPhotoUrl!)
                      : null,
                  child: provider.userPhotoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.userName ?? 'Signed in',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        provider.userEmail ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _signOut(context, provider),
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign out',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.lastSyncTime != null
                      ? 'Last sync: ${_formatSyncTime(provider.lastSyncTime!)}'
                      : 'Auto-sync enabled',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.isSyncing
                        ? null
                        : () => _downloadFromCloud(context, provider),
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: provider.isSyncing
                        ? null
                        : () => _uploadToCloud(context, provider),
                    icon: provider.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(provider.isSyncing ? 'Syncing...' : 'Upload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, ExerciseProvider provider) async {
    try {
      await provider.signInWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Signed in successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context, ExerciseProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to sync data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await provider.signOut();
    }
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${time.day}/${time.month}/${time.year}';
  }

  Future<void> _uploadToCloud(BuildContext context, ExerciseProvider provider) async {
    try {
      await provider.syncToCloud();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data uploaded to cloud!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadFromCloud(BuildContext context, ExerciseProvider provider) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download from Cloud?'),
        content: const Text('This will replace your local data with cloud data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await provider.syncFromCloud();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data downloaded from cloud!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required Key key,
    required ExerciseCategory category,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          AppTheme.getCategoryIcon(category.icon),
          color: AppTheme.primaryColor,
        ),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  void _showNumberPicker(
    BuildContext context, {
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    int selectedValue = currentValue;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: selectedValue > min
                        ? () => setState(() => selectedValue--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$selectedValue',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    onPressed: selectedValue < max
                        ? () => setState(() => selectedValue++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        onChanged(selectedValue);
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
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, ExerciseProvider provider) {
    final nameController = TextEditingController();
    String selectedIcon = 'fitness_center';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Icon',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.availableIcons.map((iconName) {
                    final isSelected = iconName == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = iconName),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(iconName),
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            provider.addCategory(
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    ExerciseProvider provider,
    ExerciseCategory category,
  ) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Icon',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.availableIcons.map((iconName) {
                    final isSelected = iconName == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = iconName),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(iconName),
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            provider.updateCategory(category.copyWith(
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                            ));
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ExerciseProvider provider,
    ExerciseCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteCategory(category.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
