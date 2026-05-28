import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/user_model.dart' as model;
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/ui/screens/chat/chat_screen.dart';
import 'package:health_tracker/ui/screens/home/comments_screen.dart';
import 'package:health_tracker/ui/screens/home/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

const Color _socialBlue = Color(0xFF1877F2);
const Color _lightPageBg = Color(0xFFF0F2F5);
const Color _lightCardBg = Colors.white;
const Color _lightPrimaryText = Color(0xFF050505);
const Color _lightSecondaryText = Color(0xFF65676B);
const Color _lightLine = Color(0xFFE4E6EB);
const Color _lightButtonGray = Color(0xFFE4E6EB);

const Color _darkPageBg = Color(0xFF18191A);
const Color _darkCardBg = Color(0xFF242526);
const Color _darkPrimaryText = Color(0xFFE4E6EB);
const Color _darkSecondaryText = Color(0xFFB0B3B8);
const Color _darkLine = Color(0xFF3A3B3C);
const Color _darkButtonGray = Color(0xFF3A3B3C);

class UserProfileScreen extends StatefulWidget {
  final String uid;

  const UserProfileScreen({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];

  bool _isLoading = true;
  bool _isFollowing = false;

  static const String _defaultAvatar = 'https://i.stack.imgur.com/l60Hf.png';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg => _isDark ? _darkPageBg : _lightPageBg;
  Color get _cardBg => _isDark ? _darkCardBg : _lightCardBg;
  Color get _primaryText => _isDark ? _darkPrimaryText : _lightPrimaryText;
  Color get _secondaryText => _isDark ? _darkSecondaryText : _lightSecondaryText;
  Color get _lineColor => _isDark ? _darkLine : _lightLine;
  Color get _buttonGray => _isDark ? _darkButtonGray : _lightButtonGray;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      final posts = postsQuery.docs.map((doc) => doc.data()).toList();

      posts.sort((a, b) {
        final aDate = a['datePublished'];
        final bDate = b['datePublished'];

        if (aDate is Timestamp && bDate is Timestamp) {
          return bDate.compareTo(aDate);
        }

        return 0;
      });

      final isMe = currentUid == widget.uid;
      bool isFollowing = false;

      if (!isMe && currentUid != null) {
        isFollowing = await _checkFollowing(currentUid, widget.uid);
      }

      if (!mounted) return;

      setState(() {
        _userData = userDoc.data() ?? {};
        _userPosts = posts;
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load profile error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkFollowing(String currentUid, String targetUid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    final following = List<String>.from(doc.data()?['following'] ?? []);
    return following.contains(targetUid);
  }

  Future<void> _toggleFollow() async {
    if (_userData.isEmpty) return;

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final firestore = FirebaseFirestore.instance;
      final currentFollowers = List<String>.from(_userData['followers'] ?? []);

      if (_isFollowing) {
        await firestore.collection('users').doc(currentUid).update({
          'following': FieldValue.arrayRemove([widget.uid]),
        });

        await firestore.collection('users').doc(widget.uid).update({
          'followers': FieldValue.arrayRemove([currentUid]),
        });

        currentFollowers.remove(currentUid);
      } else {
        await firestore.collection('users').doc(currentUid).update({
          'following': FieldValue.arrayUnion([widget.uid]),
        });

        await firestore.collection('users').doc(widget.uid).update({
          'followers': FieldValue.arrayUnion([currentUid]),
        });

        if (!currentFollowers.contains(currentUid)) {
          currentFollowers.add(currentUid);
        }
      }

      if (!mounted) return;

      setState(() {
        _isFollowing = !_isFollowing;
        _userData['followers'] = currentFollowers;
      });
    } catch (e) {
      debugPrint('Follow error: $e');
    }
  }

  String _photoUrl() {
    final photoUrl = (_userData['photoUrl'] ?? '').toString();

    if (photoUrl.isEmpty) {
      return _defaultAvatar;
    }

    return photoUrl;
  }

  String _coverUrl() {
    return (_userData['coverUrl'] ?? '').toString().trim();
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }

    return value.toString();
  }

  List<dynamic> _readLikes(Map<String, dynamic> post) {
    final likes = post['likes'];

    if (likes is List) {
      return List<dynamic>.from(likes);
    }

    return [];
  }

  String _formatPostDate(dynamic value) {
    try {
      DateTime? date;

      if (value is Timestamp) {
        date = value.toDate();
      } else if (value is DateTime) {
        date = value;
      }

      if (date == null) {
        return 'Just now';
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 7) {
        return DateFormat.yMMMd().format(date);
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return 'Just now';
    }
  }

  void _openPostDetails(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPostsScreen(
          userData: _userData,
          posts: _userPosts,
          initialIndex: index,
        ),
      ),
    );
  }

