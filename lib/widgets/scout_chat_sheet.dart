import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/hitting_profile.dart';
import '../services/performance_analysis/analysis_context_builder.dart';
import '../services/performance_analysis/performance_analysis_service.dart';
import '../services/performance_analysis/performance_report_model.dart';
import '../theme/app_styles.dart';
import '../theme/zuno_colors.dart';
import 'hitting_profile_picker.dart';

/// Emerald green accent - app's primary brand color
const Color _scoutAccent = Color(0xFF10B981);
const Color _scoutWarning = Color(0xFFF59E0B);
const Color _scoutNegative = Color(0xFFEF4444);

/// Scout - AthleteHub's Performance Analysis Engine.
///
/// Shows the AI-scored scouting report and a chat that starts fresh on every
/// open; earlier chats are kept and browsable by date.
class ScoutChatSheet extends StatefulWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const ScoutChatSheet({
    super.key,
    required this.statName,
    required this.gameData,
  });

  static void show(
    BuildContext context, {
    required String statName,
    required List<Map<String, dynamic>> gameData,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ScoutChatSheet(statName: statName, gameData: gameData),
    );
  }

  @override
  State<ScoutChatSheet> createState() => _ScoutChatSheetState();
}

class _ScoutChatSheetState extends State<ScoutChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PerformanceAnalysisService _analysisService =
      PerformanceAnalysisService();
  final List<_ChatMessage> _messages = [];

  bool _isLoading = false;
  PerformanceContext? _performanceContext;

  /// Null until the first message of a new chat is sent.
  String? _conversationId;

  PerformanceReport? _report;
  HittingProfile? _profile;
  bool _reportLoading = false;
  String? _reportError;
  final Set<String> _expandedCategories = {};

  bool _showHistory = false;
  bool _historyLoading = false;
  List<_ConversationSummary> _history = [];

  CollectionReference<Map<String, dynamic>>? get _conversations {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scoutConversations');
  }

  @override
  void initState() {
    super.initState();
    _performanceContext = AnalysisContextBuilder.build(widget.gameData);
    _init();
  }

  Future<void> _init() async {
    _profile = await _analysisService.getHittingProfile();
    if (mounted) await _loadReport();
  }

  Future<void> _changeProfile() async {
    final chosen = await HittingProfileSheet.show(context, _profile);
    if (chosen == null || chosen == _profile || !mounted) return;
    setState(() {
      _profile = chosen;
      _report = null;
      _expandedCategories.clear();
    });
    await _loadReport();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Report
  // ---------------------------------------------------------------------------

  Future<void> _loadReport({bool forceRefresh = false}) async {
    final ctx = _performanceContext;
    if (ctx == null || !ctx.hasEnoughData) return;

    setState(() {
      _reportLoading = true;
      _reportError = null;
    });

    try {
      final report = await _analysisService.reportForContext(
        ctx,
        profile: _profile,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _reportLoading = false;
      });
    } catch (e) {
      debugPrint('Scout report failed: $e');
      final cached = await _analysisService.cachedReport(profile: _profile);
      if (!mounted) return;
      setState(() {
        _report = cached ?? _report;
        _reportLoading = false;
        if (_report == null) {
          _reportError = "Couldn't reach the analysis service.";
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  void _startNewChat() {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.clear();
      _conversationId = null;
      _showHistory = false;
      _isLoading = false;
    });
  }

  Future<void> _openHistory() async {
    final col = _conversations;
    if (col == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _showHistory = true;
      _historyLoading = true;
    });

    try {
      final query = await col
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();
      final items = <_ConversationSummary>[];

      for (final doc in query.docs) {
        final data = doc.data();
        final updated =
            (data['updatedAt'] as Timestamp?)?.toDate() ??
            (data['createdAt'] as Timestamp?)?.toDate();
        if (updated == null) continue;

        var title = data['title'] as String?;
        var count = (data['messageCount'] as num?)?.toInt();

        // Older chats were created before titles existed; derive one from the
        // first question and store it so this only happens once.
        if (title == null) {
          final first = await doc.reference
              .collection('messages')
              .orderBy('timestamp')
              .limit(1)
              .get();
          if (first.docs.isEmpty) continue;
          title = _titleFrom(
            first.docs.first.data()['content'] as String? ?? '',
          );
          unawaited(doc.reference.update({'title': title}).catchError((_) {}));
        }
        if (count == 0) continue;

        items.add(
          _ConversationSummary(id: doc.id, title: title, updatedAt: updated),
        );
      }

      if (!mounted) return;
      setState(() {
        _history = items;
        _historyLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading Scout history: $e');
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _openConversation(_ConversationSummary convo) async {
    final col = _conversations;
    if (col == null) return;
    HapticFeedback.selectionClick();

    try {
      final query = await col
          .doc(convo.id)
          .collection('messages')
          .orderBy('timestamp')
          .limit(100)
          .get();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            query.docs.map(
              (d) => _ChatMessage(
                role: d.data()['role'] as String? ?? 'assistant',
                content: d.data()['content'] as String? ?? '',
              ),
            ),
          );
        _conversationId = convo.id;
        _showHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error opening Scout conversation: $e');
    }
  }

  Future<void> _deleteConversation(_ConversationSummary convo) async {
    final col = _conversations;
    if (col == null) return;
    setState(() => _history.removeWhere((c) => c.id == convo.id));
    if (_conversationId == convo.id) {
      _messages.clear();
      _conversationId = null;
    }

    try {
      final ref = col.doc(convo.id);
      final msgs = await ref.collection('messages').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final m in msgs.docs) {
        batch.delete(m.reference);
      }
      batch.delete(ref);
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting Scout conversation: $e');
    }
  }

  String _titleFrom(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return 'Conversation';
    return clean.length <= 60 ? clean : '${clean.substring(0, 57)}...';
  }

  Future<void> _ensureConversation(String firstMessage) async {
    if (_conversationId != null) return;
    final col = _conversations;
    if (col == null) return;
    final ref = await col.add({
      'title': _titleFrom(firstMessage),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': 0,
    });
    _conversationId = ref.id;
  }

  Future<void> _saveMessage(String role, String content) async {
    final col = _conversations;
    if (col == null || _conversationId == null) return;

    try {
      final ref = col.doc(_conversationId);
      await ref.collection('messages').add({
        'role': role,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await ref.update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error saving Scout message: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  void _askQuestion(String question) {
    _inputController.text = question;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    HapticFeedback.lightImpact();

    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      await _ensureConversation(text);
      await _saveMessage('user', text);
      final response = await _callScout(text, history);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: response));
          _isLoading = false;
        });
        await _saveMessage('assistant', response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: 'assistant',
              content:
                  "I couldn't analyze that right now. Try asking about your average, strikeouts, or trends.",
            ),
          );
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  Future<String> _callScout(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    final ctx = _performanceContext;
    if (ctx == null) {
      return "I need more game data to analyze. Log at least 3 games and I'll break down your performance.";
    }

    final report = _report;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'chatWithScout',
      );
      final result = await callable
          .call({
            'message': userMessage,
            'context': ctx.toJson(),
            'history': history,
            if (report != null)
              'report': {
                'grade': report.grade,
                'overallScore': report.overallScore,
                if (report.hittingProfile != null)
                  'profileLabel': report.profileLabel,
                'focusArea': report.focusArea,
                'overallTrend': report.overallTrend,
                'comparisonGroup': ?report.comparisonGroup,
                'drills': report.drills,
                'categories': report.categories
                    .map((c) => {'label': c.label, 'score': c.score})
                    .toList(),
              },
          })
          .timeout(const Duration(seconds: 30));

      return result.data['response'] as String? ??
          _generateLocalResponse(userMessage);
    } catch (e) {
      return _generateLocalResponse(userMessage);
    }
  }

  /// Offline answers. They read from the report so they never disagree with it.
  String _generateLocalResponse(String userMessage) {
    final ctx = _performanceContext;
    if (ctx == null) return "Log more games and I'll have data to analyze.";

    final s = ctx.season;
    final t = ctx.trend;
    final report = _report;
    final lower = userMessage.toLowerCase();
    final trendLine = switch (report?.overallTrend) {
      'declining' => 'Recent form is meaningfully below your season level.',
      'improving' => 'Recent form is meaningfully above your season level.',
      _ => 'That gap is within normal game-to-game swing.',
    };

    if (report != null &&
        (lower.contains('improve') ||
            lower.contains('weakness') ||
            lower.contains('drill'))) {
      final drills = report.drills.map((d) => '• $d').join('\n');
      return 'Priority focus: ${report.focusArea}.'
          '${(report.focusDetail ?? '').isNotEmpty ? '\n\n${report.focusDetail}' : ''}'
          '${drills.isNotEmpty ? '\n\nDrills to try:\n$drills' : ''}';
    }

    if (report != null && lower.contains('strength')) {
      if (report.strengths.isEmpty) {
        return 'No category is above typical yet. Your best area right now is '
            '${_orderedCategories(report).where((c) => c.available).map((c) => c.label).firstOrNull ?? 'still forming'}.';
      }
      return report.strengths
          .map((i) => '• ${i.title}: ${i.evidence}')
          .join('\n\n');
    }

    if (report != null && lower.contains('grade')) {
      final lines = report.categories
          .where((c) => c.available)
          .map((c) => '• ${c.label}: ${c.score} (${c.weight}% of the grade)')
          .join('\n');
      return '${report.grade} for a ${report.profileLabel}. ${report.headline}\n\n'
          'Category scores (75 = typical):\n$lines';
    }

    if (lower.contains('average') ||
        lower.contains('avg') ||
        lower.contains('last 10') ||
        lower.contains('cooling') ||
        lower.contains('lately')) {
      return "Season AVG: ${s.avg.toStringAsFixed(3)}\n"
          "Last 10 games: ${t.last10Avg.toStringAsFixed(3)}\n"
          "Last 5 games: ${t.last5Avg.toStringAsFixed(3)}\n\n"
          "$trendLine";
    }

    if (lower.contains('ops')) {
      return "OPS = OBP + SLG\n\n"
          "Your OBP: ${s.obp.toStringAsFixed(3)}\n"
          "Your SLG: ${s.slg.toStringAsFixed(3)}\n"
          "Your OPS: ${s.ops.toStringAsFixed(3)}\n\n"
          "OBP is how often you reach base; SLG is total bases per at-bat.";
    }

    return "${ctx.gamesAnalyzed} games: ${s.avg.toStringAsFixed(3)} AVG, ${s.ops.toStringAsFixed(3)} OPS. "
        "Ask about your grade, strengths, recent form, or what to work on.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  Color _text(bool isDark) =>
      isDark ? ZunoColors.darkText : ZunoColors.lightText;
  Color _muted(bool isDark) =>
      isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted;
  Color _surface(bool isDark) =>
      isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface;
  Color _border(bool isDark) =>
      isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final ctx = _performanceContext;
    final hasData = ctx != null && ctx.hasEnoughData;

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: isDark ? ZunoColors.darkBg : ZunoColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHandle(isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _showHistory
                ? _buildHistoryHeader(isDark)
                : _buildHeader(isDark, ctx?.gamesAnalyzed ?? 0),
          ),
          Expanded(
            child: _showHistory
                ? _buildHistoryList(isDark)
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      if (hasData)
                        ..._buildReportSection(isDark, ctx)
                      else ...[
                        _buildEmptyState(isDark),
                        const SizedBox(height: 20),
                      ],
                      if (_messages.isNotEmpty) _buildChatSection(isDark),
                    ],
                  ),
          ),
          if (!_showHistory) _buildInputArea(isDark, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _border(isDark),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    String? tooltip,
    String? label,
  }) {
    final box = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _surface(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: _muted(isDark)),
    );
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: label == null
          ? box
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                box,
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _muted(isDark),
                  ),
                ),
              ],
            ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _buildHeader(bool isDark, int gamesCount) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border(isDark)),
          ),
          child: Icon(
            Icons.analytics_outlined,
            color: isDark ? ZunoColors.darkAccent : ZunoColors.lightAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scout',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _text(isDark),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                gamesCount > 0
                    ? '$gamesCount games analyzed'
                    : 'Performance Analysis',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _muted(isDark),
                ),
              ),
            ],
          ),
        ),
        if (_messages.isNotEmpty) ...[
          _headerButton(
            icon: Icons.add_comment_outlined,
            onTap: _startNewChat,
            isDark: isDark,
            tooltip: 'New chat',
            label: 'New',
          ),
          const SizedBox(width: 8),
        ],
        _headerButton(
          icon: Icons.tune_rounded,
          onTap: _changeProfile,
          isDark: isDark,
          tooltip: 'Hitting profile',
          label: 'Profile',
        ),
        const SizedBox(width: 8),
        _headerButton(
          icon: Icons.history_rounded,
          onTap: _openHistory,
          isDark: isDark,
          tooltip: 'Previous chats',
          label: 'History',
        ),
        const SizedBox(width: 8),
        _headerButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).pop(),
          isDark: isDark,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Previous chats
  // ---------------------------------------------------------------------------

  Widget _buildHistoryHeader(bool isDark) {
    return Row(
      children: [
        _headerButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => setState(() => _showHistory = false),
          isDark: isDark,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Previous chats',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _text(isDark),
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: _startNewChat,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? ZunoColors.darkAccent : ZunoColors.lightAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: isDark
                      ? ZunoColors.darkOnAccent
                      : ZunoColors.lightOnAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'New chat',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ZunoColors.darkOnAccent
                        : ZunoColors.lightOnAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _dateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d, y').format(date);
  }

  Widget _buildHistoryList(bool isDark) {
    if (_historyLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _muted(isDark),
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 32, color: _muted(isDark)),
              const SizedBox(height: 12),
              Text(
                'No previous chats',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _text(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Conversations with Scout are saved here by date.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: _muted(isDark)),
              ),
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[];
    String? currentGroup;
    for (final convo in _history) {
      final group = _dateGroup(convo.updatedAt);
      if (group != currentGroup) {
        currentGroup = group;
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 18, bottom: 8),
            child: Text(
              group.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _muted(isDark),
                letterSpacing: 0.6,
              ),
            ),
          ),
        );
      }
      rows.add(_buildHistoryTile(convo, isDark));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      physics: const BouncingScrollPhysics(),
      children: rows,
    );
  }

  Widget _buildHistoryTile(_ConversationSummary convo, bool isDark) {
    final isCurrent = convo.id == _conversationId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(convo.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteConversation(convo),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: _scoutNegative.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: _scoutNegative,
            size: 20,
          ),
        ),
        child: InkWell(
          onTap: () => _openConversation(convo),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _surface(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? _scoutAccent.withValues(alpha: 0.6)
                    : _border(isDark),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: _muted(isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    convo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _text(isDark),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('h:mm a').format(convo.updatedAt),
                  style: GoogleFonts.inter(fontSize: 11, color: _muted(isDark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scouting report
  // ---------------------------------------------------------------------------

  List<Widget> _buildReportSection(bool isDark, PerformanceContext ctx) {
    final report = _report;

    if (report == null) {
      return [
        _reportError != null
            ? _buildReportError(isDark)
            : _buildReportLoading(isDark, ctx.gamesAnalyzed),
        const SizedBox(height: 24),
      ];
    }

    return [
      _buildGradeCard(isDark, report),
      const SizedBox(height: 20),
      if (report.summary.isNotEmpty) ...[
        _buildSectionLabel(
          'Season Summary',
          Icons.calendar_today_outlined,
          isDark,
        ),
        const SizedBox(height: 10),
        Text(
          report.summary,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _text(isDark),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
      if (report.keyInsight != null && report.keyInsight!.title.isNotEmpty) ...[
        _buildKeyInsight(isDark, report.keyInsight!),
        const SizedBox(height: 20),
      ],
      if (report.focusArea.isNotEmpty) ...[
        _buildFocusCard(isDark, report),
        const SizedBox(height: 20),
      ],
      if (report.strengths.isNotEmpty) ...[
        _buildInsightList('Strengths', report.strengths, _scoutAccent, isDark),
        const SizedBox(height: 20),
      ],
      if (report.concerns.isNotEmpty) ...[
        _buildInsightList(
          'Room to grow',
          report.concerns,
          _scoutWarning,
          isDark,
        ),
        const SizedBox(height: 20),
      ],
      const SizedBox(height: 4),
    ];
  }

  Widget _buildSectionLabel(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _muted(isDark)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _muted(isDark),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildReportLoading(bool isDark, int games) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border(isDark)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _scoutAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyzing $games games',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _text(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _profile == null
                      ? 'Scoring contact, power, discipline and trends'
                      : 'Weighting your report as a ${_profile!.label}',
                  style: GoogleFonts.inter(fontSize: 12, color: _muted(isDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportError(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border(isDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 20, color: _muted(isDark)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _reportError ?? 'Analysis unavailable',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _text(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadReport(forceRefresh: true),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _scoutAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String grade, bool isDark) {
    if (grade.startsWith('A')) return _scoutAccent;
    if (grade.startsWith('B')) return _text(isDark);
    if (grade.startsWith('C')) return _scoutWarning;
    if (grade.startsWith('-')) return _muted(isDark);
    return _scoutNegative;
  }

  Color _scoreColor(int score, bool isDark) {
    if (score >= 78) return _scoutAccent;
    if (score >= 72) return isDark ? Colors.white70 : Colors.black54;
    return _scoutWarning;
  }

  (String, IconData, Color) _trendDisplay(String trend, bool isDark) {
    switch (trend) {
      case 'improving':
        return ('Rising', Icons.trending_up_rounded, _scoutAccent);
      case 'declining':
        return ('Cooling', Icons.trending_down_rounded, _scoutNegative);
      default:
        return ('Steady', Icons.trending_flat_rounded, _muted(isDark));
    }
  }

  Widget _buildGradeCard(bool isDark, PerformanceReport report) {
    final (trendLabel, trendIcon, trendColor) = _trendDisplay(
      report.overallTrend,
      isDark,
    );
    final confidence = switch (report.confidence) {
      'high' => 'High confidence',
      'medium' => 'Medium confidence',
      _ => 'Small sample',
    };

    return GradientBorderCard(
      radius: 14,
      fill: _surface(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!report.usesCurrentStandards) ...[
            _buildStandardsUpdatedBanner(isDark, report),
            const SizedBox(height: 14),
          ],
          _buildProfileRow(isDark, report),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.grade,
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: _gradeColor(report.grade, isDark),
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (report.overallScore != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${report.overallScore}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _text(isDark),
                            ),
                          ),
                          TextSpan(
                            text: ' / 100',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _muted(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(trendIcon, size: 18, color: trendColor),
                        const SizedBox(width: 6),
                        Text(
                          trendLabel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.headline,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _text(isDark),
                        height: 1.35,
                      ),
                    ),
                    if (report.previousGrade != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recalculated with updated standards (v${report.scoringVersion}). '
                        'Under v${report.previousScoringVersion} this was ${report.previousGrade}.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _muted(isDark),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (report.categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._orderedCategories(
              report,
            ).map((c) => _buildCategoryRow(c, isDark, report)),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Tick mark = 75, a typical ${(report.comparisonGroup ?? 'high school varsity and travel ball hitters').toLowerCase().replaceFirst(RegExp(r's$'), '')}.'
                '${report.comparisonNote != null ? ' ${report.comparisonNote}' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _muted(isDark),
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Divider(height: 1, color: _border(isDark)),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showStandardsInfo(isDark, report),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.isProvisional
                          ? 'Provisional standards'
                          : 'Standards v${report.scoringVersion}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _muted(isDark),
                        decoration: TextDecoration.underline,
                        decorationColor: _muted(isDark),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: _muted(isDark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  ' · $confidence · ${report.gamesAnalyzed} games',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _muted(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _reportLoading
                    ? null
                    : () => _loadReport(forceRefresh: true),
                child: _reportLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _muted(isDark),
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: _muted(isDark),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardsUpdatedBanner(bool isDark, PerformanceReport report) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _scoutAccent.withValues(alpha: 0.5)),
        color: _scoutAccent.withValues(alpha: isDark ? 0.08 : 0.06),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Scout\'s standards were updated. This grade used the '
              'v${report.scoringVersion} standards.',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.35,
                color: _text(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: _reportLoading
                ? null
                : () => _loadReport(forceRefresh: true),
            style: TextButton.styleFrom(
              foregroundColor: _scoutAccent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              'See updated grade',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStandardsInfo(bool isDark, PerformanceReport report) {
    final rows = <String>[
      'Scoring version ${report.scoringVersion}',
      if (report.benchmarkSet != null) 'Benchmarks: ${report.benchmarkSet}',
      if (report.profileWeightsVersion != null)
        'Profile weights: v${report.profileWeightsVersion}',
    ];
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: _surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.isProvisional
                    ? 'Provisional standards'
                    : 'Scout standards',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _text(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                report.isProvisional
                    ? 'Scout grades your stats against benchmarks for a typical high school '
                          'varsity or travel ball hitter. We set those benchmarks by hand and '
                          'haven\'t checked them against a large group of real players yet, so '
                          'a grade is not a national percentile. An A means well above our '
                          'benchmarks, not top 10% of all players.\n\n'
                          'When we update the standards, your existing report stays as it was '
                          'and you can choose to see the updated grade.'
                    : 'These standards have been checked against real player data.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: _text(isDark),
                ),
              ),
              const SizedBox(height: 14),
              ...rows.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    r,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _muted(isDark),
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

  /// Heaviest-weighted categories for the active profile first; momentum and
  /// categories without data last.
  List<CategoryScore> _orderedCategories(PerformanceReport report) {
    int rank(CategoryScore c) =>
        !c.available ? 2 : (c.key == 'momentum' ? 1 : 0);
    return [...report.categories]..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : b.weight.compareTo(a.weight);
    });
  }

  String _weightNote(CategoryScore category, PerformanceReport report) {
    if (!category.available) return 'Not counted until there is enough data';
    if (category.key == 'momentum') {
      final adj = report.momentumAdjustment;
      if (adj.abs() < 0.05) {
        return 'Recent form matches your season; no change to the grade';
      }
      return 'Recent form moves your grade ${adj > 0 ? '+' : ''}${adj.toStringAsFixed(1)}';
    }
    return '${category.weight}% of your ${report.profileLabel} grade';
  }

  Widget _buildProfileRow(bool isDark, PerformanceReport report) {
    final hasProfile = report.hittingProfile != null;
    return Row(
      children: [
        Expanded(
          child: Text(
            hasProfile
                ? '${report.profileLabel.toUpperCase()} GRADE'
                : 'OVERALL OFFENSE GRADE',
            style: sectionLabelStyle(isDark),
          ),
        ),
        GestureDetector(
          onTap: _changeProfile,
          child: Text(
            hasProfile ? 'Change profile' : 'Set hitting profile',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _scoutAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    CategoryScore category,
    bool isDark,
    PerformanceReport report,
  ) {
    final expanded = _expandedCategories.contains(category.key);
    final color = _scoreColor(category.score, isDark);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: category.rationale.isEmpty
          ? null
          : () => setState(() {
              expanded
                  ? _expandedCategories.remove(category.key)
                  : _expandedCategories.add(category.key);
            }),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _muted(isDark),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: category.available
                              ? (category.score / 100).clamp(0.0, 1.0)
                              : 0,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? ZunoColors.darkSurface2
                              : ZunoColors.lightSurface2,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      Positioned.fill(
                        top: -2,
                        bottom: -2,
                        child: Align(
                          alignment: const Alignment(0.5, 0), // 75 of 100
                          child: Container(
                            width: 1.5,
                            color: _text(isDark).withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 24,
                  child: Text(
                    category.available ? '${category.score}' : '—',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _text(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: _muted(isDark),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6, right: 20),
                      child: Text(
                        '${category.rationale}\n${_weightNote(category, report)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _muted(isDark),
                          height: 1.4,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyInsight(bool isDark, KeyInsight insight) {
    final (icon, iconColor) = switch (insight.tone) {
      'positive' => (Icons.show_chart_rounded, _scoutAccent),
      'warning' => (Icons.warning_amber_rounded, _scoutWarning),
      _ => (Icons.insights_outlined, _muted(isDark)),
    };

    return GestureDetector(
      onTap: () =>
          _askQuestion('Tell me more about ${insight.title.toLowerCase()}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  'Key Insight',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _muted(isDark),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              insight.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _text(isDark),
              ),
            ),
            if (insight.stats.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final stat in insight.stats.take(3)) ...[
                    _buildMiniStat(stat.key, stat.value, isDark),
                    const SizedBox(width: 24),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              insight.detail,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _muted(isDark),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ask Scout',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _scoutAccent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: _scoutAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard(bool isDark, PerformanceReport report) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _surface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border(isDark)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(width: 3, child: ColoredBox(color: _scoutAccent)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFocusContent(isDark, report),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusContent(bool isDark, PerformanceReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIORITY FOCUS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted(isDark),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          report.focusArea,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _text(isDark),
            height: 1.35,
          ),
        ),
        if ((report.focusDetail ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            report.focusDetail!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _muted(isDark),
              height: 1.45,
            ),
          ),
        ],
        if (report.drills.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'DRILLS TO TRY',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _muted(isDark),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          for (final (i, drill) in report.drills.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _scoutAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _scoutAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      drill,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _text(isDark),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInsightList(
    String label,
    List<ReportInsight> items,
    Color dot,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted(isDark),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _text(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.evidence,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _muted(isDark),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _muted(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _text(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: _surface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        children: [
          Icon(Icons.query_stats_rounded, size: 36, color: _muted(isDark)),
          const SizedBox(height: 14),
          Text(
            'Need more data',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _text(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log at least 5 games to unlock your scouting report.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _muted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Questions that fit this report, so a chip never assumes a slump or a
  /// weakness the scores don't show.
  List<String> get _suggestedQuestions {
    final report = _report;
    return [
      if (report != null && report.focusArea.isNotEmpty)
        'How do I improve ${report.focusArea.toLowerCase()}?',
      switch (report?.overallTrend) {
        'declining' => 'Why am I cooling off?',
        'improving' => 'What\'s working lately?',
        _ => 'Last 10 games vs my season',
      },
      'What are my strengths?',
      'Explain my grade',
      'Explain OPS',
    ];
  }

  Widget _buildQuestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () => _askQuestion(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? ZunoColors.darkText : ZunoColors.lightText,
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder,
        ),
        const SizedBox(height: 16),
        ..._messages.map((msg) => _buildMessageBubble(msg, isDark)),
        if (_isLoading) _buildAnalyzingIndicator(isDark),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isDark) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? (isDark ? ZunoColors.darkAccent : ZunoColors.lightAccent)
              : (isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface),
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: !isUser
              ? Border.all(
                  color: isDark
                      ? ZunoColors.darkBorder
                      : ZunoColors.lightBorder,
                )
              : null,
        ),
        child: isUser
            ? Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? ZunoColors.darkOnAccent
                      : ZunoColors.lightOnAccent,
                ),
              )
            : MarkdownBody(
                data: message.content,
                selectable: true,
                softLineBreak: true,
                shrinkWrap: true,
                styleSheet: _getMarkdownStyle(isDark),
              ),
      ),
    );
  }

  MarkdownStyleSheet _getMarkdownStyle(bool isDark) {
    final textColor = isDark ? ZunoColors.darkText : ZunoColors.lightText;
    final mutedColor = isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted;

    final baseStyle = GoogleFonts.inter(
      fontSize: 14,
      height: 1.55,
      color: textColor,
      fontWeight: FontWeight.w400,
    );

    return MarkdownStyleSheet(
      p: baseStyle,
      pPadding: EdgeInsets.zero,
      blockSpacing: 10,
      strong: baseStyle.copyWith(fontWeight: FontWeight.w600),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      h1: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h2: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      h3: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      listBullet: baseStyle.copyWith(color: mutedColor),
      listIndent: 16,
      listBulletPadding: const EdgeInsets.only(right: 6),
      a: baseStyle.copyWith(
        color: _scoutAccent,
        decoration: TextDecoration.underline,
      ),
      blockquote: baseStyle.copyWith(
        color: mutedColor,
        fontStyle: FontStyle.italic,
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: mutedColor.withValues(alpha: 0.4), width: 3),
        ),
      ),
      code: GoogleFonts.robotoMono(
        fontSize: 13,
        color: textColor,
        backgroundColor: isDark
            ? ZunoColors.darkSurface2
            : ZunoColors.lightSurface2,
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: isDark ? ZunoColors.darkSurface2 : ZunoColors.lightSurface2,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildAnalyzingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface,
          borderRadius: BorderRadius.circular(
            14,
          ).copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(
            color: isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Analyzing',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? ZunoColors.darkBg : ZunoColors.lightBg,
        border: Border(
          top: BorderSide(
            color: isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ZunoColors.darkSurface
                          : ZunoColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? ZunoColors.darkBorder
                            : ZunoColors.lightBorder,
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ZunoColors.darkText
                            : ZunoColors.lightText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask about your stats...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? ZunoColors.darkMuted
                              : ZunoColors.lightMuted,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? ZunoColors.darkAccent
                          : ZunoColors.lightAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: isDark
                          ? ZunoColors.darkOnAccent
                          : ZunoColors.lightOnAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedQuestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) =>
                    _buildQuestionChip(_suggestedQuestions[i], isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;

  const _ChatMessage({required this.role, required this.content});
}

class _ConversationSummary {
  final String id;
  final String title;
  final DateTime updatedAt;

  const _ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
  });
}
