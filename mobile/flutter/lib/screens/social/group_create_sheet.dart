import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_loading.dart';

/// Bottom sheet for creating a group conversation (F12)
/// - Group name text field (required, max 100 chars)
/// - Multi-select friend picker (searchable list with checkboxes)
/// - Minimum 2 members required
/// - Create button
class GroupCreateSheet extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic> conversation)? onCreated;

  const GroupCreateSheet({super.key, this.onCreated});

  @override
  ConsumerState<GroupCreateSheet> createState() => _GroupCreateSheetState();
}

class _GroupCreateSheetState extends ConsumerState<GroupCreateSheet> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isCreating = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null && mounted) {
        setState(() => _userId = userId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedMemberIds.length < 2 || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final socialService = ref.read(socialServiceProvider);
      final conversation = await socialService.createGroupConversation(
        name: name,
        memberIds: _selectedMemberIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call(conversation);
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = ref.colors(context);
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'New Group',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Group name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Group Name *',
                hintText: 'e.g., Gym Squad',
                prefixIcon: const Icon(Icons.group_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          // Selected count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Friends (${_selectedMemberIds.length} selected)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedMemberIds.length < 2 ? textMuted : colors.accent,
                  ),
                ),
                const Spacer(),
                if (_selectedMemberIds.length < 2)
                  Text(
                    'Min 2 required',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          // Friends list
          Expanded(
            child: _buildFriendsList(isDark, colors, textMuted),
          ),
          // Create button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _nameController.text.trim().isNotEmpty &&
                          _selectedMemberIds.length >= 2 &&
                          !_isCreating
                      ? _handleCreate
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentContrast,
                    disabledBackgroundColor: colors.accent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accentContrast,
                          ),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(bool isDark, ThemeColors colors, Color textMuted) {
    if (_userId == null) {
      return AppLoading.fullScreen();
    }

    final friendsAsync = ref.watch(friendsListProvider(_userId!));

    return friendsAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: textMuted),
              const SizedBox(height: 12),
              Text('Failed to load friends', style: TextStyle(color: textMuted)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(friendsListProvider(_userId!)),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      data: (friends) {
        final searchQuery = _searchController.text.trim().toLowerCase();
        final filteredFriends = searchQuery.isEmpty
            ? friends
            : friends.where((f) {
                final name = (f['name'] as String? ?? '').toLowerCase();
                return name.contains(searchQuery);
              }).toList();

        if (filteredFriends.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty
                  ? 'No friends to add'
                  : 'No friends matching "$searchQuery"',
              style: TextStyle(color: textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: filteredFriends.length,
          itemBuilder: (context, index) {
            final friend = filteredFriends[index];
            final friendId = friend['id'] as String? ?? '';
            final friendName = friend['name'] as String? ?? 'User';
            final friendAvatar = friend['avatar_url'] as String?;
            final isSelected = _selectedMemberIds.contains(friendId);

            return ListTile(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedMemberIds.remove(friendId);
                  } else {
                    _selectedMemberIds.add(friendId);
                  }
                });
              },
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: colors.accent.withValues(alpha: 0.2),
                backgroundImage: friendAvatar != null ? NetworkImage(friendAvatar) : null,
                child: friendAvatar == null
                    ? Text(
                        friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      )
                    : null,
              ),
              title: Text(
                friendName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (value == true) {
                      _selectedMemberIds.add(friendId);
                    } else {
                      _selectedMemberIds.remove(friendId);
                    }
                  });
                },
                activeColor: colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        );
      },
    );
  }
}
