import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/training_intensity_provider.dart';
import '../../../data/models/training_intensity.dart';
import '../../../data/repositories/training_intensity_repository.dart';

/// Screen for viewing and editing user's stored 1RMs
class My1RMsScreen extends ConsumerStatefulWidget {
  const My1RMsScreen({super.key});

  @override
  ConsumerState<My1RMsScreen> createState() => _My1RMsScreenState();
}

class _My1RMsScreenState extends ConsumerState<My1RMsScreen> {
  bool _isAutoPopulating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final oneRMsState = ref.watch(userOneRMsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My 1RMs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: [
          if (!oneRMsState.isLoading)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textMuted),
              onSelected: (value) async {
                if (value == 'auto_populate') {
                  await _autoPopulate();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'auto_populate',
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 20, color: textMuted),
                      const SizedBox(width: 12),
                      const Text('Auto-populate from history'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: oneRMsState.isLoading || _isAutoPopulating
          ? const Center(child: CircularProgressIndicator())
          : oneRMsState.oneRMs.isEmpty
              ? _buildEmptyState(context, isDark, textPrimary, textMuted)
              : _buildList(context, oneRMsState.oneRMs, isDark, textPrimary, textMuted, elevated, cardBorder),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOneRMSheet(context),
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add 1RM'),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No 1RMs Recorded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your max lifts to get personalized weight recommendations based on your training intensity.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _autoPopulate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Auto-populate from workout history'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: BorderSide(color: AppColors.cyan),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<UserExercise1RM> oneRMs,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    // Sort alphabetically
    final sorted = List<UserExercise1RM>.from(oneRMs)
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userOneRMsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final rm = sorted[index];
          return _OneRMCard(
            oneRM: rm,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            elevated: elevated,
            cardBorder: cardBorder,
            onEdit: () => _showEditOneRMSheet(context, rm),
            onDelete: () => _deleteOneRM(rm),
          );
        },
      ),
    );
  }

  Future<void> _autoPopulate() async {
    setState(() => _isAutoPopulating = true);

    final response = await ref.read(userOneRMsProvider.notifier).autoPopulate();

    setState(() => _isAutoPopulating = false);

    if (response != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: response.count > 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _showAddOneRMSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditOneRMSheet(
        onSave: (exerciseName, weight, source) async {
          final success = await ref.read(userOneRMsProvider.notifier).setOneRM(
            exerciseName: exerciseName,
            oneRepMaxKg: weight,
            source: source,
          );
          if (success && mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditOneRMSheet(BuildContext context, UserExercise1RM oneRM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditOneRMSheet(
        existingOneRM: oneRM,
        onSave: (exerciseName, weight, source) async {
          final success = await ref.read(userOneRMsProvider.notifier).setOneRM(
            exerciseName: exerciseName,
            oneRepMaxKg: weight,
            source: source,
          );
          if (success && mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Future<void> _deleteOneRM(UserExercise1RM oneRM) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete 1RM?'),
        content: Text('Remove ${oneRM.exerciseName} from your saved 1RMs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(userOneRMsProvider.notifier).deleteOneRM(oneRM.exerciseName);
    }
  }
}

/// Card for displaying a single 1RM
class _OneRMCard extends StatelessWidget {
  final UserExercise1RM oneRM;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final Color cardBorder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OneRMCard({
    required this.oneRM,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    required this.cardBorder,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _sourceIcon {
    switch (oneRM.source) {
      case 'tested':
        return Icons.verified;
      case 'calculated':
        return Icons.calculate;
      default:
        return Icons.edit;
    }
  }

  Color get _sourceColor {
    switch (oneRM.source) {
      case 'tested':
        return Colors.green;
      case 'calculated':
        return Colors.orange;
      default:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorder),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Weight display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      oneRM.oneRepMaxKg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan,
                      ),
                    ),
                    Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Exercise name and source
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oneRM.exerciseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _sourceIcon,
                          size: 14,
                          color: _sourceColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          oneRM.sourceDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for adding/editing a 1RM
class _AddEditOneRMSheet extends StatefulWidget {
  final UserExercise1RM? existingOneRM;
  final Future<void> Function(String exerciseName, double weight, String source) onSave;

  const _AddEditOneRMSheet({
    this.existingOneRM,
    required this.onSave,
  });

  @override
  State<_AddEditOneRMSheet> createState() => _AddEditOneRMSheetState();
}

class _AddEditOneRMSheetState extends State<_AddEditOneRMSheet> {
  late TextEditingController _exerciseController;
  late TextEditingController _weightController;
  String _selectedSource = 'manual';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _exerciseController = TextEditingController(
      text: widget.existingOneRM?.exerciseName ?? '',
    );
    _weightController = TextEditingController(
      text: widget.existingOneRM?.oneRepMaxKg.toStringAsFixed(1) ?? '',
    );
    _selectedSource = widget.existingOneRM?.source ?? 'manual';
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _exerciseController.text.trim().isNotEmpty &&
        _weightController.text.isNotEmpty &&
        double.tryParse(_weightController.text) != null &&
        double.parse(_weightController.text) > 0;
  }

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() => _isSaving = true);

    await widget.onSave(
      _exerciseController.text.trim(),
      double.parse(_weightController.text),
      _selectedSource,
    );

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final isEditing = widget.existingOneRM != null;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                isEditing ? 'Edit 1RM' : 'Add 1RM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Exercise name
            TextField(
              controller: _exerciseController,
              enabled: !isEditing,
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Bench Press',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cyan),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Weight
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: '1RM Weight (kg)',
                hintText: 'e.g., 100',
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cyan),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Source selection
            Text(
              'Source',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _SourceChip(
                  label: 'Entered manually',
                  icon: Icons.edit,
                  isSelected: _selectedSource == 'manual',
                  onTap: () => setState(() => _selectedSource = 'manual'),
                ),
                _SourceChip(
                  label: 'Tested 1RM',
                  icon: Icons.verified,
                  isSelected: _selectedSource == 'tested',
                  onTap: () => setState(() => _selectedSource = 'tested'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid && !_isSaving ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update' : 'Save',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      checkmarkColor: AppColors.cyan,
    );
  }
}
