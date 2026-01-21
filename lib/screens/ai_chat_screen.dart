import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../models/user_model.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  
  AppUser? _currentUser;
  String? _userRole;

  List<String> _quickQuestions = [];
  
  // SharedPreferences key for chat history
  static const String _chatHistoryKey = 'ai_chat_history';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Fetch full user profile for context
      _currentUser = await _firestoreService.getUser(user.uid);
      _userRole = _currentUser?.role;
    }
    _setupQuickQuestions();
    
    // Load saved chat history
    await _loadChatHistory();
    
    // Only add welcome message if no history exists
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }
  
  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _authService.currentUser?.uid ?? 'guest';
      final key = '${_chatHistoryKey}_$userId';
      
      final String? historyJson = prefs.getString(key);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> historyList = json.decode(historyJson);
        setState(() {
          _messages.clear();
          _messages.addAll(historyList.map((item) => ChatMessage.fromJson(item)).toList());
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }
  
  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _authService.currentUser?.uid ?? 'guest';
      final key = '${_chatHistoryKey}_$userId';
      
      final historyJson = json.encode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString(key, historyJson);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }
  
  // Delete all chat history
  Future<void> _deleteHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _authService.currentUser?.uid ?? 'guest';
      final key = '${_chatHistoryKey}_$userId';
      
      await prefs.remove(key);
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat history deleted'),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      }
    } catch (e) {
      print('Error deleting chat history: $e');
    }
  }
  
  void _setupQuickQuestions() {
    if (_userRole == 'alumni') {
      _quickQuestions = [
        'How can I help a student?',
        'Draft a job post for me',
        'Suggest mentorship topics',
        'Tips for first-time mentors',
      ];
    } else {
      _quickQuestions = [
        'How do I prepare for interviews?',
        'What skills should I learn?',
        'Career path for my major?',
        'How to approach a mentor?',
      ];
    }
    if (mounted) setState(() {});
  }

  void _addWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        String welcomeText;
        if (_userRole == 'alumni') {
          welcomeText = 'Hi! I\'m your Alumni Assistant. 👋\n\nI can help you with:\n• Finding mentees\n• Drafting job descriptions\n• Mentorship guides\n• Scheduling sessions\n\nHow can I support your mentorship journey today?';
        } else {
          welcomeText = 'Hi! I\'m your AI Career Assistant. 👋\n\nI can help you with:\n• Career guidance\n• Interview preparation\n• Skill development\n• Mentor recommendations\n\nHow can I assist you today?';
        }
        
        _messages.add(ChatMessage(
          text: welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _saveChatHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();
    _saveChatHistory();

    // Placeholder message for streaming response
    final aiMsg = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(aiMsg);
    });

    // Accumulate the response
    StringBuffer responseBuffer = StringBuffer();

    _geminiService.generateResponseStream(text, _currentUser).listen(
      (chunk) {
        responseBuffer.write(chunk);
        if (mounted) {
          setState(() {
            // Update the last message (which is our AI placeholder)
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages.last = ChatMessage(
                  text: responseBuffer.toString(),
                  isUser: false,
                  timestamp: DateTime.now(),
                  isStreaming: true
              );
            }
          });
          _scrollToBottom();
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
             _isTyping = false;
             if (_messages.isNotEmpty && !_messages.last.isUser) {
                // Finalize the message
                _messages.last = ChatMessage(
                  text: responseBuffer.toString(),
                  isUser: false,
                  timestamp: DateTime.now(),
                  isStreaming: false,
                );
             }
          });
          _saveChatHistory();
        }
      },
      onError: (e) {
         if (mounted) {
          setState(() {
             _isTyping = false;
             _messages.add(ChatMessage(
                text: "Sorry, I encountered an error. Please try again.",
                isUser: false,
                timestamp: DateTime.now(),
             ));
          });
          _saveChatHistory();
        }
      }
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // Get dynamic title based on user role
  String get _assistantTitle {
    if (_userRole == 'alumni') {
      return 'Alumni AI Assistant';
    } else {
      return 'Student AI Assistant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF8F9FE), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildMessageList(isDark)),
                    if (_messages.length <= 1) _buildQuickQuestions(isDark),
                    if (_isTyping && _messages.last.isUser) _buildTypingIndicator(isDark), // Show dots only if waiting for stream to start
                    _buildInputArea(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _assistantTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF00D4AA),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00D4AA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 3-dot menu with options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete History', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Chat History'),
        content: const Text('Are you sure you want to delete all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHistory();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index], isDark);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                      )
                    : null,
                color: message.isUser
                    ? null
                    : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft:
                      Radius.circular(message.isUser ? 20 : 4),
                  bottomRight:
                      Radius.circular(message.isUser ? 4 : 20),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? const Color(0xFF6C63FF).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions(bool isDark) {
    if (_quickQuestions.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Questions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((question) {
              return GestureDetector(
                onTap: () => _handleSendMessage(question),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        question,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value - delay).clamp(0.0, 1.0) * 2 - 1).abs();
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.white24,
              const Color(0xFF6C63FF),
              animValue,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _handleSendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _handleSendMessage(_messageController.text),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });
  
  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': false, // Always save as not streaming
    };
  }
  
  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isStreaming: false,
    );
  }
}