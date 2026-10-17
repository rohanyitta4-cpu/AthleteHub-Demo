import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_styles.dart';
import '../theme/app_title_style.dart';
import '../widgets/dashboard/dash_style.dart';
import 'dart:async';

import '../services/performance_analysis/performance_analysis_service.dart';
import '../services/performance_analysis/performance_report_model.dart';
import '../utils/friendly_error.dart';

/// Scout season report (scorebook-style layout).
class PerformanceReportScreen extends StatefulWidget {
  const PerformanceReportScreen({super.key});

  @override
  State<PerformanceReportScreen> createState() => _PerformanceReportScreenState();
}

class _PerformanceReportScreenState extends State<PerformanceReportScreen> {
  final PerformanceAnalysisService _service = PerformanceAnalysisService();

  PerformanceReport? _report;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  Duration? _timeUntilRefresh;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateTimeUntilRefresh();
    });
  }

  Future<void> _updateTimeUntilRefresh() async {
    final time = await _service.timeUntilNextReport();
    if (mounted) {
      setState(() {
        _timeUntilRefresh = time;
      });
    }
  }

  Future<void> _loadReport() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final report = await _service.getReport();
      await _updateTimeUntilRefresh();

      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = friendlyError(e, "Couldn't load your report");
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshReport() async {
    final canRefresh = await _service.canGenerateNewReport();
    if (!canRefresh) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report can be refreshed in ${_formatDuration(_timeUntilRefresh)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isRefreshing = true;
      });

      HapticFeedback.mediumImpact();
      final report = await _service.generateReport();
      await _updateTimeUntilRefresh();

      if (mounted) {
        setState(() {
          _report = report;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report updated', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh report', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inMinutes <= 0) {
      return 'now';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B0D) : const Color(0xFFF7F7F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: dashText(isDark), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Scouting Report', style: appTitleStyle(color: dashText(isDark))),
        centerTitle: true,
        actions: [
          if (_report != null && _report!.gamesAnalyzed > 0)
            IconButton(
              tooltip: 'Refresh report',
              icon: _isRefreshing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: dashMuted(isDark)),
                    )
                  : Icon(Icons.refresh_rounded, color: dashMuted(isDark)),
              onPressed: _isRefreshing ? null : _refreshReport,
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: dashText(isDark))),
            const SizedBox(height: 14),
            Text('Loading report', style: GoogleFonts.inter(fontSize: 13, color: dashMuted(isDark))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: dashText(isDark)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadReport, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (_report == null || _report!.gamesAnalyzed < 5) return _buildInsufficientDataView(isDark);

    final r = _report!;
    final available = r.categories.where((c) => c.available).toList();
    var section = 0;
    String next() => (++section).toString().padLeft(2, '0');

    return RefreshIndicator(
      onRefresh: _refreshReport,
      color: dashText(isDark),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _header(r, isDark),
          if (available.isNotEmpty) ...[
            _sectionHeader(next(), 'Tool grades', isDark, trailing: '0–100 · 75 = typical'),
            for (final c in available) _toolRow(c, isDark),
          ],
          _sectionHeader(next(), 'Recent trend', isDark),
          _trend(r, isDark),
          if (r.strengths.isNotEmpty) ...[
            _sectionHeader(next(), 'Strengths', isDark),
            for (var i = 0; i < r.strengths.length; i++) _insight(i + 1, r.strengths[i], true, isDark),
          ],
          if (r.concerns.isNotEmpty) ...[
            _sectionHeader(next(), 'Concerns', isDark),
            for (var i = 0; i < r.concerns.length; i++) _insight(i + 1, r.concerns[i], false, isDark),
          ],
          _sectionHeader(next(), 'Development plan', isDark),
          _plan(r, isDark),
          const SizedBox(height: 28),
          _footer(r, isDark),
        ],
      ),
    );
  }

  Widget _header(PerformanceReport r, bool isDark) {
    final text = dashText(isDark);
    final muted = dashMuted(isDark);
    final accent = statAccent(isDark);
    final score = r.overallScore;
    final date = DateFormat('MMM d, yyyy').format(r.generatedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [r.profileLabel, if (r.comparisonGroup != null) r.comparisonGroup!].join(' · ').toUpperCase(),
          style: dashLabel(isDark, size: 10.5),
        ),
        const SizedBox(height: 4),
        Text('$date · ${r.gamesAnalyzed} games', style: dashMono(size: 11.5, color: muted)),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              score?.toString() ?? '—',
              style: dashMono(size: 64, weight: FontWeight.w800, color: text, height: 0.95),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(
                '/100',
                style: dashMono(size: 15, weight: FontWeight.w600, color: muted),
              ),
            ),
            const Spacer(),
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: text, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                r.grade,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: text, height: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (score != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: dashBorder(isDark))),
                  FractionallySizedBox(
                    widthFactor: (score / 100).clamp(0.0, 1.0),
                    child: ColoredBox(color: accent),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          r.headline,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: text,
            letterSpacing: -0.2,
          ),
        ),
        if (r.summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(r.summary, style: GoogleFonts.inter(fontSize: 14, height: 1.55, color: muted)),
        ],
        if (r.comparisonNote != null && r.comparisonNote!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            r.comparisonNote!,
            style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: muted, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String number, String title, bool isDark, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: dashText(isDark).withValues(alpha: isDark ? 0.18 : 0.25)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                number,
                style: dashMono(size: 11, weight: FontWeight.w700, color: statAccent(isDark)),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: dashText(isDark),
                ),
              ),
              const Spacer(),
              if (trailing != null) Text(trailing, style: dashMono(size: 10.5, color: dashMuted(isDark))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolRow(CategoryScore c, bool isDark) {
    final color = dashScoreColor(c.score, isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.label,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: dashText(isDark)),
                ),
              ),
              Text('${c.weight}%', style: dashMono(size: 10.5, color: dashMuted(isDark))),
              const SizedBox(width: 12),
              SizedBox(
                width: 32,
                child: Text(
                  '${c.score}',
                  textAlign: TextAlign.right,
                  style: dashMono(size: 15, weight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 6,
            child: CustomPaint(
              size: const Size(double.infinity, 6),
              painter: _GradeBarPainter(
                value: c.score / 100,
                color: color,
                track: dashBorder(isDark),
                tick: dashText(isDark).withValues(alpha: 0.6),
              ),
            ),
          ),
          if (c.rationale.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(c.rationale, style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: dashMuted(isDark))),
          ],
        ],
      ),
    );
  }

  Widget _trend(PerformanceReport r, bool isDark) {
    final (label, color, arrow) = switch (r.overallTrend) {
      'improving' => ('Improving', dashPositive, '▲'),
      'declining' => ('Declining', dashWarning, '▼'),
      _ => ('Steady', dashText(isDark), '—'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(arrow, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
            const Spacer(),
            Text('Confidence: ${r.confidence}', style: dashMono(size: 11, color: dashMuted(isDark))),
          ],
        ),
        if (r.trendSummary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.trendSummary, style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: dashMuted(isDark))),
        ],
      ],
    );
  }

  Widget _insight(int n, ReportInsight insight, bool strength, bool isDark) {
    final mark = strength ? dashPositive : dashWarning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 2, height: 36, color: mark, margin: const EdgeInsets.only(top: 2, right: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: dashText(isDark),
                  ),
                ),
                if (insight.evidence.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(insight.evidence, style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: dashMuted(isDark))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _plan(PerformanceReport r, bool isDark) {
    final text = dashText(isDark);
    final muted = dashMuted(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Focus', style: dashLabel(isDark, size: 10)),
        const SizedBox(height: 4),
        Text(
          r.focusArea,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: text),
        ),
        if (r.focusDetail != null && r.focusDetail!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.focusDetail!, style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: muted)),
        ],
        if (r.drills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Drills', style: dashLabel(isDark, size: 10)),
          const SizedBox(height: 6),
          for (var i = 0; i < r.drills.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}.',
                      style: dashMono(size: 12.5, weight: FontWeight.w700, color: statAccent(isDark)),
                    ),
                  ),
                  Expanded(
                    child: Text(r.drills[i], style: GoogleFonts.inter(fontSize: 13.5, height: 1.45, color: text)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _footer(PerformanceReport r, bool isDark) {
    final muted = dashMuted(isDark);
    final rows = [
      ('Generated', _formatRelativeTime(r.generatedAt)),
      ('Next refresh', _formatDuration(_timeUntilRefresh)),
      ('Games', '${r.gamesAnalyzed}'),
      ('Standards', r.isProvisional ? 'Provisional HS' : 'Validated'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: dashBorder(isDark)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            for (final (k, v) in rows)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$k  ', style: dashLabel(isDark, size: 9.5)),
                    TextSpan(
                      text: v,
                      style: dashMono(size: 11, weight: FontWeight.w600, color: dashText(isDark)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Generated by Scout from your logged games. Grades compare you with typical high school hitters and are meant for '
          'development, not recruiting evaluation.',
          style: GoogleFonts.inter(fontSize: 11, height: 1.45, color: muted),
        ),
      ],
    );
  }

  Widget _buildInsufficientDataView(bool isDark) {
    final logged = _report?.gamesAnalyzed ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Not enough games yet',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: dashText(isDark)),
            ),
            const SizedBox(height: 10),
            Text(
              'Scout writes a report once you have logged 5 games.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: dashMuted(isDark)),
            ),
            const SizedBox(height: 20),
            Text(
              '$logged / 5 games',
              style: dashMono(size: 14, weight: FontWeight.w700, color: dashText(isDark)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                value: (logged / 5).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: dashBorder(isDark),
                color: statAccent(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// 0–100 grade bar; tick at 75 = typical.
class _GradeBarPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final Color tick;

  _GradeBarPainter({required this.value, required this.color, required this.track, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = track);
    final w = size.width * value.clamp(0.0, 1.0);
    if (w > 0) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, size.height), r), Paint()..color = color);
    }
    final x = size.width * 0.75;
    canvas.drawLine(
      Offset(x, -2),
      Offset(x, size.height + 2),
      Paint()
        ..color = tick
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_GradeBarPainter old) =>
      old.value != value || old.color != color || old.track != track || old.tick != tick;
}