  void _openComments(Map<String, dynamic> post) {
    final postId = (post['postId'] ?? '').toString();

    if (postId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: postId,
        ),
      ),
    );
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    final description = (post['description'] ?? '').toString().trim();
    final postUrl = (post['postUrl'] ?? '').toString().trim();

    final text = StringBuffer();

    if (description.isNotEmpty) {
      text.writeln(description);
    }

    if (postUrl.isNotEmpty) {
      text.writeln(postUrl);
    }

    await Share.share(
      text.toString().trim().isEmpty
          ? 'Check out this post!'
          : text.toString().trim(),
    );
  }

  Future<void> _toggleLikeFromProfile(Map<String, dynamic> post) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final postId = (post['postId'] ?? '').toString();

      if (currentUid == null || postId.isEmpty) return;

      final likes = _readLikes(post);

      await FireStoreCrud().likePost(
        postId,
        currentUid,
        likes,
      );

      if (!mounted) return;

      setState(() {
        final updatedLikes = List<dynamic>.from(likes);

        if (updatedLikes.contains(currentUid)) {
          updatedLikes.remove(currentUid);
        } else {
          updatedLikes.add(currentUid);
        }

        post['likes'] = updatedLikes;
      });
    } catch (e) {
      debugPrint('Profile like error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _pageBg,
        body: const Center(
          child: CircularProgressIndicator(
            color: _socialBlue,
          ),
        ),
      );
    }

    if (_userData.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBg,
        body: Center(
          child: Text(
            'User not found',
            style: TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == widget.uid;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: IconThemeData(
          color: _primaryText,
        ),
        title: Text(
          _userData['username'] ?? 'Profile',
          style: TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search_rounded,
              color: _primaryText,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_horiz,
              color: _primaryText,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lineColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _socialBlue,
        backgroundColor: _cardBg,
        onRefresh: _loadUserData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(isMe),
            ),
            SliverToBoxAdapter(
              child: _buildProfileTabs(),
            ),
            _userPosts.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyPosts(),
                  )
                : SliverToBoxAdapter(
                    child: _buildPostsSectionHeader(),
                  ),
            if (_userPosts.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildPostItem(
                      _userPosts[index],
                      index,
                    );
                  },
                  childCount: _userPosts.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isMe) {
    final username = (_userData['username'] ?? '').toString();
    final bio = (_userData['bio'] ?? '').toString();

    final followers = (_userData['followers'] as List?)?.length ?? 0;
    final following = (_userData['following'] as List?)?.length ?? 0;
    final posts = _userPosts.length;

    return Container(
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildCoverPhoto(),
              Positioned(
                left: 16,
                bottom: -52,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: _buttonGray,
                    backgroundImage: NetworkImage(_photoUrl()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isEmpty ? 'User' : username,
                  style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bio.isEmpty ? 'No bio yet' : bio,
                  style: TextStyle(
                    color: bio.isEmpty ? _secondaryText : _primaryText,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniStat(
                      Icons.article_outlined,
                      _formatCount(posts),
                      'Posts',
                    ),
                    _buildMiniStat(
                      Icons.people_alt_outlined,
                      _formatCount(followers),
                      'Followers',
                    ),
                    _buildMiniStat(
                      Icons.person_add_alt_1_outlined,
                      _formatCount(following),
                      'Following',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                isMe ? _buildEditButton() : _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPhoto() {
    final coverUrl = _coverUrl();

    if (coverUrl.isEmpty) {
      return Container(
        height: 178,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8EC5FC),
              Color(0xFFE0C3FC),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Profile cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 178,
      width: double.infinity,
      child: Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8EC5FC),
                  Color(0xFFE0C3FC),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(
    IconData icon,
    String count,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _buttonGray,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: _primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.edit_rounded,
                size: 19,
              ),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonGray,
                foregroundColor: _primaryText,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          width: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: _buttonGray,
              foregroundColor: _primaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Icon(Icons.more_horiz),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final username = (_userData['username'] ?? '').toString();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(
                _isFollowing
                    ? Icons.check_circle_outline_rounded
                    : Icons.person_add_alt_1_rounded,
                size: 19,
              ),
              label: Text(_isFollowing ? 'Following' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? _buttonGray : _socialBlue,
                foregroundColor: _isFollowing ? _primaryText : Colors.white,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      targetUid: widget.uid,
                      targetName: username,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_rounded,
                size: 18,
              ),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonGray,
                foregroundColor: _primaryText,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _cardBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildProfileTabItem(
                  label: 'Posts',
                  selected: true,
                ),
                _buildProfileTabItem(
                  label: 'About',
                  selected: false,
                ),
                _buildProfileTabItem(
                  label: 'Photos',
                  selected: false,
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: _lineColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabItem({
    required String label,
    required bool selected,
  }) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _socialBlue : _secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: _socialBlue,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSectionHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: _cardBg,
      child: Row(
        children: [
          Text(
            'Posts',
            style: TextStyle(
              color: _primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: _buttonGray,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tune_rounded,
              color: _primaryText,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPosts() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 70),
      color: _cardBg,
      child: Column(
        children: [
          Container(
            height: 86,
            width: 86,
            decoration: BoxDecoration(
              color: _buttonGray,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 42,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Posts Yet',
            style: TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Posts will appear here.',
            style: TextStyle(
              color: _secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(
    Map<String, dynamic> post,
    int index,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final username = (_userData['username'] ?? 'User').toString();
    final description = (post['description'] ?? '').toString();
    final postUrl = (post['postUrl'] ?? '').toString();
    final postId = (post['postId'] ?? '').toString();
    final likes = _readLikes(post);
    final isLiked = currentUid != null && likes.contains(currentUid);
    final date = _formatPostDate(post['datePublished']);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openPostDetails(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _buttonGray,
                    backgroundImage: NetworkImage(_photoUrl()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            color: _primaryText,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              date,
                              style: TextStyle(
                                color: _secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '·',
                              style: TextStyle(
                                color: _secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.public,
                              size: 12,
                              color: _secondaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_horiz,
                    color: _secondaryText,
                  ),
                ],
              ),
            ),
          ),
          if (description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                description,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (postUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: InkWell(
                onTap: () => _openPostDetails(index),
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    postUrl,
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPostImageError();
                    },
                  ),
                ),
              ),
            ),
          if (postUrl.isEmpty && description.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: _buildTextOnlyPreview('Post'),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                if (likes.isNotEmpty) ...[
                  Container(
                    height: 20,
                    width: 20,
                    decoration: const BoxDecoration(
                      color: _socialBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatCount(likes.length),
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                if (postId.isNotEmpty) _buildCommentCountText(postId),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: _lineColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildPostActionButton(
                  icon: isLiked
                      ? Icons.thumb_up_alt
                      : Icons.thumb_up_alt_outlined,
                  label: 'Like',
                  isActive: isLiked,
                  onPressed: postId.isEmpty
                      ? null
                      : () => _toggleLikeFromProfile(post),
                ),
                _buildPostActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
                  isActive: false,
                  onPressed: postId.isEmpty ? null : () => _openComments(post),
                ),
                _buildPostActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  isActive: false,
                  onPressed: () => _sharePost(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImageError() {
    return Container(
      height: 220,
      width: double.infinity,
      color: _buttonGray,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: _secondaryText,
          size: 44,
        ),
      ),
    );
  }

  Widget _buildTextOnlyPreview(String description) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _buttonGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryText,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCountText(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        final commentCount = snapshot.data?.docs.length ?? 0;

        if (commentCount == 0) {
          return const SizedBox.shrink();
        }

        return Text(
          '$commentCount comments',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
        ),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? _socialBlue : _secondaryText,
          disabledForegroundColor: _secondaryText.withOpacity(0.45),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class UserPostsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const UserPostsScreen({
    Key? key,
    required this.userData,
    required this.posts,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  late final PageController _pageController;

  bool _isLikeAnimating = false;

  static const String _defaultAvatar = 'https://i.stack.imgur.com/l60Hf.png';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg => _isDark ? _darkPageBg : _lightPageBg;
  Color get _cardBg => _isDark ? _darkCardBg : _lightCardBg;
  Color get _primaryText => _isDark ? _darkPrimaryText : _lightPrimaryText;
  Color get _secondaryText => _isDark ? _darkSecondaryText : _lightSecondaryText;
  Color get _lineColor => _isDark ? _darkLine : _lightLine;
  Color get _buttonGray => _isDark ? _darkButtonGray : _lightButtonGray;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _photoUrl() {
    final photoUrl = (widget.userData['photoUrl'] ?? '').toString();

    if (photoUrl.isEmpty) {
      return _defaultAvatar;
    }

    return photoUrl;
  }

  String _formatDate(dynamic value) {
    try {
      DateTime? date;

      if (value is Timestamp) {
        date = value.toDate();
      } else if (value is DateTime) {
        date = value;
      }

      if (date == null) {
        return 'Just now';
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 7) {
        return DateFormat.yMMMd().format(date);
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return 'Just now';
    }
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }

    return value.toString();
  }

  List<dynamic> _readLikes(Map<String, dynamic> post) {
    final likes = post['likes'];

    if (likes is List) {
      return List<dynamic>.from(likes);
    }

    return [];
  }

  Future<void> _toggleLike(
    Map<String, dynamic> post,
    String currentUid,
  ) async {
    try {
      final postId = (post['postId'] ?? '').toString();

      if (postId.isEmpty) return;

      final likes = _readLikes(post);

      await FireStoreCrud().likePost(
        postId,
        currentUid,
        likes,
      );

      if (!mounted) return;

      setState(() {
        final updatedLikes = List<dynamic>.from(likes);

        if (updatedLikes.contains(currentUid)) {
          updatedLikes.remove(currentUid);
        } else {
          updatedLikes.add(currentUid);
        }

        post['likes'] = updatedLikes;
      });
    } catch (e) {
      debugPrint('Detail like error: $e');
    }
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    final description = (post['description'] ?? '').toString().trim();
    final postUrl = (post['postUrl'] ?? '').toString().trim();

    final text = StringBuffer();

    if (description.isNotEmpty) {
      text.writeln(description);
    }

    if (postUrl.isNotEmpty) {
      text.writeln(postUrl);
    }

    await Share.share(
      text.toString().trim().isEmpty
          ? 'Check out this post!'
          : text.toString().trim(),
    );
  }

  void _openComments(Map<String, dynamic> post) {
    final postId = (post['postId'] ?? '').toString();

    if (postId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = (widget.userData['username'] ?? '').toString();

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _primaryText,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username.isEmpty ? 'Posts' : username,
              style: TextStyle(
                color: _primaryText,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              'Posts',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_horiz,
              color: _primaryText,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lineColor,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return _buildPostPage(widget.posts[index]);
        },
      ),
    );
  }

  Widget _buildPostPage(Map<String, dynamic> post) {
    final model.User currentUser = Provider.of<UserProvider>(context).getUser;

    final username = (widget.userData['username'] ?? '').toString();
    final description = (post['description'] ?? '').toString();
    final postUrl = (post['postUrl'] ?? '').toString();
    final postId = (post['postId'] ?? '').toString();
    final date = _formatDate(post['datePublished']);
    final likes = _readLikes(post);
    final isLiked = likes.contains(currentUser.uid);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        child: Container(
          color: _cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(
                username: username,
                date: date,
              ),
              if (description.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 15,
                      height: 1.36,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              GestureDetector(
                onDoubleTap: () async {
                  await _toggleLike(
                    post,
                    currentUser.uid,
                  );

                  if (!mounted) return;

                  setState(() {
                    _isLikeAnimating = true;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (postUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            postUrl,
                            width: double.infinity,
                            height: 430,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildOnlyTextPost(description);
                            },
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: _buildOnlyTextPost(description),
                      ),
                    AnimatedOpacity(
                      opacity: _isLikeAnimating ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: LikeAnimation(
                        isAnimating: _isLikeAnimating,
                        duration: const Duration(milliseconds: 450),
                        onEnd: () {
                          setState(() {
                            _isLikeAnimating = false;
                          });
                        },
                        child: Container(
                          height: 96,
                          width: 96,
                          decoration: BoxDecoration(
                            color: _socialBlue.withOpacity(0.92),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.thumb_up_alt,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    if (likes.isNotEmpty) ...[
                      Container(
                        height: 21,
                        width: 21,
                        decoration: const BoxDecoration(
                          color: _socialBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.thumb_up_alt,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCount(likes.length),
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (postId.isNotEmpty) _buildCommentCountText(postId),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: _lineColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    _buildPostActionButton(
                      icon: isLiked
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      label: 'Like',
                      isActive: isLiked,
                      onPressed: postId.isEmpty
                          ? null
                          : () => _toggleLike(
                                post,
                                currentUser.uid,
                              ),
                    ),
                    _buildPostActionButton(
                      icon: Icons.mode_comment_outlined,
                      label: 'Comment',
                      isActive: false,
                      onPressed: postId.isEmpty ? null : () => _openComments(post),
                    ),
                    _buildPostActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      isActive: false,
                      onPressed: () => _sharePost(post),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: _lineColor,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: InkWell(
                  onTap: () => _openComments(post),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: _buttonGray,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: _lineColor,
                          backgroundImage: NetworkImage(_photoUrl()),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Write a comment...',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader({
    required String username,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _buttonGray,
            backgroundImage: NetworkImage(_photoUrl()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isEmpty ? 'User' : username,
                  style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '·',
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.public,
                      size: 12,
                      color: _secondaryText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz,
            color: _secondaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCountText(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        final commentCount = snapshot.data?.docs.length ?? 0;

        if (commentCount == 0) {
          return const SizedBox.shrink();
        }

        return Text(
          '$commentCount comments',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
        ),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? _socialBlue : _secondaryText,
          disabledForegroundColor: _secondaryText.withOpacity(0.45),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlyTextPost(String description) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 300,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _buttonGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          description.isEmpty ? 'Post' : description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}