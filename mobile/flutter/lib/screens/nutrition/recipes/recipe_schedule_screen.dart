/// Schedule a recipe to be logged — recurring (daily/weekdays/weekends/custom)
/// or batch (cook once, log across N specific date+meal slots).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/cook_event.dart';
import '../../../data/models/recipe.dart';
import '../../../data/models/scheduled_recipe.dart';
import '../../../data/repositories/recipe_repository.dart';

class RecipeScheduleScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  final String userId;
  final bool isDark;
  const RecipeScheduleScreen({super.key, required this.recipe, required this.userId, required this.isDark});
  @override
  ConsumerState<RecipeScheduleScreen> createState() => _RecipeScheduleScreenState();
}

class _RecipeScheduleScreenState extends ConsumerState<RecipeScheduleScreen> {
  ScheduleMode _mode = ScheduleMode.recurring;
  ScheduleKind _kind = ScheduleKind.daily;
  final Set<int> _customDays = {};   // 0=Sun..6=Sat
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 30);
  MealSlot _meal = MealSlot.lunch;
  double _servings = 1.0;
  bool _silentLog = false;

  // Batch
  double _portionsMade = 3.0;
  StorageKind _storage = StorageKind.fridge;
  final List<BatchSlot> _batchSlots = [];

  final String _tz = DateTime.now().timeZoneName; // best-effort; backend re-resolves
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        title: Text('Schedule', style: TextStyle(color: text)),
        iconTheme: IconThemeData(color: text),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save',
                style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Recipe card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.restaurant_menu, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.recipe.name,
                    style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Mode toggle
          SegmentedButton<ScheduleMode>(
            segments: const [
              ButtonSegment(value: ScheduleMode.recurring, label: Text('Recurring')),
              ButtonSegment(value: ScheduleMode.batch, label: Text('Batch (cook once)')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),

          if (_mode == ScheduleMode.recurring) ...[
            _label('Repeat', text),
            Wrap(spacing: 8, children: [
              for (final k in ScheduleKind.values)
                ChoiceChip(
                  label: Text(k.value.toUpperCase()),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                  selectedColor: accent.withValues(alpha: 0.2),
                ),
            ]),
            if (_kind == ScheduleKind.custom) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][i]),
                    selected: _customDays.contains(i),
                    onSelected: (sel) => setState(() {
                      sel ? _customDays.add(i) : _customDays.remove(i);
                    }),
                    selectedColor: accent,
                  ),
              ]),
            ],
            const SizedBox(height: 16),
            _label('At time (your local)', text),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: accent),
              title: Text(_time.format(context), style: TextStyle(color: text)),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
            ),
            const SizedBox(height: 8),
            _label('Meal slot', text),
            DropdownButton<MealSlot>(
              value: _meal, isExpanded: true,
              dropdownColor: surface,
              items: MealSlot.values.map((m) => DropdownMenuItem(
                value: m, child: Text(m.value, style: TextStyle(color: text)))).toList(),
              onChanged: (v) => setState(() => _meal = v ?? _meal),
            ),
            const SizedBox(height: 8),
            _label('Servings per fire', text),
            Row(children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: _servings > 0.25
                  ? () => setState(() => _servings -= 0.25) : null),
              Text(_servings.toStringAsFixed(2), style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _servings += 0.25)),
            ]),
            SwitchListTile(
              title: Text('Silent auto-log (advanced)', style: TextStyle(color: text)),
              subtitle: Text('Default is notify + 1-tap confirm', style: TextStyle(color: muted, fontSize: 11)),
              value: _silentLog,
              onChanged: (v) => setState(() => _silentLog = v),
              activeColor: accent,
            ),
          ] else ...[
            _label('Portions you cooked', text),
            Row(children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: _portionsMade > 1
                  ? () => setState(() => _portionsMade -= 1) : null),
              Text(_portionsMade.toStringAsFixed(0),
                style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _portionsMade += 1)),
            ]),
            const SizedBox(height: 12),
            _label('Storage', text),
            SegmentedButton<StorageKind>(
              segments: const [
                ButtonSegment(value: StorageKind.fridge, label: Text('Fridge (3d)')),
                ButtonSegment(value: StorageKind.freezer, label: Text('Freezer (30d)')),
                ButtonSegment(value: StorageKind.counter, label: Text('Counter (1d)')),
              ],
              selected: {_storage},
              onSelectionChanged: (s) => setState(() => _storage = s.first),
            ),
            const SizedBox(height: 16),
            _label('Schedule meals', text),
            Text('Add a slot for each portion you plan to eat',
                style: TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 8),
            ..._batchSlots.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BatchSlotRow(
                    slot: e.value, accent: accent, text: text, surface: surface,
                    onChange: (s) => setState(() => _batchSlots[e.key] = s),
                    onRemove: () => setState(() => _batchSlots.removeAt(e.key)),
                  ),
                )),
            OutlinedButton.icon(
              onPressed: _batchSlots.length >= _portionsMade.ceil()
                  ? null
                  : () {
                      final tomorrow = DateTime.now().add(const Duration(days: 1));
                      setState(() => _batchSlots.add(BatchSlot(
                            localDate: tomorrow,
                            mealType: MealSlot.lunch,
                            localTime: '12:30',
                            servings: 1.0,
                          )));
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add slot'),
            ),
            const SizedBox(height: 8),
            Text(
              _batchSlots.fold<double>(0, (s, b) => s + b.servings) > _portionsMade
                  ? '⚠️ Slot servings exceed portions made'
                  : 'Slots: ${_batchSlots.fold<double>(0, (s, b) => s + b.servings).toStringAsFixed(1)} / $_portionsMade',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String l, Color text) =>
      Padding(padding: const EdgeInsets.only(bottom: 6),
          child: Text(l, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? cookEventId;
      if (_mode == ScheduleMode.batch) {
        final ev = await ref.read(recipeRepositoryProvider).createCookEvent(
              widget.userId,
              CookEventCreate(
                recipeId: widget.recipe.id,
                portionsMade: _portionsMade,
                storage: _storage,
              ),
            );
        cookEventId = ev.id;
      }
      final req = ScheduledRecipeLogCreate(
        recipeId: widget.recipe.id,
        scheduleMode: _mode,
        mealType: _meal,
        servings: _servings,
        timezone: _tz,
        silentLog: _silentLog,
        scheduleKind: _mode == ScheduleMode.recurring ? _kind : null,
        daysOfWeek: _kind == ScheduleKind.custom ? _customDays.toList() : null,
        localTime: _mode == ScheduleMode.recurring
            ? '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'
            : null,
        cookEventId: cookEventId,
        batchSlots: _mode == ScheduleMode.batch ? _batchSlots : null,
      );
      await ref.read(recipeRepositoryProvider).createSchedule(widget.userId, req);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _BatchSlotRow extends StatelessWidget {
  final BatchSlot slot;
  final Color accent;
  final Color text;
  final Color surface;
  final ValueChanged<BatchSlot> onChange;
  final VoidCallback onRemove;
  const _BatchSlotRow({
    required this.slot, required this.accent, required this.text,
    required this.surface, required this.onChange, required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        TextButton(
          onPressed: () async {
            final d = await showDatePicker(
              context: context, initialDate: slot.localDate,
              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (d != null) onChange(BatchSlot(
              localDate: d, mealType: slot.mealType, localTime: slot.localTime, servings: slot.servings,
            ));
          },
          child: Text(
            '${slot.localDate.month}/${slot.localDate.day}',
            style: TextStyle(color: text),
          ),
        ),
        DropdownButton<MealSlot>(
          value: slot.mealType,
          underline: const SizedBox.shrink(),
          items: MealSlot.values.map((m) => DropdownMenuItem(
            value: m, child: Text(m.value, style: TextStyle(color: text)))).toList(),
          onChanged: (v) => v != null ? onChange(BatchSlot(
            localDate: slot.localDate, mealType: v, localTime: slot.localTime, servings: slot.servings,
          )) : null,
        ),
        const Spacer(),
        Text('×${slot.servings.toStringAsFixed(1)}', style: TextStyle(color: accent)),
        IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
      ]),
    );
  }
}
