import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/user_model.dart' as model;
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/shared/utilities/utils.dart';
import 'package:health_tracker/ui/screens/home/comments_screen.dart';
import 'package:health_tracker/ui/screens/home/widgets/like_animation.dart';
import 'package:health_tracker/ui/screens/profile/user_profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final dynamic snap;

  const PostCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;

  void _openUserProfile(BuildContext context, String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(uid: uid),
      ),
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      await FireStoreCrud().deletePost(postId);
    } catch (err) {
      if (!mounted) return;
      showSnackBar(context, err.toString());
    }
  }

  String _formatDate(dynamic value) {
    try {
      if (value is Timestamp) {
        return DateFormat.yMMMd().format(value.toDate());
      }
      if (value is DateTime) {
        return DateFormat.yMMMd().format(value);
      }
      return 'Just now';
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

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  List _readLikes() {
    final likes = widget.snap['likes'];
    if (likes is List) return likes;
    return [];
  }

  Future<void> _sharePost() async {
    final description = (widget.snap['description'] ?? '').toString().trim();
    final postUrl = (widget.snap['postUrl'] ?? '').toString().trim();

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

  void _openComments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: widget.snap['postId'].toString(),
        ),
      ),
    );
  }

  void _showPostMenu(model.User user) {
    if (widget.snap['uid'].toString() != user.uid) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete post',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    deletePost(widget.snap['postId'].toString());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionContent({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool active = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const CircleAvatar(
        radius: 22,
        child: Icon(Icons.person),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundImage: NetworkImage(imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111111) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;

    final uid = widget.snap['uid'].toString();
    final username = widget.snap['username'].toString();
    final profImage = (widget.snap['profImage'] ?? '').toString();
    final postId = widget.snap['postId'].toString();
    final postUrl = (widget.snap['postUrl'] ?? '').toString();
    final description = (widget.snap['description'] ?? '').toString();
    final dateText = _formatDate(widget.snap['datePublished']);
    final likes = _readLikes();
    final bool isLiked = likes.contains(user.uid);
    final int views = _readInt(widget.snap['views']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(context, uid),
                  child: _buildAvatar(profImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUserProfile(context, uid),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                dateText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.public,
                              size: 13,
                              color: subTextColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showPostMenu(user),
                  icon: Icon(
                    Icons.more_vert,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          // DESCRIPTION
          if (description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: ExpandableText(
                description,
                maxLines: 3,
                expandText: 'show more',
                collapseText: 'show less',
                linkColor: Colors.blue,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),

          // IMAGE
          if (postUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: () {
                FireStoreCrud().likePost(
                  postId,
                  user.uid,
                  likes,
                );

                setState(() {
                  isLikeAnimating = true;
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    color: isDark ? Colors.black : Colors.grey.shade100,
                    child: Image.network(
                      postUrl,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.36,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.36,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          height: 220,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: subTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isLikeAnimating ? 1 : 0,
                    child: LikeAnimation(
                      isAnimating: isLikeAnimating,
                      duration: const Duration(milliseconds: 450),
                      onEnd: () {
                        setState(() {
                          isLikeAnimating = false;
                        });
                      },
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 105,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          // STATS
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatCount(likes.length)} likes',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final commentCount = snapshot.data?.docs.length ?? 0;

                    return Text(
                      '${_formatCount(commentCount)} comments',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.visibility_outlined,
                  size: 17,
                  color: subTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatCount(views),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          // ACTION ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: LikeAnimation(
                    isAnimating: isLiked,
                    smallLike: true,
                    child: _actionContent(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      label: 'Like',
                      active: isLiked,
                      color: isLiked ? Colors.red : subTextColor,
                      onTap: () {
                        FireStoreCrud().likePost(
                          postId,
                          user.uid,
                          likes,
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _actionContent(
                    icon: CupertinoIcons.text_bubble,
                    label: 'Comment',
                    color: subTextColor,
                    onTap: _openComments,
                  ),
                ),
                Expanded(
                  child: _actionContent(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: subTextColor,
                    onTap: _sharePost,
                  ),
                ),
                Expanded(
                  child: _actionContent(
                    icon: Icons.visibility_outlined,
                    label: _formatCount(views),
                    color: subTextColor,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}