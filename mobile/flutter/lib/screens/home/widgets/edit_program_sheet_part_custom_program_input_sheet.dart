part of 'edit_program_sheet.dart';


/// Custom Program Input Sheet - shown when user taps "Custom" training program
class _CustomProgramInputSheet extends StatefulWidget {
  final String? initialDescription;
  final ValueChanged<String> onSave;
  final SheetColors colors;

  const _CustomProgramInputSheet({
    this.initialDescription,
    required this.onSave,
    required this.colors,
  });

  @override
  State<_CustomProgramInputSheet> createState() =>
      _CustomProgramInputSheetState();
}


class _CustomProgramInputSheetState extends State<_CustomProgramInputSheet> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  static const List<String> _examples = [
    'Train for HYROX competition',
    'Improve my box jump height',
    'Build explosive power for basketball',
    'Train for a marathon',
    'Get better at pull-ups',
    'Prepare for obstacle course racing',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDescription);
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSave(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.tune, color: colors.purple, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Custom Program',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Describe what you want to train for and AI will create a personalized program.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Text input
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g., "Train for HYROX competition"',
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.glassSurface,
                  counterStyle: TextStyle(color: colors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.purple, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (_) => _saveAndClose(),
              ),
              const SizedBox(height: 16),

              // Examples
              Text(
                'Examples',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _examples.map((example) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = example;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: example.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.glassSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasText ? _saveAndClose : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.purple.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Custom Program',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Program History Sheet - shows list of past program configurations
class _ProgramHistorySheet extends StatelessWidget {
  final List<ProgramHistory> history;
  final Future<void> Function(String programId) onRestore;

  const _ProgramHistorySheet({
    required this.history,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.history, color: colors.cyan, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program History',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Restore a previous program configuration',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.cardBorder),

          // History list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final program = history[index];
                return _buildProgramCard(context, program, colors);
              },
            ),
          ),
        ],
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    ProgramHistory program,
    SheetColors colors,
  ) {
    final isCurrent = program.isCurrent;
    final createdAt = DateTime.tryParse(program.createdAt);

    // Extract readable info from preferences
    final difficulty = program.difficulty ?? 'medium';
    final trainingProgram = program.trainingSplit ?? 'Custom';
    final workoutDays = program.selectedDays.isNotEmpty
        ? program.selectedDays.length
        : (program.daysPerWeek ?? 3);

    String dateText = 'Unknown date';
    if (createdAt != null) {
      final now = DateTime.now();
      final diff = now.difference(createdAt);
      if (diff.inDays == 0) {
        dateText = 'Today';
      } else if (diff.inDays == 1) {
        dateText = 'Yesterday';
      } else if (diff.inDays < 7) {
        dateText = '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        dateText = '${(diff.inDays / 7).floor()} weeks ago';
      } else {
        dateText = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.cyan.withOpacity(0.1)
            : colors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? colors.cyan.withOpacity(0.5) : colors.cardBorder,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? colors.cyan.withOpacity(0.2)
                      : colors.glassSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCurrent ? Icons.check_circle : Icons.fitness_center,
                  color: isCurrent ? colors.cyan : colors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatProgramName(trainingProgram),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cyan,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Program details
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip('$workoutDays days/week', Icons.calendar_today, colors),
              _buildDetailChip(_capitalize(difficulty), Icons.speed, colors),
              if (program.equipment.isNotEmpty)
                _buildDetailChip(
                  '${program.equipment.length} equipment',
                  Icons.fitness_center,
                  colors,
                ),
            ],
          ),

          // Restore button (only for non-current programs)
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onRestore(program.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.cyan,
                  side: BorderSide(color: colors.cyan),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Restore This Program'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon, SheetColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatProgramName(String programId) {
    // Convert program IDs to readable names
    final names = {
      'push_pull_legs': 'Push/Pull/Legs',
      'ppl': 'Push/Pull/Legs',
      'phul': 'PHUL',
      'phat': 'PHAT',
      'upper_lower': 'Upper/Lower',
      'full_body': 'Full Body',
      'arnold_split': 'Arnold Split',
      'bro_split': 'Bro Split',
      'hyrox': 'HYROX Training',
      'custom': 'Custom Program',
    };
    return names[programId.toLowerCase()] ?? _capitalize(programId.replaceAll('_', ' '));
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

