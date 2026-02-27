import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wrapped_data.dart';
import '../../data/providers/wrapped_provider.dart';
import '../../data/services/haptic_service.dart';
import 'cards/intro_card.dart';
import 'cards/volume_card.dart';
import 'cards/favorites_card.dart';
import 'cards/consistency_card.dart';
import 'cards/records_card.dart';
import 'cards/time_card.dart';
import 'cards/personality_card.dart';
import 'cards/summary_card.dart';
import 'wrapped_share_sheet.dart';

/// Full-screen story viewer for Fitness Wrapped.
/// Swipe through 8 cards with auto-advance, progress bar, and share.
class WrappedViewerScreen extends ConsumerStatefulWidget {
  final String periodKey;

  const WrappedViewerScreen({super.key, required this.periodKey});

  @override
  ConsumerState<WrappedViewerScreen> createState() =>
      _WrappedViewerScreenState();
}

class _WrappedViewerScreenState extends ConsumerState<WrappedViewerScreen> {
  static const _totalCards = 8;
  static const _autoAdvanceDuration = Duration(seconds: 5);

  final _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(_autoAdvanceDuration, (_) {
      if (!_isPaused && _currentPage < _totalCards - 1) {
        _goToPage(_currentPage + 1);
      }
    });
  }

  void _resetAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _startAutoAdvance();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalCards) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onTapLeft() {
    if (_currentPage > 0) {
      HapticService.selection();
      _goToPage(_currentPage - 1);
      _resetAutoAdvance();
    }
  }

  void _onTapRight() {
    if (_currentPage < _totalCards - 1) {
      HapticService.selection();
      _goToPage(_currentPage + 1);
      _resetAutoAdvance();
    }
  }

  void _onLongPressStart() {
    setState(() => _isPaused = true);
  }

  void _onLongPressEnd() {
    setState(() => _isPaused = false);
    _resetAutoAdvance();
  }

  void _showShareSheet(WrappedData data) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WrappedShareSheet(
        data: data,
        currentCardIndex: _currentPage,
      ),
    );
  }

  List<Widget> _buildCards(WrappedData data) {
    return [
      WrappedIntroCard(data: data, showWatermark: false),
      WrappedVolumeCard(data: data, showWatermark: false),
      WrappedFavoritesCard(data: data, showWatermark: false),
      WrappedConsistencyCard(data: data, showWatermark: false),
      WrappedRecordsCard(data: data, showWatermark: false),
      WrappedTimeCard(data: data, showWatermark: false),
      WrappedPersonalityCard(data: data, showWatermark: false),
      WrappedSummaryCard(data: data, showWatermark: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(wrappedProvider(widget.periodKey));

    return Scaffold(
      backgroundColor: Colors.black,
      body: asyncData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFA855F7)),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load your Wrapped',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(wrappedProvider(widget.periodKey)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _buildViewer(data),
      ),
    );
  }

  Widget _buildViewer(WrappedData data) {
    final cards = _buildCards(data);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Page view with tap zones
        GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(),
          onLongPressEnd: (_) => _onLongPressEnd(),
          onLongPressCancel: () => _onLongPressEnd(),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalCards,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) => cards[index],
          ),
        ),

        // Tap zones (left half = back, right half = forward)
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _onTapLeft,
                  onLongPressStart: (_) => _onLongPressStart(),
                  onLongPressEnd: (_) => _onLongPressEnd(),
                  onLongPressCancel: () => _onLongPressEnd(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _onTapRight,
                  onLongPressStart: (_) => _onLongPressStart(),
                  onLongPressEnd: (_) => _onLongPressEnd(),
                  onLongPressCancel: () => _onLongPressEnd(),
                ),
              ),
            ],
          ),
        ),

        // Progress bar at top
        Positioned(
          top: topPadding + 8,
          left: 16,
          right: 16,
          child: _ProgressBar(
            totalSegments: _totalCards,
            currentSegment: _currentPage,
          ),
        ),

        // Close button (top-left)
        Positioned(
          top: topPadding + 24,
          left: 16,
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Share button at bottom center
        Positioned(
          bottom: bottomPadding + 24,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _showShareSheet(data),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Progress bar with segments for each card
class _ProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentSegment;

  const _ProgressBar({
    required this.totalSegments,
    required this.currentSegment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (index) {
        final isCompleted = index < currentSegment;
        final isCurrent = index == currentSegment;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSegments - 1 ? 4 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.white.withValues(alpha: 0.9)
                  : isCurrent
                      ? const Color(0xFFA855F7)
                      : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      }),
    );
  }
}
