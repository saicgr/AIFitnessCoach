import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/social_provider.dart';

/// Full-screen story viewer (F11)
/// - PageView for swiping between users' stories
/// - Linear progress bar timer at top (5s per image)
/// - Tap right half -> next story, tap left half -> previous
/// - Long press to pause timer
/// - Records view via fire-and-forget POST
/// - Swipe down to dismiss
class StoryViewerScreen extends ConsumerStatefulWidget {
  final Map<String, List<Map<String, dynamic>>> storiesByUser;
  final int initialUserIndex;

  const StoryViewerScreen({
    super.key,
    required this.storiesByUser,
    this.initialUserIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  bool _isPaused = false;

  List<String> get _userIds => widget.storiesByUser.keys.toList();

  List<Map<String, dynamic>> get _currentUserStories {
    if (_currentUserIndex >= _userIds.length) return [];
    return widget.storiesByUser[_userIds[_currentUserIndex]] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _pageController = PageController(initialPage: _currentUserIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _startStoryTimer();
    _recordView();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    final stories = _currentUserStories;
    if (stories.isEmpty) return;

    final story = stories[_currentStoryIndex];
    final mediaType = story['media_type'] as String? ?? 'image';
    // 5s for images, could be dynamic for videos
    final duration = mediaType == 'video'
        ? const Duration(seconds: 15)
        : const Duration(seconds: 5);

    _progressController.duration = duration;
    _progressController.forward(from: 0);
  }

  void _recordView() {
    final stories = _currentUserStories;
    if (stories.isEmpty || _currentStoryIndex >= stories.length) return;

    final storyId = stories[_currentStoryIndex]['id'] as String?;
    if (storyId != null) {
      // Fire-and-forget
      ref.read(socialServiceProvider).markStoryViewed(storyId);
    }
  }

  void _nextStory() {
    final stories = _currentUserStories;
    if (_currentStoryIndex < stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStoryTimer();
      _recordView();
    } else {
      // Move to next user
      if (_currentUserIndex < _userIds.length - 1) {
        setState(() {
          _currentUserIndex++;
          _currentStoryIndex = 0;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startStoryTimer();
        _recordView();
      } else {
        // End of all stories
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStoryTimer();
      _recordView();
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        final prevStories = _currentUserStories;
        _currentStoryIndex = prevStories.isNotEmpty ? prevStories.length - 1 : 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _recordView();
    }
  }

  void _onLongPressStart() {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _onLongPressEnd() {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final stories = _currentUserStories;
    if (stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No stories', style: TextStyle(color: Colors.white))),
      );
    }

    final currentStory = stories[_currentStoryIndex];
    final mediaUrl = currentStory['media_url'] as String?;
    final caption = currentStory['caption'] as String?;
    final userName = currentStory['user_name'] as String? ?? 'User';
    final userAvatar = currentStory['user_avatar'] as String?;
    final createdAt = currentStory['created_at'] as String?;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        onLongPressStart: (_) => _onLongPressStart(),
        onLongPressEnd: (_) => _onLongPressEnd(),
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx > screenWidth / 2) {
            _nextStory();
          } else {
            _previousStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story media
            if (mediaUrl != null)
              Image.network(
                mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                ),
              ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Progress bars and user info
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bars
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(stories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: SizedBox(
                                height: 3,
                                child: index < _currentStoryIndex
                                    ? const LinearProgressIndicator(
                                        value: 1.0,
                                        backgroundColor: Colors.white30,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      )
                                    : index == _currentStoryIndex
                                        ? AnimatedBuilder(
                                            animation: _progressController,
                                            builder: (context, child) {
                                              return LinearProgressIndicator(
                                                value: _progressController.value,
                                                backgroundColor: Colors.white30,
                                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                                              );
                                            },
                                          )
                                        : const LinearProgressIndicator(
                                            value: 0.0,
                                            backgroundColor: Colors.white30,
                                            valueColor: AlwaysStoppedAnimation(Colors.white30),
                                          ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // User info row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                          child: userAvatar == null
                              ? Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (createdAt != null)
                          Text(
                            _formatTimeAgo(createdAt),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Caption overlay at bottom
            if (caption != null && caption.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      final diff = DateTime.now().difference(time);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
