import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/training_intensity_provider.dart';
import '../../../data/models/training_intensity.dart';

// Import linked exercises types
export '../../../data/models/training_intensity.dart' show LinkedExercise, ExerciseLinkSuggestion;

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

/// Card for displaying a single 1RM with linked exercises
class _OneRMCard extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_OneRMCard> createState() => _OneRMCardState();
}

class _OneRMCardState extends ConsumerState<_OneRMCard> {
  bool _isExpanded = false;

  IconData get _sourceIcon {
    switch (widget.oneRM.source) {
      case 'tested':
        return Icons.verified;
      case 'calculated':
        return Icons.calculate;
      default:
        return Icons.edit;
    }
  }

  Color get _sourceColor {
    switch (widget.oneRM.source) {
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
    final linkedCount = ref.watch(linkedExerciseCountProvider(widget.oneRM.exerciseName));
    final linkedExercises = ref.watch(linkedExercisesForProvider(widget.oneRM.exerciseName));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.cardBorder),
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: widget.onEdit,
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
                          widget.oneRM.oneRepMaxKg.toStringAsFixed(1),
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
                            color: widget.textMuted,
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
                          widget.oneRM.exerciseName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.textPrimary,
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
                              widget.oneRM.sourceDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.textMuted,
                              ),
                            ),
                          ],
                        ),
                        // Linked exercises badge
                        if (linkedCount > 0) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 12,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$linkedCount linked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 14,
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions column
                  Column(
                    children: [
                      // Link button
                      IconButton(
                        onPressed: () => _showLinkExerciseSheet(context),
                        icon: Icon(
                          Icons.add_link,
                          color: widget.textMuted,
                        ),
                        tooltip: 'Link exercises',
                      ),
                      // Delete button
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: widget.textMuted,
                        ),
                        tooltip: 'Delete 1RM',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expandable linked exercises section
          if (_isExpanded && linkedExercises.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.purple.withValues(alpha: 0.05)
                    : Colors.purple.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: widget.cardBorder),
                  Text(
                    'Linked Exercises',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...linkedExercises.map((link) => _LinkedExerciseRow(
                    link: link,
                    primaryOneRM: widget.oneRM.oneRepMaxKg,
                    textPrimary: widget.textPrimary,
                    textMuted: widget.textMuted,
                    onDelete: () => _deleteLink(link),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLinkExerciseSheet(BuildContext context) {
    // Load suggestions first
    ref.read(linkedExercisesProvider.notifier).loadSuggestions(widget.oneRM.exerciseName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LinkExerciseSheet(
        primaryExerciseName: widget.oneRM.exerciseName,
        primaryOneRM: widget.oneRM.oneRepMaxKg,
      ),
    );
  }

  Future<void> _deleteLink(LinkedExercise link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Link?'),
        content: Text('Remove ${link.linkedExerciseName} from linked exercises?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(linkedExercisesProvider.notifier).deleteLink(link.id);
    }
  }
}

/// Row displaying a single linked exercise
class _LinkedExerciseRow extends StatelessWidget {
  final LinkedExercise link;
  final double primaryOneRM;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onDelete;

  const _LinkedExerciseRow({
    required this.link,
    required this.primaryOneRM,
    required this.textPrimary,
    required this.textMuted,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final derivedWeight = (primaryOneRM * link.strengthMultiplier).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right, size: 16, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.linkedExerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${link.multiplierDisplay} = $derivedWeight kg • ${link.relationshipDisplay}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.close, size: 18, color: textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for linking exercises
class _LinkExerciseSheet extends ConsumerStatefulWidget {
  final String primaryExerciseName;
  final double primaryOneRM;

  const _LinkExerciseSheet({
    required this.primaryExerciseName,
    required this.primaryOneRM,
  });

  @override
  ConsumerState<_LinkExerciseSheet> createState() => _LinkExerciseSheetState();
}

class _LinkExerciseSheetState extends ConsumerState<_LinkExerciseSheet> {
  final TextEditingController _exerciseController = TextEditingController();
  double _multiplier = 0.85;
  String _relationshipType = 'variant';
  bool _isSaving = false;

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  bool get _isValid => _exerciseController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() => _isSaving = true);

    final success = await ref.read(linkedExercisesProvider.notifier).createLink(
      primaryExerciseName: widget.primaryExerciseName,
      linkedExerciseName: _exerciseController.text.trim(),
      strengthMultiplier: _multiplier,
      relationshipType: _relationshipType,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Linked ${_exerciseController.text.trim()} to ${widget.primaryExerciseName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _selectSuggestion(ExerciseLinkSuggestion suggestion) {
    _exerciseController.text = suggestion.name;
    setState(() => _multiplier = suggestion.suggestedMultiplier);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final linkedState = ref.watch(linkedExercisesProvider);
    final suggestions = linkedState.suggestions;

    final derivedWeight = (widget.primaryOneRM * _multiplier).toStringAsFixed(1);

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
            // Handle
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

            // Title
            Center(
              child: Text(
                'Link Exercise',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Link to ${widget.primaryExerciseName}',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ),
            const SizedBox(height: 24),

            // Exercise name input
            TextField(
              controller: _exerciseController,
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Incline Bench Press',
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Suggestions
            if (suggestions.isNotEmpty) ...[
              Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.take(6).map((s) => ActionChip(
                  label: Text(s.name, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _selectSuggestion(s),
                  backgroundColor: cardBorder.withValues(alpha: 0.3),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Multiplier slider
            Text(
              'Strength Multiplier: ${(_multiplier * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Derived 1RM: $derivedWeight kg',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cyan,
              ),
            ),
            Slider(
              value: _multiplier,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              onChanged: (value) => setState(() => _multiplier = value),
              activeColor: AppColors.cyan,
            ),
            const SizedBox(height: 16),

            // Relationship type
            Text(
              'Relationship Type',
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
                _RelationshipChip(
                  label: 'Variant',
                  value: 'variant',
                  selected: _relationshipType == 'variant',
                  onSelected: () => setState(() => _relationshipType = 'variant'),
                ),
                _RelationshipChip(
                  label: 'Angle',
                  value: 'angle',
                  selected: _relationshipType == 'angle',
                  onSelected: () => setState(() => _relationshipType = 'angle'),
                ),
                _RelationshipChip(
                  label: 'Equipment',
                  value: 'equipment_swap',
                  selected: _relationshipType == 'equipment_swap',
                  onSelected: () => setState(() => _relationshipType = 'equipment_swap'),
                ),
                _RelationshipChip(
                  label: 'Progression',
                  value: 'progression',
                  selected: _relationshipType == 'progression',
                  onSelected: () => setState(() => _relationshipType = 'progression'),
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
                    : const Text(
                        'Link Exercise',
                        style: TextStyle(
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

class _RelationshipChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  const _RelationshipChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      checkmarkColor: AppColors.cyan,
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
