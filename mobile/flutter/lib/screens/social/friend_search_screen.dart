import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/social_provider.dart';
import '../../data/services/api_client.dart';
import 'widgets/user_search_result_card.dart';

/// Friend Search Screen - Search for users and send friend requests
class FriendSearchScreen extends ConsumerStatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  ConsumerState<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String? _userId;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initUser();
  }

  Future<void> _initUser() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() => _userId = userId);
      if (userId != null) {
        _loadSuggestions();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    if (_userId == null) return;

    setState(() {
      _isLoadingSuggestions = true;
      _error = null;
    });

    try {
      final socialService = ref.read(socialServiceProvider);
      final suggestions = await socialService.getFriendSuggestions(
        userId: _userId!,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load suggestions';
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (_userId == null) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final socialService = ref.read(socialServiceProvider);
      final results = await socialService.searchUsers(
        userId: _userId!,
        query: query,
        limit: 30,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Search failed';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _handleFollowOrRequest(Map<String, dynamic> user) async {
    if (_userId == null) return;

    HapticFeedback.mediumImpact();

    final targetUserId = user['id'] as String;
    final requiresApproval = user['requires_approval'] as bool? ?? false;
    final hasPending = user['has_pending_request'] as bool? ?? false;
    final pendingRequestId = user['pending_request_id'] as String?;

    try {
      final socialService = ref.read(socialServiceProvider);
      if (hasPending && pendingRequestId != null) {
        // Cancel existing request
        await socialService.cancelFriendRequest(
          userId: _userId!,
          requestId: pendingRequestId,
        );
        _showSnackBar('Friend request cancelled');
      } else if (requiresApproval) {
        // Send friend request
        await socialService.sendFriendRequest(
          userId: _userId!,
          toUserId: targetUserId,
        );
        _showSnackBar('Friend request sent!');
      } else {
        // Instant follow - use existing connection API
        // For now, we'll use the friend request as a connection mechanism
        await socialService.sendFriendRequest(
          userId: _userId!,
          toUserId: targetUserId,
        );
        _showSnackBar('Following!');
      }

      // Refresh the current search/suggestions
      if (_searchController.text.isNotEmpty) {
        await _performSearch(_searchController.text);
      } else {
        await _loadSuggestions();
      }
    } catch (e) {
      _showSnackBar('Failed to send request');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Find Friends'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _performSearch(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.cyan,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'Search'),
              Tab(text: 'Suggestions'),
            ],
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchResults(isDark),
                _buildSuggestions(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for friends',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a name to find users',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UserSearchResultCard(
            user: user,
            onAction: () => _handleFollowOrRequest(user),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions(bool isDark) {
    if (_isLoadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadSuggestions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow friends to get better suggestions',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final user = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UserSearchResultCard(
              user: user,
              onAction: () => _handleFollowOrRequest(user),
              showSuggestionReason: true,
            ),
          );
        },
      ),
    );
  }
}
