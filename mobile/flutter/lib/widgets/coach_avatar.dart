import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../data/models/coach_persona.dart';

/// Reusable circular coach avatar with image support.
///
/// Displays the coach's image in a circular frame with an optional
/// gradient border using the coach's primary and accent colors.
/// Falls back to displaying the coach's icon if the image fails to load.
/// Supports tap to view full avatar in a dialog.
class CoachAvatar extends StatelessWidget {
  /// The coach persona to display
  final CoachPersona coach;

  /// Size of the avatar (width and height)
  final double size;

  /// Whether to show the gradient border around the image
  final bool showBorder;

  /// Width of the gradient border (only applies when showBorder is true)
  final double borderWidth;

  /// Whether to show a shadow beneath the avatar
  final bool showShadow;

  /// Whether tapping the avatar shows a full view dialog
  final bool enableTapToView;

  /// Optional custom onTap callback (overrides tap-to-view behavior)
  final VoidCallback? onTap;

  const CoachAvatar({
    super.key,
    required this.coach,
    this.size = 40,
    this.showBorder = true,
    this.borderWidth = 2,
    this.showShadow = true,
    this.enableTapToView = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = showBorder ? size - (borderWidth * 2) : size;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showBorder
            ? LinearGradient(
                colors: [coach.primaryColor, coach.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: coach.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: showBorder ? EdgeInsets.all(borderWidth) : null,
      child: ClipOval(
        child: coach.imagePath != null
            ? Image.asset(
                coach.imagePath!,
                width: innerSize,
                height: innerSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackIcon(innerSize),
              )
            : _buildFallbackIcon(innerSize),
      ),
    );

    // Wrap with GestureDetector if tap is enabled
    if (onTap != null || enableTapToView) {
      avatar = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            _showAvatarDialog(context);
          }
        },
        child: avatar,
      );
    }

    return avatar;
  }

  /// Builds a fallback icon when the image fails to load or is not available
  Widget _buildFallbackIcon(double iconContainerSize) {
    return Container(
      width: iconContainerSize,
      height: iconContainerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [coach.primaryColor, coach.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          coach.icon,
          color: Colors.white,
          size: iconContainerSize * 0.5,
        ),
      ),
    );
  }

  /// Shows a dialog with the full coach avatar and info
  void _showAvatarDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: coach.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      coach.primaryColor.withOpacity(0.15),
                      coach.accentColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Large avatar
                    Hero(
                      tag: 'coach_avatar_${coach.id}',
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [coach.primaryColor, coach.accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: coach.primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: coach.imagePath != null
                              ? Image.asset(
                                  coach.imagePath!,
                                  width: 132,
                                  height: 132,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackIcon(132),
                                )
                              : _buildFallbackIcon(132),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Coach name
                    Text(
                      coach.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Tagline
                    Text(
                      coach.tagline,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Coach details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Personality badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: coach.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        coach.personalityBadge,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: coach.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Specialization
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 16,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          coach.specialization,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: coach.primaryColor.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: coach.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a standalone coach avatar view dialog.
/// Can be called from anywhere to show a coach's full profile.
void showCoachAvatarDialog(BuildContext context, CoachPersona coach) {
  HapticFeedback.lightImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
  final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: coach.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    coach.primaryColor.withOpacity(0.15),
                    coach.accentColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Large avatar
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [coach.primaryColor, coach.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: coach.primaryColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: coach.imagePath != null
                          ? Image.asset(
                              coach.imagePath!,
                              width: 132,
                              height: 132,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [coach.primaryColor, coach.accentColor],
                                  ),
                                ),
                                child: Icon(
                                  coach.icon,
                                  color: Colors.white,
                                  size: 66,
                                ),
                              ),
                            )
                          : Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [coach.primaryColor, coach.accentColor],
                                ),
                              ),
                              child: Icon(
                                coach.icon,
                                color: Colors.white,
                                size: 66,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Coach name
                  Text(
                    coach.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tagline
                  Text(
                    coach.tagline,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Coach details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Personality badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: coach.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coach.personalityBadge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: coach.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specialization
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        coach.specialization,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: coach.primaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: coach.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
