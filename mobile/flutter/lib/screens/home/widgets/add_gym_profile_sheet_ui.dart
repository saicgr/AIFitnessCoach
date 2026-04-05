part of 'add_gym_profile_sheet.dart';

/// UI builder methods extracted from _AddGymProfileSheetState
extension _AddGymProfileSheetStateUI on _AddGymProfileSheetState {

  Widget _buildStepContent(bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
    switch (_currentStep) {
      case 0:
        return _buildNameAndEnvironmentStep(isDark, textPrimary, textSecondary, accentColor);
      case 1:
        return _buildEquipmentStep(isDark, textPrimary, textSecondary, accentColor);
      case 2:
        return _buildStyleStep(isDark, textPrimary, textSecondary);
      default:
        return const SizedBox.shrink();
    }
  }

}
