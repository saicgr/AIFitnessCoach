import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/design_system/zealova.dart';
import '../../data/models/injury.dart';
import '../../data/services/api_client.dart';
import 'injuries_list_screen.dart';
import 'widgets/body_part_selector.dart';

import '../../l10n/generated/app_localizations.dart';
/// Screen for reporting a new injury
class ReportInjuryScreen extends ConsumerStatefulWidget {
  const ReportInjuryScreen({super.key});

  @override
  ConsumerState<ReportInjuryScreen> createState() => _ReportInjuryScreenState();
}

class _ReportInjuryScreenState extends ConsumerState<ReportInjuryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedBodyPart;
  String? _selectedInjuryType;
  String _selectedSeverity = 'moderate';
  int _painLevel = 5;
  DateTime _occurredAt = DateTime.now();
  bool _isSubmitting = false;

  final List<String> _injuryTypes = [
    'strain',
    'sprain',
    'tendinitis',
    'bursitis',
    'fracture',
    'dislocation',
    'contusion',
    'tear',
    'overuse',
    'other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final tc = ThemeColors.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: tc.accent,
              onPrimary: tc.accentContrast,
              surface: tc.surface,
              onSurface: tc.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _occurredAt = picked;
      });
    }
  }

  Future<void> _submitInjury() async {
    if (_selectedBodyPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reportInjuryPleaseSelectABody),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) throw Exception('Not authenticated');

      await apiClient.post(
        '/injuries/$userId/report',
        data: {
          'body_part': _selectedBodyPart!,
          if (_selectedInjuryType != null) 'injury_type': _selectedInjuryType,
          'severity': _selectedSeverity,
          'pain_level': _painLevel,
          'occurred_at': _occurredAt.toIso8601String().substring(0, 10),
          if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
        },
      );

      // Refresh the injuries list
      ref.read(injuriesListProvider.notifier).loadInjuries();

      ref.read(posthogServiceProvider).capture(
        eventName: 'injury_reported',
        properties: {
          'body_part': _selectedBodyPart!,
          'severity': _selectedSeverity,
          if (_selectedInjuryType != null) 'injury_type': _selectedInjuryType!,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).reportInjuryInjuryReportedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report injury: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final backgroundColor = tc.background;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final elevated = tc.surface;
    final cardBorder = AppColors.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).reportInjuryReportInjury,
        kicker: 'RECOVERY',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Body part selector
              BodyPartSelector(
                selectedBodyPart: _selectedBodyPart,
                onBodyPartSelected: (bodyPart) {
                  setState(() {
                    _selectedBodyPart = bodyPart;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Injury type dropdown
              ZealovaSectionKicker(AppLocalizations.of(context).reportInjuryInjuryTypeOptional),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedInjuryType,
                    hint: Text(AppLocalizations.of(context).reportInjurySelectInjuryType, style: TextStyle(color: textMuted)),
                    isExpanded: true,
                    dropdownColor: elevated,
                    style: TextStyle(color: textPrimary, fontSize: 16),
                    icon: Icon(Icons.keyboard_arrow_down, color: textMuted),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(AppLocalizations.of(context).reportInjuryNotSure, style: TextStyle(color: textMuted)),
                      ),
                      ..._injuryTypes.map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(_formatInjuryType(type)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedInjuryType = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Severity selector
              ZealovaSectionKicker(AppLocalizations.of(context).reportInjurySeverity),
              const SizedBox(height: 12),
              _buildSeveritySelector(elevated, cardBorder, textPrimary),

              const SizedBox(height: 24),

              // Pain level slider
              ZealovaSectionKicker(AppLocalizations.of(context).reportInjuryCurrentPainLevel),
              const SizedBox(height: 10),
              _buildPainLevelSlider(textPrimary, textMuted, elevated),

              const SizedBox(height: 24),

              // Date picker
              ZealovaSectionKicker(AppLocalizations.of(context).reportInjuryWhenDidItOccur),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_occurredAt),
                        style: TextStyle(fontSize: 16, color: textPrimary),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Notes field
              ZealovaSectionKicker(AppLocalizations.of(context).reportInjuryAdditionalNotesOptional),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(color: textPrimary),
                cursorColor: tc.accent,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).reportInjuryDescribeHowTheInjury,
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: elevated,
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
                    borderSide: BorderSide(color: tc.accent, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Warning banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tc.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tc.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: tc.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).reportInjuryThisIsForTracking,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              _isSubmitting
                  ? Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tc.accent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tc.accentContrast,
                        ),
                      ),
                    )
                  : ZealovaButton(
                      label: AppLocalizations.of(context).reportInjuryReportInjury,
                      onTap: _submitInjury,
                    ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeveritySelector(Color elevated, Color cardBorder, Color textPrimary) {
    final severities = [
      ('mild', 'Mild', 'Minor discomfort', AppColors.success),
      ('moderate', 'Moderate', 'Noticeable pain', AppColors.warning),
      ('severe', 'Severe', 'Significant pain', AppColors.error),
    ];

    return Row(
      children: severities.map((severity) {
        final isSelected = _selectedSeverity == severity.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedSeverity = severity.$1;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: severity.$1 != 'severe' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? severity.$4.withValues(alpha: 0.15)
                    : elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? severity.$4 : cardBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? severity.$4 : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    severity.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? severity.$4 : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    severity.$3,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPainLevelSlider(Color textPrimary, Color textMuted, Color elevated) {
    Color painColor;
    String painDescription;
    IconData painIcon;

    if (_painLevel <= 3) {
      painColor = AppColors.success;
      painDescription = 'Mild discomfort';
      painIcon = Icons.sentiment_satisfied;
    } else if (_painLevel <= 6) {
      painColor = AppColors.warning;
      painDescription = 'Moderate pain';
      painIcon = Icons.sentiment_neutral;
    } else {
      painColor = AppColors.error;
      painDescription = 'Severe pain';
      painIcon = Icons.sentiment_very_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(painIcon, color: painColor, size: 32),
              const SizedBox(width: 12),
              Text(
                '$_painLevel',
                style: ZType.disp(48, color: painColor),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/10',
                  style: ZType.lbl(16, color: textMuted, letterSpacing: 1),
                ),
              ),
            ],
          ),
          Text(
            painDescription.toUpperCase(),
            style: ZType.lbl(11, color: painColor, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: painColor,
              inactiveTrackColor: painColor.withValues(alpha: 0.2),
              thumbColor: painColor,
              overlayColor: painColor.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _painLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() {
                  _painLevel = value.round();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).reportInjuryNoPain, style: TextStyle(fontSize: 12, color: textMuted)),
                Text('Worst pain', style: TextStyle(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatInjuryType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
