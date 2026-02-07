import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/schedule_item.dart';
import 'recurrence_picker.dart';

/// Bottom sheet for creating or editing schedule items.
/// Supports dynamic fields per item type and common fields like
/// date/time pickers, notification toggle, recurrence, and Google Calendar sync.
class AddScheduleItemSheet extends StatefulWidget {
  final DateTime selectedDate;
  final String? prefilledTime;
  final ScheduleItem? existingItem;
  final Function(ScheduleItemCreate) onSave;

  const AddScheduleItemSheet({
    super.key,
    required this.selectedDate,
    this.prefilledTime,
    this.existingItem,
    required this.onSave,
  });

  @override
  State<AddScheduleItemSheet> createState() => _AddScheduleItemSheetState();
}

class _AddScheduleItemSheetState extends State<AddScheduleItemSheet> {
  late ScheduleItemType _selectedType;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _notificationsEnabled = true;
  int _notifyBefore = 15;
  bool _syncToGoogleCalendar = false;
  String? _recurrenceRule;

  // Field controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _activityTargetController = TextEditingController();

  // Meal type
  MealType _mealType = MealType.breakfast;

  static const _notifyOptions = [5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _selectedType = existing.itemType;
      _date = existing.scheduledDate;
      _startTime = _parseTimeOfDay(existing.startTime) ?? TimeOfDay.now();
      _endTime = existing.endTime != null
          ? _parseTimeOfDay(existing.endTime!)!
          : _addMinutes(_startTime, existing.durationMinutes ?? 30);
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      _activityTargetController.text = existing.activityTarget ?? '';
      _mealType = existing.mealType ?? MealType.breakfast;
      _notificationsEnabled = existing.notifyBeforeMinutes > 0;
      _notifyBefore = existing.notifyBeforeMinutes;
      _recurrenceRule = existing.recurrenceRule;
      _syncToGoogleCalendar = existing.googleCalendarEventId != null;
    } else {
      _selectedType = ScheduleItemType.workout;
      _date = widget.selectedDate;
      if (widget.prefilledTime != null) {
        _startTime = _parseTimeOfDay(widget.prefilledTime!) ?? TimeOfDay.now();
      } else {
        _startTime = TimeOfDay.now();
      }
      _endTime = _addMinutes(_startTime, 30);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _activityTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.black45;
    final surfaceColor = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingItem != null ? 'Edit Item' : 'Add to Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: mutedColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),
                    // Type selector
                    _buildSectionLabel('Type', textColor),
                    const SizedBox(height: 8),
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 20),
                    // Dynamic fields per type
                    ..._buildTypeSpecificFields(isDark, textColor, mutedColor, surfaceColor, borderColor),
                    const SizedBox(height: 20),
                    // Date
                    _buildSectionLabel('Date', textColor),
                    const SizedBox(height: 8),
                    _buildDatePicker(isDark, textColor, surfaceColor, borderColor),
                    const SizedBox(height: 16),
                    // Time
                    _buildSectionLabel('Time', textColor),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildTimePicker('Start', _startTime, (t) => setState(() => _startTime = t), isDark, textColor, surfaceColor, borderColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimePicker('End', _endTime, (t) => setState(() => _endTime = t), isDark, textColor, surfaceColor, borderColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    _buildSectionLabel('Description (optional)', textColor),
                    const SizedBox(height: 8),
                    _buildTextField(_descriptionController, 'Add a note...', isDark, surfaceColor, borderColor, textColor, maxLines: 2),
                    const SizedBox(height: 20),
                    // Notification toggle
                    _buildNotificationSection(isDark, textColor, mutedColor, surfaceColor, borderColor),
                    const SizedBox(height: 16),
                    // Recurrence
                    _buildSectionLabel('Repeat', textColor),
                    const SizedBox(height: 8),
                    RecurrencePicker(
                      initialRule: _recurrenceRule,
                      onChanged: (rule) => setState(() => _recurrenceRule = rule),
                    ),
                    const SizedBox(height: 16),
                    // Google Calendar
                    _buildGoogleCalendarToggle(isDark, textColor, mutedColor),
                    const SizedBox(height: 24),
                    // Save button
                    _buildSaveButton(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor.withOpacity(0.7),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    final types = [
      (ScheduleItemType.workout, 'Workout', Icons.fitness_center, const Color(0xFF06B6D4)),
      (ScheduleItemType.activity, 'Activity', Icons.directions_run, const Color(0xFF3B82F6)),
      (ScheduleItemType.meal, 'Meal', Icons.restaurant, const Color(0xFF22C55E)),
      (ScheduleItemType.habit, 'Habit', Icons.check_circle_outline, const Color(0xFFA855F7)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final (type, label, icon, color) = t;
        final isSelected = _selectedType == type;
        return ChoiceChip(
          avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedType = type),
          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          selectedColor: color,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  List<Widget> _buildTypeSpecificFields(bool isDark, Color textColor, Color mutedColor, Color surfaceColor, Color borderColor) {
    switch (_selectedType) {
      case ScheduleItemType.workout:
        return [
          _buildSectionLabel('Workout Title', textColor),
          const SizedBox(height: 8),
          _buildTextField(_titleController, 'e.g. Upper Body Strength', isDark, surfaceColor, borderColor, textColor),
        ];
      case ScheduleItemType.activity:
        return [
          _buildSectionLabel('Activity Name', textColor),
          const SizedBox(height: 8),
          _buildTextField(_titleController, 'e.g. Morning Walk, Swimming', isDark, surfaceColor, borderColor, textColor),
          const SizedBox(height: 12),
          _buildSectionLabel('Target (optional)', textColor),
          const SizedBox(height: 8),
          _buildTextField(_activityTargetController, 'e.g. 10,000 steps, 30 laps', isDark, surfaceColor, borderColor, textColor),
        ];
      case ScheduleItemType.meal:
        return [
          _buildSectionLabel('Meal', textColor),
          const SizedBox(height: 8),
          _buildMealTypeSelector(isDark),
          const SizedBox(height: 12),
          _buildSectionLabel('Title (optional)', textColor),
          const SizedBox(height: 8),
          _buildTextField(_titleController, 'e.g. Grilled chicken salad', isDark, surfaceColor, borderColor, textColor),
        ];
      case ScheduleItemType.habit:
        return [
          _buildSectionLabel('Habit Name', textColor),
          const SizedBox(height: 8),
          _buildTextField(_titleController, 'e.g. Meditate, Read, Journal', isDark, surfaceColor, borderColor, textColor),
        ];
      case ScheduleItemType.fasting:
        return [
          _buildSectionLabel('Fasting Session', textColor),
          const SizedBox(height: 8),
          _buildTextField(_titleController, 'e.g. 16:8 Intermittent Fast', isDark, surfaceColor, borderColor, textColor),
        ];
    }
  }

  Widget _buildMealTypeSelector(bool isDark) {
    final meals = [
      (MealType.breakfast, 'Breakfast'),
      (MealType.lunch, 'Lunch'),
      (MealType.dinner, 'Dinner'),
      (MealType.snack, 'Snack'),
    ];
    return Wrap(
      spacing: 8,
      children: meals.map((m) {
        final (type, label) = m;
        final isSelected = _mealType == type;
        final color = const Color(0xFF22C55E);
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() {
            _mealType = type;
            if (_titleController.text.isEmpty) {
              _titleController.text = label;
            }
          }),
          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          selectedColor: color,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black26,
          fontSize: 15,
        ),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black26, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark, Color textColor, Color surfaceColor, Color borderColor) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: textColor.withOpacity(0.6)),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(_date),
              style: TextStyle(fontSize: 15, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
    bool isDark,
    Color textColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: textColor.withOpacity(0.6)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.5))),
                Text(
                  time.format(context),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(bool isDark, Color textColor, Color mutedColor, Color surfaceColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Notification', textColor),
            Switch.adaptive(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              activeColor: isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
        if (_notificationsEnabled) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _notifyOptions.map((minutes) {
              final isSelected = _notifyBefore == minutes;
              final label = minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => setState(() => _notifyBefore = minutes),
                backgroundColor: surfaceColor,
                selectedColor: isDark ? Colors.white : Colors.black,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: borderColor),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGoogleCalendarToggle(bool isDark, Color textColor, Color mutedColor) {
    return Row(
      children: [
        Icon(Icons.event, size: 20, color: mutedColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Add to Google Calendar',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ),
        Switch.adaptive(
          value: _syncToGoogleCalendar,
          onChanged: (v) => setState(() => _syncToGoogleCalendar = v),
          activeColor: isDark ? Colors.white : Colors.black,
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final isValid = _titleController.text.isNotEmpty ||
        _selectedType == ScheduleItemType.meal;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isValid ? _onSave : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          widget.existingItem != null ? 'Save Changes' : 'Add to Schedule',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _onSave() {
    // Auto-title for meal type if empty
    String title = _titleController.text.trim();
    if (title.isEmpty && _selectedType == ScheduleItemType.meal) {
      title = _mealType.name[0].toUpperCase() + _mealType.name.substring(1);
    }
    if (title.isEmpty) return;

    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
    final durationMinutes = (_endTime.hour * 60 + _endTime.minute) - (_startTime.hour * 60 + _startTime.minute);

    final item = ScheduleItemCreate(
      title: title,
      itemType: _selectedType,
      scheduledDate: _date,
      startTime: startStr,
      endTime: endStr,
      durationMinutes: durationMinutes > 0 ? durationMinutes : 30,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      activityTarget: _activityTargetController.text.isNotEmpty ? _activityTargetController.text : null,
      mealType: _selectedType == ScheduleItemType.meal ? _mealType : null,
      isRecurring: _recurrenceRule != null,
      recurrenceRule: _recurrenceRule,
      notifyBeforeMinutes: _notificationsEnabled ? _notifyBefore : 0,
      syncToGoogleCalendar: _syncToGoogleCalendar,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  TimeOfDay? _parseTimeOfDay(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final total = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }
}
