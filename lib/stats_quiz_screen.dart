import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'services/stats_update_service.dart';
import 'firebase_stats_service.dart';
import 'package:flutter/services.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/haptic_helper.dart';
import 'theme/zuno_theme.dart';
import 'theme/app_title_style.dart';
import 'utils/friendly_error.dart';

// Green accent color for Zuno AI theme
const Color zunoGreen = Color(0xFF10B981); // Emerald green

// Message model for chat
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.messages,
    required this.updatedAt,
  });
}

/// Uses Firebase callables so the API key stays on the server (encrypted in Firebase config).
class ZunoChatService {
  final _functions = FirebaseFunctions.instance;

  Future<String> getAIResponse(
    List<Map<String, dynamic>> messages, {
    bool useWebSearch = false,
    String? systemPrompt,
    String? statAnalysisContext,
  }) async {
    try {
      final result = await _functions.httpsCallable('chatWithZuno').call({
        'messages': messages,
        'systemPrompt': systemPrompt,
        'statAnalysisContext': statAnalysisContext,
        'useWebSearch': useWebSearch,
      });
      final data = result.data as Map<dynamic, dynamic>?;
      final text = data?['text'] as String?;
      if (text == null || text.isEmpty) throw Exception('Empty response from AI');
      return text;
    } on FirebaseFunctionsException catch (e) {
      // Log full detail — code "internal" often hides the real message in e.message.
      debugPrint('chatWithZuno failed: code=${e.code} message=${e.message} details=${e.details}');
      rethrow;
    }
  }

  Future<String> analyzeHandwrittenStats(List<int> imageData) async {
    final base64 = base64Encode(imageData);
    final result = await _functions.httpsCallable('analyzeHandwrittenImage').call({'imageBase64': base64});
    final data = result.data as Map<dynamic, dynamic>?;
    return (data?['text'] as String?) ?? 'No stats detected in image.';
  }
}

class StatsQuizScreen extends StatefulWidget {
  const StatsQuizScreen({super.key});

  @override
  State<StatsQuizScreen> createState() => _StatsQuizScreenState();
}

