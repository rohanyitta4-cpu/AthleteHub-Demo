import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/rank_accent.dart';
import '../theme/zuno_theme.dart';
import 'haptic_helper.dart';

/// Chat-style message bubble (shared layout; colors from [ZunoTheme] on [BuildContext]).
class ChatMessageBubble extends StatefulWidget {
  final String content;
  final bool isUser;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final bool showActions;

  const ChatMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.onCopy,
    this.onRegenerate,
    this.showActions = true,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ZunoActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ZunoActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.actionChip,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.1 : -0.1, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await HapticHelper.lightImpact();
    await Clipboard.setData(ClipboardData(text: widget.content));
    widget.onCopy?.call();
  }

  Future<void> _handleRegenerate() async {
    await HapticHelper.lightImpact();
    widget.onRegenerate?.call();
  }

  void _onMarkdownLink(String? href) {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    unawaited(_openMarkdownUri(uri));
  }

  Future<void> _openMarkdownUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context, double baseSize) {
    final bodyColor = context.textPrimary;
    final linkColor = RankAccent.instance.color(context.isDark) ??
        (context.isDark ? const Color(0xFF9EC8FF) : const Color(0xFF2563EB));
    final base = GoogleFonts.inter(
      fontSize: baseSize,
      height: 1.55,
      color: bodyColor,
      letterSpacing: -0.15,
    );
    return MarkdownStyleSheet(
      p: base,
      pPadding: EdgeInsets.zero,
      blockSpacing: 12,
      h1: base.copyWith(
        fontSize: baseSize + 4,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h2: base.copyWith(
        fontSize: baseSize + 3,
        fontWeight: FontWeight.w700,
        height: 1.32,
      ),
      h3: base.copyWith(
        fontSize: baseSize + 2,
        fontWeight: FontWeight.w600,
        height: 1.38,
      ),
      h1Padding: const EdgeInsets.only(top: 6, bottom: 8),
      h2Padding: const EdgeInsets.only(top: 6, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 6),
      strong: base.copyWith(fontWeight: FontWeight.w700),
      em: base.copyWith(fontStyle: FontStyle.italic),
      a: base.copyWith(
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor.withOpacity(0.35),
      ),
      code: base.copyWith(
        fontFamily: 'monospace',
        fontSize: baseSize * 0.88,
        backgroundColor: context.surface2,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF141414)
            : const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border),
      ),
      blockquote: base.copyWith(
        color: bodyColor.withOpacity(0.92),
        height: 1.6,
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: context.accent.withOpacity(0.45),
            width: 3,
          ),
        ),
      ),
      listIndent: 22,
      listBullet: base,
      listBulletPadding: const EdgeInsets.only(right: 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.border),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(left: 64, right: 16, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: context.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SelectableText(
              widget.content,
              style: TextStyle(
                color: context.onAccent,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFont = screenWidth > 600 ? 15.0 : 14.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
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
                margin: EdgeInsets.only(
                  right: 16,
                  bottom: screenWidth > 600 ? 18 : 14,
                ),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: MarkdownBody(
                        data: widget.content.isEmpty ? ' ' : widget.content,
                        selectable: true,
                        softLineBreak: true,
                        shrinkWrap: true,
                        styleSheet: _markdownStyle(context, baseFont),
                        onTapLink: (text, href, title) => _onMarkdownLink(href),
                      ),
                    ),
                    if (widget.showActions) ...[
                      Divider(color: context.border, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            _ZunoActionChip(
                              label: '⎘  Copy',
                              onTap: () => unawaited(_handleCopy()),
                            ),
                            const SizedBox(width: 8),
                            if (widget.onRegenerate != null)
                              _ZunoActionChip(
                                label: '↺  Regenerate',
                                onTap: () => unawaited(_handleRegenerate()),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUser) {
      return _buildUserBubble(context);
    }
    return _buildAssistantBubble(context);
  }
}
