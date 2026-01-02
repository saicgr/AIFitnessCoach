import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Input bar widget for live chat
/// Includes text field, send button, and typing detection
class LiveChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;
  final ValueChanged<String>? onTextChanged;

  const LiveChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
    this.onTextChanged,
  });

  @override
  State<LiveChatInputBar> createState() => _LiveChatInputBarState();
}

class _LiveChatInputBarState extends State<LiveChatInputBar> {
  bool _hasText = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _typingDebounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Debounce typing indicator
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 300), () {
      widget.onTextChanged?.call(widget.controller.text);
    });
  }

  void _handleSend() {
    if (!widget.enabled || !_hasText) return;
    HapticService.medium();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.cardBorder.withOpacity(0.5)
                : AppColorsLight.cardBorder,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.enabled
                      ? 'Type a message...'
                      : 'Chat ended',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColors.cyan.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  if (_hasText) _handleSend();
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          _SendButton(
            enabled: widget.enabled && _hasText,
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}

/// Animated send button
class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SendButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: [AppColors.cyan, AppColors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : AppColors.glassSurface,
        shape: BoxShape.circle,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: AnimatedRotation(
              turns: enabled ? 0 : -0.125,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.send_rounded,
                size: 22,
                color: enabled ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Attachment button (optional - for future use)
class AttachmentButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AttachmentButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.attach_file_rounded,
        color: AppColors.textSecondary,
      ),
      tooltip: 'Attach file',
    );
  }
}