class _StatsQuizScreenState extends State<StatsQuizScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollEnabled = true;

  late ZunoChatService _aiService;
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<ChatMessage> _messages = [];
  final Map<String, dynamic> _collectedStats = {};
  final List<ChatSession> _chatSessions = [];
  
  bool _isLoading = false;
  bool _showHistorySidebar = false;
  String? _currentSessionId;
  bool _isLoadingConversations = false;
  /// Loaded from Firestore (users/uid/context/latestStatAnalysis) so Zuno can use recent stat analysis.
  String? _statAnalysisContext;
  // This is only used to hold the URL for future UI; suppress unused_field warning without changing behavior.
  // ignore: unused_field
  String? _userProfilePictureUrl;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _conversationsStream;

  void _newChat() async {
    await HapticHelper.lightImpact();
    // Save current session before starting new one
    if (_messages.isNotEmpty && _currentSessionId != null) {
      await _saveMessageToFirebase(_messages.last);
    }
    setState(() {
      _messages.clear();
      _collectedStats.clear();
      _startNewSession();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Started a new chat'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _switchConversation(String conversationId) async {
    await HapticHelper.lightImpact();
    
    // Save current session before switching
    if (_messages.isNotEmpty && _currentSessionId != null) {
      await _saveMessageToFirebase(_messages.last);
    }

    // Find the selected conversation
    final selectedSession = _chatSessions.firstWhere(
      (s) => s.id == conversationId,
      orElse: () => _chatSessions.first,
    );

    setState(() {
      _currentSessionId = selectedSession.id;
      _messages.clear();
      _messages.addAll(selectedSession.messages);
      _collectedStats.clear();
      _showHistorySidebar = false;
    });

    _scrollToBottom(force: true);
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _regenerateFrom(int aiMessageIndex) async {
    // Haptic feedback for regenerate
    await HapticHelper.lightImpact();
    
    // Find the most recent user message before this AI message
    int userIdx = aiMessageIndex - 1;
    while (userIdx >= 0 && _messages[userIdx].role != 'user') {
      userIdx--;
    }
    if (userIdx < 0) return;
    // Build conversation up to the user message
    final convo = _messages.take(userIdx + 1).map((m) => {'role': m.role, 'content': m.content}).toList();
    setState(() {
      _isLoading = true;
    });
    _scrollToBottom(force: true);
    try {
      final aiReply = await _aiService.getAIResponse(
        convo,
        statAnalysisContext: _statAnalysisContext,
      );
      final aiMessage = ChatMessage(
        id: DateTime.now().toString(),
        role: 'assistant',
        content: _cleanAIResponse(aiReply),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.insert(aiMessageIndex + 1, aiMessage);
        _isLoading = false;
      });
      
      // Haptic feedback when regenerated message is received
      await HapticHelper.selection();
      
      _scrollToBottom(force: true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final parsed = _parseZunoChatError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parsed.snackBar),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadUserProfilePicture();
    _loadConversationsFromFirebase();
    _loadStatAnalysisContext();
  }

  @override
  void dispose() {
    _conversationsStream?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfilePicture() async {
    try {
      if (_currentUser != null) {
        // Try loading from users collection first
        final userDoc = await _firestore
            .collection('users')
            .doc(_currentUser.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()?.containsKey('profilePictureUrl') == true) {
          if (mounted) {
            setState(() {
              _userProfilePictureUrl = userDoc.get('profilePictureUrl') as String?;
            });
          }
        } else {
          // Fallback to playerProfiles
          final profileDoc = await _firestore
              .collection('playerProfiles')
              .doc(_currentUser.uid)
              .get();
          
          if (profileDoc.exists && profileDoc.data()?.containsKey('profilePictureUrl') == true) {
      if (mounted) {
              setState(() {
                _userProfilePictureUrl = profileDoc.get('profilePictureUrl') as String?;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading profile picture for chat: $e');
    }
  }


  void _initializeAI() {
    _aiService = ZunoChatService();
  }

  Future<void> _loadStatAnalysisContext() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('context')
          .doc('latestStatAnalysis')
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && mounted) {
        final data = doc.data();
        final text = data?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          setState(() => _statAnalysisContext = text);
        }
      }
    } catch (e) {
      print('Load stat context: $e');
    }
  }

  Future<void> _loadConversationsFromFirebase() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingConversations = true;
    });

    try {
      // Load all conversations from Firebase
      final conversationsRef = _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('conversations');

      final conversationsSnapshot = await conversationsRef
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();

      final loadedSessions = <ChatSession>[];

      for (var doc in conversationsSnapshot.docs) {
        final data = doc.data();
        final messagesData = data['messages'] as List<dynamic>? ?? [];
        
        final messages = messagesData.map((msg) {
          return ChatMessage(
            id: msg['id'] ?? DateTime.now().toString(),
            role: msg['role'] ?? 'user',
            content: msg['content'] ?? '',
            timestamp: msg['timestamp']?.toDate() ?? DateTime.now(),
          );
        }).toList();

        loadedSessions.add(
        ChatSession(
            id: doc.id,
            messages: messages,
            updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
          ),
        );
      }

      // Set up real-time listener for conversations
      _conversationsStream?.cancel();
      _conversationsStream = conversationsRef
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;
        
        final updatedSessions = <ChatSession>[];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final messagesData = data['messages'] as List<dynamic>? ?? [];
          
          final messages = messagesData.map((msg) {
            return ChatMessage(
              id: msg['id'] ?? DateTime.now().toString(),
              role: msg['role'] ?? 'user',
              content: msg['content'] ?? '',
              timestamp: msg['timestamp']?.toDate() ?? DateTime.now(),
            );
          }).toList();

          updatedSessions.add(
            ChatSession(
              id: doc.id,
              messages: messages,
              updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
            ),
          );
        }

        setState(() {
          _chatSessions.clear();
          _chatSessions.addAll(updatedSessions);
          
          // If we have conversations and no current session, load the most recent one
          if (_currentSessionId == null && updatedSessions.isNotEmpty && _messages.isEmpty) {
            final mostRecent = updatedSessions.first;
            _currentSessionId = mostRecent.id;
            _messages.addAll(mostRecent.messages);
          } else if (_currentSessionId != null && _messages.isEmpty) {
            // Load current session messages
            final currentSession = updatedSessions.firstWhere(
              (s) => s.id == _currentSessionId,
              orElse: () => updatedSessions.isNotEmpty ? updatedSessions.first : ChatSession(
                id: _currentSessionId!,
                messages: [],
          updatedAt: DateTime.now(),
        ),
      );
            _messages.addAll(currentSession.messages);
          }
        });
      });

      setState(() {
        _chatSessions.clear();
        _chatSessions.addAll(loadedSessions);
        _isLoadingConversations = false;

        // Load most recent conversation if no current session
        if (_currentSessionId == null && loadedSessions.isNotEmpty) {
          final mostRecent = loadedSessions.first;
          _currentSessionId = mostRecent.id;
          _messages.addAll(mostRecent.messages);
        } else if (_currentSessionId == null) {
          // Start new session if no conversations exist
          _startNewSession();
        }
      });

      // If no conversations, start a new session
      if (loadedSessions.isEmpty && _messages.isEmpty) {
        _startNewSession();
      }
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        _isLoadingConversations = false;
      });
      // Start new session on error
      if (_messages.isEmpty) {
        _startNewSession();
      }
    }
  }

  Future<void> _saveMessageToFirebase(ChatMessage message) async {
    if (_currentUser == null || _currentSessionId == null) return;

    try {
      final conversationRef = _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('conversations')
          .doc(_currentSessionId!);

      // Get existing conversation
      final conversationDoc = await conversationRef.get();
      
      // Prepare all messages for saving
      final messagesToSave = _messages.map((msg) => {
        'id': msg.id,
        'role': msg.role,
        'content': msg.content,
        'timestamp': Timestamp.fromDate(msg.timestamp),
      }).toList();

      // Update or create conversation
      if (conversationDoc.exists) {
        await conversationRef.update({
          'messages': messagesToSave,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await conversationRef.set({
          'messages': messagesToSave,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'totalMessagesCount': _messages.length,
        });
      }
    } catch (e) {
      print('Error saving message to Firebase: $e');
    }
  }

  void _startNewSession() {
    // Save current session to Firebase if it has messages
    if (_messages.isNotEmpty && _currentSessionId != null) {
      _saveMessageToFirebase(_messages.last);
    }

    // Generate new session ID
    _currentSessionId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    _messages.clear();
    _collectedStats.clear();
    _sendInitialGreeting();
  }

  void _sendInitialGreeting() async {
    final greeting = ChatMessage(
      id: DateTime.now().toString(),
      role: 'assistant',
      content: 'Hi, I\'m Zuno, your AI stats coach. I can help you log your stats by typing, uploading handwritten notes, or talking to me. You can ask me anything about baseball, strength training, or mental preparation. Let\'s get started.',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(greeting);
    });

    _scrollToBottom(force: true);
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!force && !_autoScrollEnabled) return;
      final target = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  /// Zuno “typing” row — same layout in light/dark; colors from [ZunoTheme].
  Widget _buildZunoTypingRow() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(left: 16, right: 10, top: 4),
          decoration: BoxDecoration(
            color: context.accent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'Z',
              style: TextStyle(
                color: context.onAccent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16, bottom: 14),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ZUNO',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TypingIndicator(
                  dotSize: screenWidth > 600 ? 9 : 8,
                  color: context.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showZunoAttachmentSheet() {
    final theme = Theme.of(context);
    final sheetDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: sheetDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: sheetDark ? Colors.white : theme.primaryColor,
              ),
              title: Text(
                'Choose from Library',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: sheetDark
                      ? Colors.white
                      : (theme.textTheme.bodyLarge?.color ?? Colors.black),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(source: ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: sheetDark ? Colors.white : theme.primaryColor,
              ),
              title: Text(
                'Take Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: sheetDark
                      ? Colors.white
                      : (theme.textTheme.bodyLarge?.color ?? Colors.black),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(source: ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Zuno input bar — same widgets in light/dark ([ZunoTheme] colors).
  Widget _buildZunoInputArea() {
    final bottomInset = MediaQuery.of(context).padding.bottom + 30;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
      decoration: BoxDecoration(
        color: context.bg,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120, minHeight: 50),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: context.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showZunoAttachmentSheet,
                    child: Container(
                      margin: const EdgeInsets.only(left: 6, bottom: 7, top: 7),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: context.accent,
                        size: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message Zuno...',
                        hintStyle: TextStyle(
                          color: context.textMuted.withOpacity(0.85),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap:
                _isLoading ? null : () => _sendMessage(_messageController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isLoading ? context.surface2 : context.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                color: _isLoading ? context.textMuted : context.onAccent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Haptic feedback for sending
    await HapticHelper.lightImpact();

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom(force: true);

    // Prepare messages for AI
    final messagesForAI = _messages.map((msg) {
      return {
        'role': msg.role,
        'content': msg.content,
      };
    }).toList();

    // Add system prompt
    final systemPrompt = {
      'role': 'system',
      'content': '''You are Zuno, a friendly and knowledgeable AI assistant. You're like ChatGPT - you can talk about anything! You're also a helpful baseball stats coach when needed.

FORMATTING (readability — like ChatGPT):
- Structure answers with short paragraphs separated by a blank line when you have more than one idea
- Use **bold** sparingly for key terms or short emphasis (not whole sentences)
- When listing several items, use short bullet lines starting with "- " so the app can render them clearly
- Use numbered lists (1. 2. 3.) only when order or steps matter
- Avoid giant walls of text; break up long explanations
- Do NOT output raw JSON, code blocks, or machine-readable stat payloads except inside the hidden <STATS_JSON> block at the very end when saving stats (never show JSON to the user in prose)
- Talk naturally with contractions (I'm, you're, didn't); stay friendly and clear

YOUR PRIMARY ROLES (in order of priority):
1. General Conversational AI - Chat about ANY topic (like ChatGPT): current events, science, history, technology, sports, entertainment, advice, questions, etc.
2. Web-Enabled Assistant - Use web search to provide current, accurate information when needed
3. Baseball Stats Collector - When the user mentions baseball stats, help log their performance data
4. Training Advisor - Provide strength, conditioning, and mental prep guidance when asked
5. Baseball Expert - Answer questions about rules, techniques, and strategy when relevant
6. Motivational Coach - Be encouraging and supportive when appropriate

GENERAL CONVERSATION:
- You can discuss ANY topic the user brings up
- Feel free to have open-ended conversations
- Use web search when the user asks about current events, recent news, or real-time information
- Don't limit yourself to baseball - be a general-purpose AI assistant
- If the user wants to chat about something unrelated to baseball, engage fully!

STAT CATEGORIES YOU TRACK:
Batting: at bats, hits, runs, doubles, triples, home runs, walks, intentional walks, strikeouts, RBIs, stolen bases, caught stealing, hit by pitch, sacrifice bunts, sacrifice flies, game_date, strike_count, success_with_2_strikes
Optional batting (only record if the user mentions them; never require them): hard-hit balls (balls squared up, outs included), quality at-bats (hit, walk/HBP, 6+ pitch AB, hard-hit out, sac, moved a runner, or RBI)
- Intentional walks are part of the walks total. Sacrifice bunts and sacrifice flies are separate and neither counts as an at bat.
Pitching: innings pitched, earned runs, walks, strikeouts, pitches thrown, complete games, shutouts, saves, ERA, WHIP
Fielding: position, putouts, assists, errors, double plays

REQUIRED FIELDS FOR EVERY ENTRY:
- game_date: When did the game happen? (ask if not mentioned, conversationally)
- strike_count: How many strikes total in your at-bats? (ask if not mentioned, conversationally)
- success_with_2_strikes: How many hits with 2 strikes? (ask if not mentioned, conversationally)
- All batting/pitching/fielding stats available (collect gently over the conversation)

ACCEPTED STAT FORMATS (Be flexible with all variations):
- "I went 2 for 3" = 3 at bats, 2 hits
- "Got 1 HR" = 1 home run
- "3 Ks" = 3 strikeouts
- "2/4 with an RBI" = 4 at bats, 2 hits, 1 RBI
- "Pitched 5 innings, 2 ERs" = 5 innings pitched, 2 earned runs
- "Got a hit" = 1 hit (infer 1 at bat)
- "Struck out 10" = 10 strikeouts
- "3 RBIs" = 3 RBIs
- "Doubled" = 1 double
- "Home run!" = 1 home run
- "1-2, walk, HR" = variations with slashes
- "0 for 4" = 4 at bats, 0 hits
- "Perfect game" = 0 walks, 0 hits allowed
- "No hitter" = 0 hits allowed
- "5K night" = 5 strikeouts in a game

STAT EXTRACTION:
- Extract ANY identifiable stat from user message
- Make educated guesses from context
- If multiple stats, mention them all naturally in conversation
- **IMPORTANT**: Always ask for MISSING REQUIRED FIELDS in a conversational way:
  - game_date - "When did this game happen?"
  - strike_count - "How many strikes did you get in total?"
  - success_with_2_strikes - "How many hits did you get with 2 strikes?"
- Only ask for 1-2 missing fields per turn (don't overwhelm)
- Once you have all required fields, suggest saving naturally

GOOD RESPONSE EXAMPLES:
"Nice work today! Getting 2 hits in 4 at bats is solid. How were you seeing the ball?"

"That's a great line - 3 for 4 with a double and an RBI. You're seeing it well lately."

"Looks like a tough day at the plate, but you got a walk. What was the pitcher throwing?"

BAD RESPONSE FORMATS (avoid):
- Dumping JSON or `{key: value}` blobs in the visible reply
- Fake markdown like *2 hits* used as decoration on every word

ALWAYS: Clear, well-spaced prose; use lists only when they help the reader scan

CRITICAL (FOR APP ONLY): When you have extracted stats and are ready to save, include the following JSON INSIDE the tags <STATS_JSON> ... </STATS_JSON> at the VERY END of your reply. Do NOT wrap it in code fences or show any other code-like formatting. Everything BEFORE the tags must be purely natural language:
<STATS_JSON>
{
  "at_bats": (number or null),
  "hits": (number or null),
  "runs": (number or null),
  "home_runs": (number or null),
  "rbi": (number or null),
  "strikeouts": (number or null),
  "doubles": (number or null),
  "triples": (number or null),
  "walks": (number or null),
  "intentional_walks": (number or null),
  "hit_by_pitch": (number or null),
  "stolen_bases": (number or null),
  "sacrifice_bunts": (number or null),
  "sacrifice_flies": (number or null),
  "hard_hit_balls": (number or null, only if the user gave it),
  "quality_at_bats": (number or null, only if the user gave it),
  "strike_count": (number or null),
  "success_with_2_strikes": (number or null),
  "game_date": (string like "2025-10-24" or null)
}
</STATS_JSON>

This allows the app to automatically capture all stats and save them.

Collected stats so far: ${jsonEncode(_collectedStats)}

Remember: You're a general-purpose AI assistant first (like ChatGPT), and a stats tracker when needed. Be flexible, understanding, and ready to help with ANY topic. Engage in natural conversation about anything the user wants to discuss. Use web search to provide current, accurate information when questions require real-time data. Always respond naturally and conversationally!'''
    };

    try {
      final aiMessages = [systemPrompt, ...messagesForAI];
      final lowerUserText = userMessage.content.toLowerCase();
      final shouldUseWebSearch = RegExp(
        r'(today|yesterday|tonight|right now|latest|current|live|score|scores|won|win|news|breaking)',
      ).hasMatch(lowerUserText);

      final aiResponse = await _aiService.getAIResponse(
        aiMessages,
        systemPrompt: systemPrompt['content'],
        statAnalysisContext: _statAnalysisContext,
        useWebSearch: shouldUseWebSearch,
      );

      // Clean response: remove JSON tags for display
      final cleanedResponse = _cleanAIResponse(aiResponse);

      final assistantMessage = ChatMessage(
        id: DateTime.now().toString(),
        role: 'assistant',
        content: cleanedResponse,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      // Save both messages to Firebase
      await _saveMessageToFirebase(userMessage);
      await _saveMessageToFirebase(assistantMessage);

      // Haptic feedback when message is received
      await HapticHelper.selection();

      _scrollToBottom(force: true);

      // Extract stats from conversation AND from AI's JSON response
      _extractStatsFromConversation(userMessage.content);
      _extractStatsFromAIResponse(aiResponse);  // Use original response for JSON extraction
      
      // CRITICAL FIX: Only save when USER explicitly says to log/save/update stats
      // Don't auto-save just because AI said something - user must command it!
      final userMessageLower = userMessage.content.toLowerCase().trim();
      
      // Comprehensive list of save/log/update command variations
      final saveCommands = [
        // Direct log commands
        'log it', 'log my', 'log the', 'log these', 'log my game', 'log my stats',
        'log stats', 'log game', 'log that', 'log this', 'log them',
        // Direct save commands
        'save it', 'save my', 'save the', 'save these', 'save my game', 'save my stats',
        'save stats', 'save game', 'save that', 'save this', 'save them',
        // Update commands
        'update stats', 'update my stats', 'update it', 'update my game',
        'update game', 'update the stats', 'update these stats',
        // Record commands
        'record it', 'record my', 'record stats', 'record my stats', 'record game',
        'record my game', 'record the stats', 'record these stats',
        // Enter/add commands
        'enter it', 'enter stats', 'enter my stats', 'enter game', 'enter my game',
        'add it', 'add stats', 'add my stats', 'add game', 'add my game',
        // Completion signals
        'done', 'that\'s it', 'that is it', 'finished', 'complete',
        'all set', 'got it', 'ok', 'okay',
        // Store/keep commands
        'store it', 'store stats', 'store my stats', 'keep it', 'keep stats',
        // Track/follow commands
        'track it', 'track stats', 'track my stats', 'track this',
        // Put/input commands
        'put it in', 'put in', 'input stats', 'input my stats',
        // Commit/finalize commands
        'commit', 'commit stats', 'finalize', 'finalize stats',
      ];
      
      // Check if message contains any save command
      final shouldSave = saveCommands.any((command) => userMessageLower.contains(command));
      
      if (shouldSave) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _saveStatsToFirebase();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final parsed = _parseZunoChatError(e);

      // Show Zuno's "reply" in the chat so the UI feels normal
      final assistantMessage = ChatMessage(
        id: DateTime.now().toString(),
        role: 'assistant',
        content: parsed.userMessage,
        timestamp: DateTime.now(),
      );
      setState(() => _messages.add(assistantMessage));
      _scrollToBottom(force: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(parsed.snackBar),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Player-facing copy for a failed Zuno request. Details go to the log only.
  ({String userMessage, String snackBar}) _parseZunoChatError(Object e) {
    debugPrint('Zuno chat error: $e');
    const unavailable = (
      userMessage:
          "Zuno can't respond right now. Check your connection and try again in a minute.",
      snackBar: 'Zuno is unavailable. Try again shortly',
    );
    if (e is FirebaseFunctionsException) {
      final msg = (e.message ?? '').toLowerCase();
      if (e.code == 'failed-precondition' && msg.contains('blocked')) {
        return (
          userMessage:
              'That message could not be processed. Try rephrasing or a shorter message.',
          snackBar: 'Try different wording',
        );
      }
      if (e.code == 'resource-exhausted') {
        return (
          userMessage:
              "Zuno is getting a lot of requests right now. Try again in a minute.",
          snackBar: 'Zuno is busy. Try again shortly',
        );
      }
      if (e.code == 'unauthenticated') {
        return (
          userMessage: 'Please sign out and back in, then try again.',
          snackBar: 'Please sign in again',
        );
      }
      return unavailable;
    }
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('unavailable') ||
        errStr.contains('connection') ||
        errStr.contains('network') ||
        errStr.contains('timeout')) {
      return unavailable;
    }
    return (
      userMessage: 'Something went wrong. Please try again.',
      snackBar: 'Please try again',
    );
  }

  String _cleanAIResponse(String response) {
    // 1) Remove the entire <STATS_JSON>...</STATS_JSON> block (hidden machine-readable section)
    var cleaned = response.replaceAll(
      RegExp(r'<STATS_JSON>[\s\S]*?</STATS_JSON>', dotAll: true),
      '',
    );
    // 2) Normalize line endings; keep paragraph breaks for markdown rendering
    cleaned = cleaned.replaceAll('\r\n', '\n').trim();
    cleaned = cleaned.split('\n').map((l) => l.trimRight()).join('\n');
    // 3) Cap excessive blank lines (keeps ChatGPT-like spacing without huge gaps)
    cleaned = cleaned.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');
    return cleaned.trim();
  }

  void _extractStatsFromConversation(String userMessageContent) {
    final lowerCaseContent = userMessageContent.toLowerCase();
    print('🔍 [EXTRACT] Processing: "$lowerCaseContent"');

    // ========== 100+ EXTRACTION PATTERNS ==========
    // Comprehensive extraction covering all variations of user input
    
    // COMBINED HITS & AT BATS PATTERNS (Most Common)
    
    // Pattern 1: "X hits in Y at bats" / "X for Y at bats"
    final hitsInAtBatsPattern = RegExp(r'(\d+)\s+(?:hits?|for|hit|went|got)\s+(?:in\s+)?(\d+)\s+(?:at[\s-]?bats?|ab|plate appearances|pas)');
    final hitsMatch = hitsInAtBatsPattern.firstMatch(lowerCaseContent);
    if (hitsMatch != null) {
      final hits = int.tryParse(hitsMatch.group(1) ?? '') ?? 0;
      final atBats = int.tryParse(hitsMatch.group(2) ?? '') ?? 0;
      _collectedStats['hits'] = hits;
      _collectedStats['at_bats'] = atBats;
      print('✅ [EXTRACT] Pattern 1 matched: hits=$hits, at_bats=$atBats');
    } else {
      // Pattern 2: "X at bats with Y hits" / "X at bats, Y hits"
      final atBatsWithHitsPattern = RegExp(r'(\d+)\s+at[\s-]?bats?\s+(?:with\s+)?(\d+)\s+hits?');
      final atBatsMatch = atBatsWithHitsPattern.firstMatch(lowerCaseContent);
      if (atBatsMatch != null) {
        final atBats = int.tryParse(atBatsMatch.group(1) ?? '') ?? 0;
        final hits = int.tryParse(atBatsMatch.group(2) ?? '') ?? 0;
        _collectedStats['hits'] = hits;
        _collectedStats['at_bats'] = atBats;
        print('✅ [EXTRACT] Pattern 2 matched: hits=$hits, at_bats=$atBats');
      } else {
        // Pattern 3: "went X for Y" (common baseball phrase)
        final wentForPattern = RegExp(r'went\s+(\d+)\s+for\s+(\d+)');
        final wentMatch = wentForPattern.firstMatch(lowerCaseContent);
        if (wentMatch != null) {
          final hits = int.tryParse(wentMatch.group(1) ?? '') ?? 0;
          final atBats = int.tryParse(wentMatch.group(2) ?? '') ?? 0;
          _collectedStats['hits'] = hits;
          _collectedStats['at_bats'] = atBats;
          print('✅ [EXTRACT] Pattern 3 matched: hits=$hits, at_bats=$atBats');
        } else {
          // Pattern 4: "X-Y" format (hits-at bats) - FIXED ORDER  
          final dashPattern = RegExp(r'(\d+)[\s-/:]+(\d+)(?:\s+(?:at[\s-]?bats?|ab|plate appearances|pas))?');
          final dashMatch = dashPattern.firstMatch(lowerCaseContent);
          if (dashMatch != null && (lowerCaseContent.contains('hit') || lowerCaseContent.contains('went') || lowerCaseContent.contains('for'))) {
            // For "2-4" or "2/4" format, first number is hits, second is at bats
            final hits = int.tryParse(dashMatch.group(1) ?? '') ?? 0;
            final atBats = int.tryParse(dashMatch.group(2) ?? '') ?? 0;
            _collectedStats['hits'] = hits;
            _collectedStats['at_bats'] = atBats;
            print('✅ [EXTRACT] Pattern 4 matched: hits=$hits, at_bats=$atBats');
          } else {
            // Pattern 5: "X/Y" fraction format
            final fractionPattern = RegExp(r'(\d+)/(\d+)(?:\s+(?:at[\s-]?bats?|ab|plate appearances|pas))?');
            final fractionMatch = fractionPattern.firstMatch(lowerCaseContent);
            if (fractionMatch != null && (lowerCaseContent.contains('hit') || lowerCaseContent.contains('went') || lowerCaseContent.contains('for'))) {
              final hits = int.tryParse(fractionMatch.group(1) ?? '') ?? 0;
              final atBats = int.tryParse(fractionMatch.group(2) ?? '') ?? 0;
              _collectedStats['hits'] = hits;
              _collectedStats['at_bats'] = atBats;
              print('✅ [EXTRACT] Pattern 5 matched: hits=$hits, at_bats=$atBats');
            } else {
              print('❌ [EXTRACT] No pattern matched, trying individual extraction');
              // Fallback for individual stat extraction
              if (lowerCaseContent.contains('at bats') || lowerCaseContent.contains('at_bats')) {
                _collectedStats['at_bats'] = _extractNumberAfterKeyword(lowerCaseContent, ['at bats', 'at_bats']);
                print('🔍 [EXTRACT] Individual at_bats: ${_collectedStats['at_bats']}');
              }
              if (lowerCaseContent.contains('hits')) {
                _collectedStats['hits'] = _extractNumberAfterKeyword(lowerCaseContent, ['hits']);
                print('🔍 [EXTRACT] Individual hits: ${_collectedStats['hits']}');
              }
            }
          }
        }
      }
    }
    
    // INDIVIDUAL STAT EXTRACTION - 100+ VARIATIONS
    
    // Runs (not home runs)
    if (lowerCaseContent.contains('run') && !lowerCaseContent.contains('home run') && !lowerCaseContent.contains('earned run')) {
      _collectedStats['runs'] = _extractNumberAfterKeyword(lowerCaseContent, ['runs', 'run', 'scored']);
    }
    
    // Doubles
    if (lowerCaseContent.contains('doub') && !lowerCaseContent.contains('doubled')) {
      _collectedStats['doubles'] = _extractNumberAfterKeyword(lowerCaseContent, ['doubles', 'double', '2b']);
    }
    
    // Triples  
    if (lowerCaseContent.contains('trip')) {
      _collectedStats['triples'] = _extractNumberAfterKeyword(lowerCaseContent, ['triples', 'triple', '3b']);
    }
    
    // Home runs - MANY variations
    if (lowerCaseContent.contains('homer') || lowerCaseContent.contains('homeruns') || lowerCaseContent.contains('home run') || 
        lowerCaseContent.contains('hr') || lowerCaseContent.contains('dinger') || lowerCaseContent.contains('bomb')) {
      _collectedStats['home_runs'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'home runs', 'home_runs', 'homer', 'homers', 'homeruns', 'hr', 'hrs', 'dingers', 'bombs'
      ]);
    }
    
    // RBI - many variations
    if (lowerCaseContent.contains('rbi') || lowerCaseContent.contains('r.b.i') || lowerCaseContent.contains('batted in')) {
      _collectedStats['rbi'] = _extractNumberAfterKeyword(lowerCaseContent, ['rbi', 'rbis', 'r.b.i', 'batted in']);
    }
    
    // Walks/BB
    if (lowerCaseContent.contains('walk') || lowerCaseContent.contains(' bb') || lowerCaseContent.contains('base on ball')) {
      _collectedStats['walks'] = _extractNumberAfterKeyword(lowerCaseContent, ['walks', 'walk', 'bb', 'base on balls']);
    }
    
    // Strikeouts/Ks
    if (lowerCaseContent.contains('strike') || lowerCaseContent.contains(' ks ') || lowerCaseContent.contains(' strikeout') || 
        lowerCaseContent.contains('punch') || lowerCaseContent.contains('fanned')) {
      _collectedStats['strikeouts'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'strikeouts', 'strikeout', 'strike outs', 'strike out', ' ks ', 'k\'s', 'kays', 'punchouts', 'punch out', 
        'fanned', 'fan', 'swing and miss'
      ]);
    }
    
    // Intentional walks
    if (lowerCaseContent.contains('intentional') || lowerCaseContent.contains('ibb')) {
      _collectedStats['intentional_walks'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'intentional walks', 'intentional walk', 'intentionally walked', 'ibb'
      ]);
    }

    // Sacrifice flies / bunts
    if (lowerCaseContent.contains('sac fl') || lowerCaseContent.contains('sacrifice fl')) {
      _collectedStats['sacrifice_flies'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'sacrifice flies', 'sacrifice fly', 'sac flies', 'sac fly'
      ]);
    }
    if (lowerCaseContent.contains('sac bunt') || lowerCaseContent.contains('sacrifice bunt')) {
      _collectedStats['sacrifice_bunts'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'sacrifice bunts', 'sacrifice bunt', 'sac bunts', 'sac bunt'
      ]);
    }

    // Hard-hit balls and quality at-bats (optional)
    if (lowerCaseContent.contains('hard hit') || lowerCaseContent.contains('hard-hit')) {
      _collectedStats['hard_hit_balls'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'hard hit balls', 'hard-hit balls', 'hard hit', 'hard-hit'
      ]);
    }
    if (lowerCaseContent.contains('quality at') || lowerCaseContent.contains('qab')) {
      _collectedStats['quality_at_bats'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'quality at bats', 'quality at-bats', 'quality abs', 'qabs', 'qab'
      ]);
    }

    // Strike count
    if (lowerCaseContent.contains('strike') && (lowerCaseContent.contains('count') || lowerCaseContent.contains('total') || 
        lowerCaseContent.contains('saw'))) {
      _collectedStats['strike_count'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'strike count', 'strikes', 'strike total', 'saw.*strikes'
      ]);
    }
    
    // Success with 2 strikes
    if (lowerCaseContent.contains('2 strike') && (lowerCaseContent.contains('hit') || lowerCaseContent.contains('success'))) {
      _collectedStats['success_with_2_strikes'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'success with 2 strikes', 'hits with 2 strikes', 'hit on 2 strikes', '2 strike hits', 'clutch hits'
      ]);
    }

    // Pitching stats - MANY variations
    if (lowerCaseContent.contains('inning') && !lowerCaseContent.contains('bat')) {
      _collectedStats['innings_pitched'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'innings pitched', 'innings_pitched', 'ip', 'innings', 'frames'
      ]);
    }
    
    // Earned runs
    if (lowerCaseContent.contains('earned run') || lowerCaseContent.contains('er')) {
      _collectedStats['earned_runs'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'earned runs', 'earned_runs', 'er', 'earned'
      ]);
    }
    
    // Pitches thrown
    if (lowerCaseContent.contains('pitches thrown') || lowerCaseContent.contains('pitches')) {
      _collectedStats['pitches_thrown'] = _extractNumberAfterKeyword(lowerCaseContent, [
        'pitches thrown', 'pitches_thrown', 'total pitches', 'pitches'
      ]);
    }
    
    // Complete games
    if (lowerCaseContent.contains('complete game') || lowerCaseContent.contains('cg')) {
      _collectedStats['complete_games'] = lowerCaseContent.contains('complete') ? 1 : 0;
    }
    
    // Shutouts
    if (lowerCaseContent.contains('shutout') || lowerCaseContent.contains('so')) {
      _collectedStats['shutouts'] = lowerCaseContent.contains('shutout') ? 1 : 0;
    }
    
    // Saves
    if (lowerCaseContent.contains('save') || lowerCaseContent.contains('sv')) {
      _collectedStats['saves'] = _extractNumberAfterKeyword(lowerCaseContent, ['saves', 'save', 'sv']);
    }

    // Fielding stats - MANY variations
    if (lowerCaseContent.contains('assist')) {
      _collectedStats['assists'] = _extractNumberAfterKeyword(lowerCaseContent, ['assists', 'assist']);
    }
    
    if (lowerCaseContent.contains('error')) {
      _collectedStats['errors'] = _extractNumberAfterKeyword(lowerCaseContent, ['errors', 'error', 'err']);
    }
    
    if (lowerCaseContent.contains('putout') || lowerCaseContent.contains('put out')) {
      _collectedStats['putouts'] = _extractNumberAfterKeyword(lowerCaseContent, ['putouts', 'putout', 'put outs']);
    }
    
    if (lowerCaseContent.contains('double play') || lowerCaseContent.contains('dp')) {
      _collectedStats['double_plays'] = _extractNumberAfterKeyword(lowerCaseContent, ['double plays', 'double play', 'dp']);
    }
    
    // Advanced stat patterns with context
    if (lowerCaseContent.contains('batting average')) {
      final avgMatch = RegExp(r'batting average[:\s]+(\d+\.?\d*)').firstMatch(lowerCaseContent);
      if (avgMatch != null) {
        // Calculate hits from average if we have at bats
        final avg = double.tryParse(avgMatch.group(1) ?? '') ?? 0;
        if (_collectedStats.containsKey('at_bats') && _collectedStats['at_bats'] > 0) {
          _collectedStats['hits'] = (avg * _collectedStats['at_bats']!).round();
        }
      }
    }
    
    // Extract game date - MANY formats
    final datePatterns = [
      RegExp(r'(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})'), // 10/26/25, 10-26-2025
      RegExp(r'(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{2,4})', caseSensitive: false), // 26 October 2025
      RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2}),?\s+(\d{2,4})', caseSensitive: false), // October 26, 2025
      RegExp(r'(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})'), // 2025/10/26
      RegExp(r'(\d{1,2})\/(\d{1,2})\/(\d{2,4})'), // 10/26/25
      RegExp(r'(\d{2})[-\/](\d{2})[-\/](\d{2})'), // 10-26-25
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(lowerCaseContent);
      if (match != null) {
        try {
          final groups = [match.group(1)!, match.group(2)!, match.group(3)!];
          // Parse based on format and create proper date string
          String dateStr;
          if (groups[2].length == 4) {
            // YYYY-MM-DD format
            dateStr = '${groups[0]}-${groups[1].padLeft(2, '0')}-${groups[2].padLeft(2, '0')}';
          } else {
            // MM/DD/YY or similar
            final year = int.tryParse(groups[2]) ?? 25;
            final yearStr = year < 50 ? '20$year' : '19$year';
            dateStr = '${groups[0].padLeft(2, '0')}-${groups[1].padLeft(2, '0')}-$yearStr';
          }
          _collectedStats['game_date'] = dateStr;
          print('✅ [EXTRACT] Game date extracted: $dateStr');
          break;
        } catch (e) {
          print('⚠️ [EXTRACT] Date parsing error: $e');
        }
      }
    }
    
    print('📊 [EXTRACT] Final collected stats: $_collectedStats');
  }

  /// Keys Zuno may return in the hidden `<STATS_JSON>` block.
  static const Set<String> _statsJsonKeys = {
    'at_bats', 'hits', 'runs', 'doubles', 'triples', 'home_runs', 'rbi',
    'walks', 'intentional_walks', 'hit_by_pitch', 'strikeouts', 'stolen_bases',
    'sacrifice_bunts', 'sacrifice_flies', 'hard_hit_balls', 'quality_at_bats',
    'strike_count', 'success_with_2_strikes',
  };

  void _extractStatsFromAIResponse(String aiResponse) {
    final block = RegExp(r'<STATS_JSON>([\s\S]*?)</STATS_JSON>').firstMatch(aiResponse);
    if (block != null) {
      try {
        final decoded = jsonDecode(block.group(1)!.trim());
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (_statsJsonKeys.contains(key) && value is num) {
              _collectedStats[key as String] = value.toInt();
            } else if (key == 'game_date' && value is String && value.isNotEmpty) {
              _collectedStats['game_date'] = value;
            }
          });
        }
      } catch (_) {
        // Malformed block; fall back to the regex and keyword extraction.
      }
    }

    // Extract game_date from the AI's JSON response
    final dateMatch = RegExp(r'game_date: "(\d{4}-\d{2}-\d{2})"').firstMatch(aiResponse);
    if (dateMatch != null) {
      _collectedStats['game_date'] = dateMatch.group(1);
    }

    // Extract strike_count from the AI's JSON response
    final strikeCountMatch = RegExp(r'strike_count: (\d+)').firstMatch(aiResponse);
    if (strikeCountMatch != null) {
      _collectedStats['strike_count'] = int.tryParse(strikeCountMatch.group(1) ?? '');
    }

    // Extract success_with_2_strikes from the AI's JSON response
    final successWith2StrikesMatch = RegExp(r'success_with_2_strikes: (\d+)').firstMatch(aiResponse);
    if (successWith2StrikesMatch != null) {
      _collectedStats['success_with_2_strikes'] = int.tryParse(successWith2StrikesMatch.group(1) ?? '');
    }
  }


  int _extractNumberAfterKeyword(String text, List<String> keywords) {
    final lowerText = text.toLowerCase();
    for (final keyword in keywords) {
      final index = lowerText.indexOf(keyword);
      if (index != -1) {
        // Get text after the keyword
        final afterKeyword = lowerText.substring(index + keyword.length);
        // Find first number after keyword
        final match = RegExp(r'(\d+)').firstMatch(afterKeyword);
        if (match != null) {
          return int.tryParse(match.group(1) ?? '') ?? 0;
        }
      }
    }
    return 0;
  }

  Future<void> _saveStatsToFirebase() async {
    if (_currentUser == null || _collectedStats.isEmpty) return;

    try {
      final firebaseService = FirebaseStatsService();
      final activeSeasonDoc = await firebaseService.getActiveSeason();
      final seasonId = activeSeasonDoc?.id;
      
      if (seasonId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active season found. Please create a season first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('📝 [ZUNO] Saving stats to season: $seasonId');
      print('📝 [ZUNO] Collected stats: ${_collectedStats.toString()}');

      // ✅ STANDARDIZED GAME DATA FORMAT
      // This must match EXACTLY what dashboard expects
      final gameData = {
        // Core timestamp - single source of truth
        'date': Timestamp.now(),
        'gameDate': _collectedStats['game_date'] as String? ?? DateTime.now().toString().split(' ')[0],
        
        // Stats wrapped in 'stats' object
        'stats': {
          // Batting stats
          'at_bats': _collectedStats['at_bats'] as int? ?? 0,
          'hits': _collectedStats['hits'] as int? ?? 0,
          'runs': _collectedStats['runs'] as int? ?? 0,
          'doubles': _collectedStats['doubles'] as int? ?? 0,
          'triples': _collectedStats['triples'] as int? ?? 0,
          'home_runs': _collectedStats['home_runs'] as int? ?? 0,
          'rbi': _collectedStats['rbi'] as int? ?? 0,
          'walks': _collectedStats['walks'] as int? ?? 0,
          'strikeouts': _collectedStats['strikeouts'] as int? ?? 0,
          'strike_count': _collectedStats['strike_count'] as int? ?? 0,
          'success_with_2_strikes': _collectedStats['success_with_2_strikes'] as int? ?? 0,
          'stolen_bases': _collectedStats['stolen_bases'] as int? ?? 0,
          'caught_stealing': _collectedStats['caught_stealing'] as int? ?? 0,
          'hit_by_pitch': _collectedStats['hit_by_pitch'] as int? ?? 0,
          'intentional_walks': _collectedStats['intentional_walks'] as int? ?? 0,
          'sacrifice_hits': _collectedStats['sacrifice_bunts'] as int? ?? 0,
          'sacrifice_flies': _collectedStats['sacrifice_flies'] as int? ?? 0,
          // Optional: only saved when the player gave them.
          if (_collectedStats['hard_hit_balls'] is int)
            'hard_hit_balls': _collectedStats['hard_hit_balls'],
          if (_collectedStats['quality_at_bats'] is int)
            'quality_at_bats': _collectedStats['quality_at_bats'],
          
          // Pitching stats
          'innings_pitched': _collectedStats['innings_pitched'] as int? ?? 0,
          'earned_runs': _collectedStats['earned_runs'] as int? ?? 0,
          'pitches_thrown': _collectedStats['pitches_thrown'] as int? ?? 0,
          'complete_games': _collectedStats['complete_games'] as int? ?? 0,
          'shutouts': _collectedStats['shutouts'] as int? ?? 0,
          'saves': _collectedStats['saves'] as int? ?? 0,
          'era': _collectedStats['era'] as double? ?? 0.0,
          'whip': _collectedStats['whip'] as double? ?? 0.0,
          
          // Fielding stats
          'assists': _collectedStats['assists'] as int? ?? 0,
          'errors': _collectedStats['errors'] as int? ?? 0,
          'putouts': _collectedStats['putouts'] as int? ?? 0,
          'double_plays': _collectedStats['double_plays'] as int? ?? 0,
        },
        
        // Metadata
        'source': 'zuno_conversation',
        'sessionId': _currentSessionId,
        'ownerId': _currentUser.uid,
      };

      print('💾 [ZUNO] Game data prepared with ${gameData['stats'].toString().length} bytes of stats');

      // ✅ SAVE TO THE CORRECT PATH
      final gameRef = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('seasons')
          .doc(seasonId)
          .collection('games')
          .add(gameData);

      print('✅ [ZUNO] Stats saved to game: ${gameRef.id}');

      // ✅ UPDATE AGGREGATED STATS
      await _updateAggregatedStats(seasonId);
      print('✅ [ZUNO] Aggregated stats updated');

      // ✅ BROADCAST TO ALL LISTENERS (Dashboard, Stats Screen, History Screen)
      print('📢 [BROADCAST] About to notify all screens of update...');
      StatsUpdateService().notifyStatsUpdated(
        userId: _currentUser.uid,
        seasonId: seasonId,
        statsData: gameData,
      );
      print('📢 [BROADCAST] Notification sent to all screens!');

      // Clear for next entry
      setState(() {
        _collectedStats.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stats saved and updated everywhere!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ [ERROR] Failed to save stats: $e');
      print('❌ [STACK] ${StackTrace.current}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(friendlyError(e, "Couldn't save your stats")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAggregatedStats(String seasonId) async {
    try {
      if (_currentUser == null) return;
      
      print('📊 [AGG] Starting aggregated stats calculation for season: $seasonId');
      
      // Get all games for the season
      final gamesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('seasons')
          .doc(seasonId)
          .collection('games')
          .get();

      final games = gamesSnapshot.docs;
      print('📊 [AGG] Found ${games.length} games to aggregate');
      
      if (games.isEmpty) {
        print('📊 [AGG] No games found, skipping aggregation');
        return;
      }

      // Calculate aggregated stats
      Map<String, dynamic> aggregated = {
        'season_id': seasonId,
        'last_updated': Timestamp.now(),
        'game_count': games.length,
        
        // Batting totals
        'hits': 0,
        'at_bats': 0,
        'runs': 0,
        'home_runs': 0,
        'rbi': 0,
        'strikeouts': 0,
        'walks': 0,
        'doubles': 0,
        'triples': 0,
        'stolen_bases': 0,
        'caught_stealing': 0,
        'hit_by_pitch': 0,
        'strike_count': 0,
        'success_with_2_strikes': 0,
        
        // Pitching totals
        'innings_pitched': 0,
        'earned_runs': 0,
        'pitches_thrown': 0,
        'complete_games': 0,
        'shutouts': 0,
        'saves': 0,
        
        // Fielding totals
        'assists': 0,
        'errors': 0,
        'putouts': 0,
        'double_plays': 0,
      };

      // Loop through each game and sum up stats
      for (var gameDoc in games) {
        final gameData = gameDoc.data();
        
        // Access nested stats field - THIS IS CRITICAL!
        final stats = (gameData['stats'] as Map<String, dynamic>?) ?? {};
        
        // DEBUG: Check if this game has the old structure (stats at root level)
        bool hasHits = gameData.containsKey('hits') || (stats.isNotEmpty && (stats.containsKey('hits') || stats.containsKey('hitCount')));
        print('🔍 [AGG] Game ${gameDoc.id}: stats.isEmpty=${stats.isEmpty}, hasHits=$hasHits, hasStats=${gameData.containsKey('stats')}');
        print('🔍 [DEBUG] Stats keys: ${stats.keys}');
        
        if (stats.isEmpty && gameData.containsKey('hits')) {
          print('⚠️ [AGG] Game ${gameDoc.id} has OLD structure - stats at root level');
          print('⚠️ [AGG] Old game stats: hits=${gameData['hits']}, at_bats=${gameData['at_bats']}');
          // For old games, use the root level stats
          aggregated['hits'] = (aggregated['hits'] as int) + (gameData['hits'] as int? ?? 0);
          aggregated['at_bats'] = (aggregated['at_bats'] as int) + (gameData['at_bats'] as int? ?? 0);
          aggregated['runs'] = (aggregated['runs'] as int) + (gameData['runs'] as int? ?? 0);
          aggregated['home_runs'] = (aggregated['home_runs'] as int) + (gameData['home_runs'] as int? ?? 0);
          aggregated['rbi'] = (aggregated['rbi'] as int) + (gameData['rbi'] as int? ?? 0);
          aggregated['strikeouts'] = (aggregated['strikeouts'] as int) + (gameData['strikeouts'] as int? ?? 0);
          aggregated['walks'] = (aggregated['walks'] as int) + (gameData['walks'] as int? ?? 0);
          aggregated['doubles'] = (aggregated['doubles'] as int) + (gameData['doubles'] as int? ?? 0);
          aggregated['triples'] = (aggregated['triples'] as int) + (gameData['triples'] as int? ?? 0);
          aggregated['stolen_bases'] = (aggregated['stolen_bases'] as int) + (gameData['stolen_bases'] as int? ?? 0);
          aggregated['caught_stealing'] = (aggregated['caught_stealing'] as int) + (gameData['caught_stealing'] as int? ?? 0);
          aggregated['hit_by_pitch'] = (aggregated['hit_by_pitch'] as int) + (gameData['hit_by_pitch'] as int? ?? 0);
          aggregated['strike_count'] = (aggregated['strike_count'] as int) + (gameData['strike_count'] as int? ?? 0);
          aggregated['success_with_2_strikes'] = (aggregated['success_with_2_strikes'] as int) + (gameData['success_with_2_strikes'] as int? ?? 0);
          
          // Add pitching stats
          aggregated['innings_pitched'] = (aggregated['innings_pitched'] as int) + (gameData['innings_pitched'] as int? ?? 0);
          aggregated['earned_runs'] = (aggregated['earned_runs'] as int) + (gameData['earned_runs'] as int? ?? 0);
          aggregated['pitches_thrown'] = (aggregated['pitches_thrown'] as int) + (gameData['pitches_thrown'] as int? ?? 0);
          aggregated['complete_games'] = (aggregated['complete_games'] as int) + (gameData['complete_games'] as int? ?? 0);
          aggregated['shutouts'] = (aggregated['shutouts'] as int) + (gameData['shutouts'] as int? ?? 0);
          aggregated['saves'] = (aggregated['saves'] as int) + (gameData['saves'] as int? ?? 0);
          
          // Add fielding stats
          aggregated['assists'] = (aggregated['assists'] as int) + (gameData['assists'] as int? ?? 0);
          aggregated['errors'] = (aggregated['errors'] as int) + (gameData['errors'] as int? ?? 0);
          aggregated['putouts'] = (aggregated['putouts'] as int) + (gameData['putouts'] as int? ?? 0);
          aggregated['double_plays'] = (aggregated['double_plays'] as int) + (gameData['double_plays'] as int? ?? 0);
          continue;
        }
        
        // DEBUG: Check if this game has NO stats at all
        if (stats.isEmpty && !gameData.containsKey('hits')) {
          print('⚠️ [AGG] Game ${gameDoc.id} has NO stats - skipping');
          continue;
        }
        
        print('📊 [AGG] Processing game ${gameDoc.id}: ${stats.isEmpty ? 'EMPTY' : 'has stats'}');
        
              if (stats.isNotEmpty) {
                // Add batting stats - HANDLE BOTH OLD AND NEW KEY NAMES
                aggregated['hits'] = (aggregated['hits'] as int) + (stats['hits'] as int? ?? stats['hitCount'] as int? ?? 0);
                aggregated['at_bats'] = (aggregated['at_bats'] as int) + (stats['at_bats'] as int? ?? stats['atBatCount'] as int? ?? 0);
                aggregated['runs'] = (aggregated['runs'] as int) + (stats['runs'] as int? ?? stats['runCount'] as int? ?? 0);
                aggregated['home_runs'] = (aggregated['home_runs'] as int) + (stats['home_runs'] as int? ?? stats['homeRunCount'] as int? ?? 0);
                aggregated['rbi'] = (aggregated['rbi'] as int) + (stats['rbi'] as int? ?? stats['rbiCount'] as int? ?? 0);
                aggregated['strikeouts'] = (aggregated['strikeouts'] as int) + (stats['strikeouts'] as int? ?? stats['strikeoutCount'] as int? ?? 0);
                aggregated['walks'] = (aggregated['walks'] as int) + (stats['walks'] as int? ?? stats['walkCount'] as int? ?? 0);
                aggregated['doubles'] = (aggregated['doubles'] as int) + (stats['doubles'] as int? ?? stats['doubleCount'] as int? ?? 0);
                aggregated['triples'] = (aggregated['triples'] as int) + (stats['triples'] as int? ?? stats['tripleCount'] as int? ?? 0);
                aggregated['stolen_bases'] = (aggregated['stolen_bases'] as int) + (stats['stolen_bases'] as int? ?? stats['stolenBaseCount'] as int? ?? 0);
                aggregated['caught_stealing'] = (aggregated['caught_stealing'] as int) + (stats['caught_stealing'] as int? ?? stats['caughtStealingCount'] as int? ?? 0);
                aggregated['hit_by_pitch'] = (aggregated['hit_by_pitch'] as int) + (stats['hit_by_pitch'] as int? ?? stats['hitByPitchCount'] as int? ?? 0);
                aggregated['strike_count'] = (aggregated['strike_count'] as int) + (stats['strike_count'] as int? ?? stats['strikeCount'] as int? ?? 0);
                aggregated['success_with_2_strikes'] = (aggregated['success_with_2_strikes'] as int) + (stats['success_with_2_strikes'] as int? ?? stats['successWith2StrikesCount'] as int? ?? 0);
                
                // Add pitching stats
                aggregated['innings_pitched'] = (aggregated['innings_pitched'] as int) + (stats['innings_pitched'] as int? ?? stats['inningsPitchedCount'] as int? ?? 0);
                aggregated['earned_runs'] = (aggregated['earned_runs'] as int) + (stats['earned_runs'] as int? ?? stats['earnedRunCount'] as int? ?? 0);
                aggregated['pitches_thrown'] = (aggregated['pitches_thrown'] as int) + (stats['pitches_thrown'] as int? ?? stats['pitchesThrownCount'] as int? ?? 0);
                aggregated['complete_games'] = (aggregated['complete_games'] as int) + (stats['complete_games'] as int? ?? stats['completeGameCount'] as int? ?? 0);
                aggregated['shutouts'] = (aggregated['shutouts'] as int) + (stats['shutouts'] as int? ?? stats['shutoutCount'] as int? ?? 0);
                aggregated['saves'] = (aggregated['saves'] as int) + (stats['saves'] as int? ?? stats['saveCount'] as int? ?? 0);
                
                // Add fielding stats
                aggregated['assists'] = (aggregated['assists'] as int) + (stats['assists'] as int? ?? stats['assistCount'] as int? ?? 0);
                aggregated['errors'] = (aggregated['errors'] as int) + (stats['errors'] as int? ?? stats['errorCount'] as int? ?? 0);
                aggregated['putouts'] = (aggregated['putouts'] as int) + (stats['putouts'] as int? ?? stats['putoutCount'] as int? ?? 0);
                aggregated['double_plays'] = (aggregated['double_plays'] as int) + (stats['double_plays'] as int? ?? stats['doublePlayCount'] as int? ?? 0);
              }
      }

      print('📊 [AGG] Aggregated totals: hits=${aggregated['hits']}, at_bats=${aggregated['at_bats']}, home_runs=${aggregated['home_runs']}');

      // Save aggregated stats
      await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('aggregated_stats')
          .doc(seasonId)
          .set(aggregated, SetOptions(merge: true));

      print('✅ [AGG] Aggregated stats saved successfully for season: $seasonId');
    } catch (e) {
      print('❌ [AGG] Error updating aggregated stats: $e');
      print('❌ [AGG] Stack: ${StackTrace.current}');
    }
  }

  Future<void> _pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    try {
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera 
              ? '📸 Opening camera...' 
              : '📸 Opening photo picker...'),
          duration: const Duration(seconds: 1),
        ),
      );
      
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Analyzing handwritten stats...'),
            duration: Duration(seconds: 2),
          ),
        );

        final imageFile = File(pickedFile.path);
        final imageBytes = await imageFile.readAsBytes();
        
        try {
          print('📸 Analyzing image with Gemini...');
          
          // Use Gemini to extract handwritten stats
          final extractedStats = await _aiService.analyzeHandwrittenStats(imageBytes);
          
          print('📸 Extracted stats: $extractedStats');
          
          // Add user message about the image
          final userMessage = ChatMessage(
            id: DateTime.now().toString(),
            role: 'user',
            content: '📸 [Uploaded handwritten stats: $extractedStats]',
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(userMessage);
            _isLoading = false;
          });
          _scrollToBottom(force: true);

          // Send the extracted stats to AI for processing
          await _sendMessage('I just uploaded a photo with these stats: $extractedStats. Can you log these for me?');

          // Upload to Firebase Storage for backup
          if (_currentUser != null) {
            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('users/${_currentUser.uid}/images/${DateTime.now().toString()}.jpg');
              
              await storageRef.putFile(imageFile);
              print('📸 Image uploaded to Firebase Storage');
            } catch (storageError) {
              print('📸 Error uploading to storage: $storageError');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Stats extracted and sent to Zuno.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } catch (e) {
          print('📸 Error analyzing image: $e');
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError(e, "Couldn't read that photo")),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 No image selected'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('📸 Error picking image: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, "Couldn't open that photo")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Legacy history/about UI removed; sidebar is used for past chats.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarBg = isDark ? context.bg : context.accent;
    final appBarFg = isDark ? Colors.white : context.onAccent;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        // Use global hamburger menu from main shell; avoid duplicate here.
        // The blue "fresh" hamburger icon comes from the shared navigation shell.
        leading: const SizedBox.shrink(),
        centerTitle: true,
        title: Text('Zuno', style: appTitleStyle(color: appBarFg)),
        actions: [
          // Conversation dropdown
          if (_chatSessions.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.history, color: appBarFg),
              tooltip: 'Switch conversation',
              onSelected: (conversationId) {
                if (conversationId == 'new') {
                  _newChat();
                } else {
                  _switchConversation(conversationId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text('New Chat'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ..._chatSessions.map((session) {
                  final preview = session.messages.isNotEmpty
                      ? session.messages.first.content
                      : 'Empty chat';
                  final dateStr = _formatDate(session.updatedAt);
                  return PopupMenuItem(
                    value: session.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: session.id == _currentSessionId
                                ? theme.primaryColor
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview.length > 50
                              ? '${preview.substring(0, 50)}...'
                              : preview,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          IconButton(
            tooltip: 'New chat',
            icon: Icon(Icons.create_outlined, color: appBarFg),
            onPressed: _newChat,
          ),
          IconButton(
            tooltip: 'Chats',
            icon: Icon(Icons.more_horiz, color: appBarFg),
              onPressed: () {
              setState(() => _showHistorySidebar = true);
              },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main chat area
          Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (_scrollController.hasClients) {
                      final extentAfter = _scrollController.position.extentAfter;
                      _autoScrollEnabled = extentAfter < 140;
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      12,
                      16,
                      12,
                      MediaQuery.of(context).viewInsets.bottom + 170,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return _buildZunoTypingRow();
                      }
                      final message = _messages[index];

                      return ChatMessageBubble(
                        content: message.content,
                        isUser: message.role == 'user',
                        onCopy: () => _copyText(message.content),
                        onRegenerate: () => _regenerateFrom(index),
                        showActions: message.role == 'assistant',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Input Area - Modern ChatGPT-style design
          // Positioned at the bottom above navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildZunoInputArea(),
          ),

          // Chat History Sidebar - Enhanced with animation
          if (_showHistorySidebar)
            GestureDetector(
              onTap: () {
                setState(() => _showHistorySidebar = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          
          if (_showHistorySidebar)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 300,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _showHistorySidebar
                    ? Offset.zero
                    : const Offset(-1, 0),
                child: Container(
                    decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                      boxShadow: [
                        BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(4, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                      // Sidebar Header
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: theme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                        ),
                child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                              'Chat History',
                      style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(
                                    () =>
                                        _showHistorySidebar =
                                            false);
                              },
                              iconSize: 20,
                    ),
                  ],
                ),
              ),
                      // Sidebar Content - ChatGPT Style
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            // Collected Stats Section
                            if (_collectedStats.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
      child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                      'Session Stats',
                  style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._collectedStats.entries.map((e) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                Text(
                                              _formatStatName(e.key),
                  style: GoogleFonts.poppins(
                                                fontSize: 11,
                  ),
                ),
                Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                  decoration: BoxDecoration(
                                                color: theme.primaryColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${e.value}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                      ),
                    ],
                  ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            
                            // Chat History Section (sessions)
                            Text(
                              'Previous Chats',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            // Chat Sessions List (past + current)
                            if (_isLoadingConversations)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_chatSessions.isNotEmpty || _messages.isNotEmpty)
                              ...[
                                ..._chatSessions,
                            if (_messages.isNotEmpty)
                                  ChatSession(
                                    id: _currentSessionId ?? 'current',
                                    messages: List<ChatMessage>.from(_messages),
                                    updatedAt: DateTime.now(),
                                  ),
                              ].asMap().entries.map((entry) {
                                final session = entry.value;
                                final ChatMessage first = session.messages.isNotEmpty
                                    ? session.messages.first
                                    : ChatMessage(
                                        id: '',
                                        role: 'assistant',
                                        content: 'Empty chat',
                                        timestamp: DateTime.now(),
                                      );
                                final preview = first.content;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _messages
                                        ..clear()
                                        ..addAll(session.messages);
                                      _currentSessionId = session.id;
                                      _showHistorySidebar = false;
                                    });
                                    _scrollToBottom(force: true);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                        Text(
                                          'Chat ${entry.key + 1}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                  Text(
                                          preview,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                            else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                                  child: Text(
                                    'Start a conversation\nwith Zuno.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatStatName(String statKey) {
    return statKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word[0].toUpperCase() +
            word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}