part of 'edit_gym_profile_sheet.dart';

/// UI builder methods extracted from _EditGymProfileSheetState
extension _EditGymProfileSheetStateUI on _EditGymProfileSheetState {

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Sticky bottom footer holding the Cancel / Save Changes actions.
  /// Pinned below the scrolling body so it never scrolls away, and padded by
  /// the keyboard inset (`viewInsets.bottom`) so it rides above the keyboard
  /// when a text field is focused. Save is greyed out while a save is in
  /// flight (`_isLoading`) or when there are no changes.
  Widget _buildStickyFooter({
    required bool isDark,
    required Color backgroundColor,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    final media = MediaQuery.of(context);
    // Lift above the keyboard when open; otherwise respect the safe-area inset.
    final bottomInset = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom
        : media.padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context).buttonCancel,
              style: TextStyle(color: textSecondary),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedColorObj,
              foregroundColor: Colors.white,
              disabledBackgroundColor: selectedColorObj.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).vacationModeSaveChanges,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildDurationButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    required bool isDark,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? selectedColorObj.withOpacity(0.15)
              : (isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isEnabled ? selectedColorObj : textSecondary.withOpacity(0.3),
          size: 20,
        ),
      ),
    );
  }

}
