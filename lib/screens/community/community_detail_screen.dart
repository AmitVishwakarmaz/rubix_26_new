import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/community_service.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import 'community_members_screen.dart';
import 'create_poll_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;
  final AppUser currentUser;

  const CommunityDetailScreen({
    super.key,
    required this.community,
    required this.currentUser,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  late TabController _tabController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get isCreator => widget.community.createdBy == widget.currentUser.userId;
  bool get isAlumni => widget.currentUser.isAlumni;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      appBar: _buildAppBar(isDark),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(isDark),
          _buildPollsTab(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.community.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            widget.community.description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.people_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityMembersScreen(
                  community: widget.community,
                  currentUser: widget.currentUser,
                ),
              ),
            );
          },
          tooltip: 'Members',
        ),
        if (isAlumni)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'create_poll') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePollScreen(
                      community: widget.community,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              } else if (value == 'leave') {
                _showLeaveDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_poll',
                child: Row(
                  children: [
                    Icon(Icons.poll, color: Color(0xFF6C63FF)),
                    SizedBox(width: 12),
                    Text('Create Poll'),
                  ],
                ),
              ),
              if (!isCreator)
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Leave Community'),
                    ],
                  ),
                ),
            ],
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6C63FF),
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
        tabs: const [
          Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Chat'),
          Tab(icon: Icon(Icons.poll_rounded), text: 'Polls'),
        ],
      ),
    );
  }

  Widget _buildChatTab(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<CommunityMessage>>(
            stream: _communityService.streamMessages(widget.community.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Auto-scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(isDark, messages[index]);
                },
              );
            },
          ),
        ),
        _buildMessageInput(isDark),
      ],
    );
  }

  Widget _buildMessageBubble(bool isDark, CommunityMessage message) {
    final isMe = message.senderId == widget.currentUser.userId;
    final isMessageFromAlumni = message.senderRole == 'alumni';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    if (isMessageFromAlumni) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Alumni',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF00D4AA),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF6C63FF)
                    : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F0F1E)
                      : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _communityService.sendMessage(
        communityId: widget.community.id,
        senderId: widget.currentUser.userId,
        senderName: widget.currentUser.name,
        senderRole: widget.currentUser.role,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildPollsTab(bool isDark) {
    return StreamBuilder<List<Poll>>(
      stream: _communityService.streamPolls(widget.community.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final polls = snapshot.data ?? [];

        if (polls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.poll_outlined,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No polls yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                if (isAlumni) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePollScreen(
                            community: widget.community,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Poll'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: polls.length,
          itemBuilder: (context, index) {
            return _buildPollCard(isDark, polls[index]);
          },
        );
      },
    );
  }

  Widget _buildPollCard(bool isDark, Poll poll) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.poll_rounded,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<Vote?>(
            stream: _communityService.streamUserVote(
              widget.community.id,
              poll.id,
              widget.currentUser.userId,
            ),
            builder: (context, voteSnapshot) {
              final userVote = voteSnapshot.data;
              final hasVoted = userVote != null;

              return StreamBuilder<Map<String, int>>(
                stream: _communityService.streamVoteCounts(
                  widget.community.id,
                  poll.id,
                ),
                builder: (context, countsSnapshot) {
                  final counts = countsSnapshot.data ?? {};
                  final totalVotes = counts.values.fold(0, (a, b) => a + b);

                  return Column(
                    children: [
                      ...poll.options.map((option) {
                        final isSelected = userVote?.option == option;
                        final voteCount = counts[option] ?? 0;
                        final percentage =
                            totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

                        return GestureDetector(
                          onTap: () => _votePoll(poll, option),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6C63FF).withOpacity(0.1)
                                  : (isDark
                                      ? const Color(0xFF0F0F1E)
                                      : const Color(0xFFF5F5F5)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6C63FF)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (totalVotes > 0)
                                  Positioned.fill(
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: percentage,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C63FF)
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF6C63FF),
                                        size: 20,
                                      )
                                    else
                                      Icon(
                                        Icons.radio_button_unchecked,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        size: 20,
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (totalVotes > 0) ...[
                                      Text(
                                        '$voteCount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(percentage * 100).toInt()}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (totalVotes > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$totalVotes vote${totalVotes != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }


  Future<void> _votePoll(Poll poll, String option) async {
    try {
      await _communityService.votePoll(
        communityId: widget.community.id,
        pollId: poll.id,
        odId: widget.currentUser.userId,
        option: option,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Community'),
        content: Text(
          'Are you sure you want to leave "${widget.community.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveCommunity();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveCommunity() async {
    try {
      await _communityService.leaveCommunity(
        communityId: widget.community.id,
        odId: widget.currentUser.userId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left the community'),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
