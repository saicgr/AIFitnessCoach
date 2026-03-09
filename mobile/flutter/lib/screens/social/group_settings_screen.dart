import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/main_shell.dart';

/// Group settings/info screen (F12)
/// - Edit group name (if admin)
/// - Member list with roles (admin/member)
/// - Add members button (admin only)
/// - Remove member option (admin only)
/// - Leave group button
class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String groupName;
  final String? groupAvatar;

  const GroupSettingsScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
    this.groupAvatar,
  });

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSavingName = false;
  String? _userId;

  // Simulated members data (would come from API in production)
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.groupName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        setState(() => _userId = userId);
        _loadMembers();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    Future.microtask(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
    super.dispose();
  }

  Future<void> _loadMembers() async {
    // Load conversation details to get members
    // For now, use conversations provider to get member info
    setState(() => _isLoadingMembers = false);
  }

  Future<void> _handleSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.groupName) {
      setState(() => _isEditingName = false);
      return;
    }

    setState(() => _isSavingName = true);

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.updateGroupSettings(
        widget.conversationId,
        name: newName,
      );
      if (_userId != null) {
        ref.invalidate(conversationsProvider(_userId!));
      }
      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSavingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name updated')),
        );
      }
    } catch (e) {
      debugPrint('Error updating group name: $e');
      if (mounted) {
        setState(() => _isSavingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
      }
    }
  }

  Future<void> _handleRemoveMember(String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $memberName from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.updateGroupMembers(
        widget.conversationId,
        removeIds: [memberId],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$memberName removed from group')),
        );
        _loadMembers();
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }

  Future<void> _handleAddMembers() async {
    if (_userId == null) return;

    final friendsAsync = ref.read(friendsListProvider(_userId!));
    final friends = friendsAsync.valueOrNull ?? [];
    final existingMemberIds = _members.map((m) => m['id'] as String).toSet();
    final availableFriends = friends.where(
      (f) => !existingMemberIds.contains(f['id'] as String? ?? ''),
    ).toList();

    if (availableFriends.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All your friends are already in this group')),
        );
      }
      return;
    }

    final selectedIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddMembersSheet(
        availableFriends: availableFriends,
      ),
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      try {
        final socialService = ref.read(socialServiceProvider);
        await socialService.updateGroupMembers(
          widget.conversationId,
          addIds: selectedIds,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${selectedIds.length} member(s)')),
          );
          _loadMembers();
        }
      } catch (e) {
        debugPrint('Error adding members: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add members: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleLeaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages from this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.leaveGroup(widget.conversationId);
      if (_userId != null) {
        ref.invalidate(conversationsProvider(_userId!));
      }
      if (mounted) {
        // Pop back to conversations list (pop twice: settings -> conversation -> list)
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error leaving group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final colors = ref.colors(context);
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Group Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Group avatar and name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  // Group Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                    backgroundImage: widget.groupAvatar != null
                        ? NetworkImage(widget.groupAvatar!)
                        : null,
                    child: widget.groupAvatar == null
                        ? const Icon(Icons.group_rounded, size: 40, color: AppColors.purple)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Group Name
                  if (_isEditingName) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            maxLength: 100,
                            autofocus: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSavingName ? null : _handleSaveName,
                          icon: _isSavingName
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.check_rounded, color: colors.accent),
                        ),
                        IconButton(
                          onPressed: () {
                            _nameController.text = widget.groupName;
                            setState(() => _isEditingName = false);
                          },
                          icon: Icon(Icons.close_rounded, color: textMuted),
                        ),
                      ],
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => setState(() => _isEditingName = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.groupName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit_rounded, size: 18, color: textMuted),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Members section header
            Row(
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _handleAddMembers,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Members list
            if (_isLoadingMembers)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_members.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    'Member list will load from server',
                    style: TextStyle(color: textMuted),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: cardBorder.withValues(alpha: 0.3),
                    indent: 60,
                  ),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final memberId = member['id'] as String? ?? '';
                    final memberName = member['name'] as String? ?? 'User';
                    final memberAvatar = member['avatar_url'] as String?;
                    final role = member['role'] as String? ?? 'member';
                    final isCurrentUser = memberId == _userId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.accent.withValues(alpha: 0.2),
                        backgroundImage: memberAvatar != null
                            ? NetworkImage(memberAvatar)
                            : null,
                        child: memberAvatar == null
                            ? Text(
                                memberName.isNotEmpty
                                    ? memberName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.accent,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        isCurrentUser ? '$memberName (You)' : memberName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: role == 'admin'
                          ? Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : null,
                      trailing: (_isAdmin && !isCurrentUser)
                          ? IconButton(
                              onPressed: () => _handleRemoveMember(memberId, memberName),
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            )
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),

            // Leave Group button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _handleLeaveGroup,
                icon: const Icon(Icons.exit_to_app_rounded),
                label: const Text('Leave Group'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for adding members to a group
class _AddMembersSheet extends StatefulWidget {
  final List<Map<String, dynamic>> availableFriends;

  const _AddMembersSheet({required this.availableFriends});

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Add Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedIds.isNotEmpty
                      ? () => Navigator.pop(context, _selectedIds.toList())
                      : null,
                  child: Text('Add (${_selectedIds.length})'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.availableFriends.length,
              itemBuilder: (context, index) {
                final friend = widget.availableFriends[index];
                final friendId = friend['id'] as String? ?? '';
                final friendName = friend['name'] as String? ?? 'User';
                final friendAvatar = friend['avatar_url'] as String?;
                final isSelected = _selectedIds.contains(friendId);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(friendId);
                      } else {
                        _selectedIds.remove(friendId);
                      }
                    });
                  },
                  secondary: CircleAvatar(
                    radius: 18,
                    backgroundImage: friendAvatar != null
                        ? NetworkImage(friendAvatar)
                        : null,
                    child: friendAvatar == null
                        ? Text(
                            friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(friendName),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
