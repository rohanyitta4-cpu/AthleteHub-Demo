import 'package:flutter/material.dart';
import 'dart:ui';
import 'coach_dashboard.dart';
import 'team_season_screen.dart';
import 'coach_live_game_screen.dart';
import 'coach_stats_screen.dart';
import 'coach_settings_screen.dart';

class CoachNavigationScreen extends StatefulWidget {
  const CoachNavigationScreen({super.key});

  @override
  State<CoachNavigationScreen> createState() => _CoachNavigationScreenState();
}

class _CoachNavigationScreenState extends State<CoachNavigationScreen> {
  int _currentIndex = 0;
  bool _navExpanded = false;

  final List<Widget> _pages = [
    const CoachDashboard(),
    const TeamSeasonScreen(),
    const CoachLiveGameScreen(),
    const CoachStatsScreen(),
    const CoachSettingsScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth != 0) return false;
          if (notification.metrics.axis != Axis.vertical) return false;
          if (notification is ScrollStartNotification || notification is ScrollUpdateNotification) {
            if (!_navExpanded) setState(() => _navExpanded = true);
          } else if (notification is ScrollEndNotification) {
            if (_navExpanded) setState(() => _navExpanded = false);
          }
          return false;
        },
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: _SlidingPillNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        items: const [
          Icons.dashboard,
          Icons.group,
          Icons.sports_baseball,
          Icons.analytics,
          Icons.settings,
        ],
        isExpanded: _navExpanded,
      ),
    );
  }
}

class _SlidingPillNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<IconData> items;
  final bool isExpanded;

  const _SlidingPillNavigationBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    required this.isExpanded,
  });

  @override
  State<_SlidingPillNavigationBar> createState() => _SlidingPillNavigationBarState();
}

class _SlidingPillNavigationBarState extends State<_SlidingPillNavigationBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(covariant _SlidingPillNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double barHeight = widget.isExpanded ? 74 : 56;
            const double horizontalPadding = 12;
            final double slotWidth = (constraints.maxWidth - horizontalPadding * 2) / widget.items.length;
            final double indicatorWidth = slotWidth * 0.6;
            final double indicatorHeight = widget.isExpanded ? 46 : 32;
            double xForIndex(int index) => horizontalPadding + slotWidth * index + (slotWidth - indicatorWidth) / 2;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutQuad,
              height: barHeight,
              child: Stack(children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutQuad,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                      border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                  ),
                ),

                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final double t = _animation.value;
                    final double left = lerpDouble(xForIndex(_previousIndex), xForIndex(widget.selectedIndex), t)!;
                    return Positioned(
                      left: left,
                      top: (barHeight - indicatorHeight) / 2,
                      width: indicatorWidth,
                      height: indicatorHeight,
                      child: Opacity(
                        opacity: (1.0 - t) * 0.35,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563eb).withOpacity(0.35),
                              borderRadius: BorderRadius.circular(indicatorHeight / 2),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final double t = _animation.value;
                    final double left = lerpDouble(xForIndex(_previousIndex), xForIndex(widget.selectedIndex), t)!;
                    return Positioned(
                      left: left,
                      top: (barHeight - indicatorHeight) / 2,
                      width: indicatorWidth,
                      height: indicatorHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563eb),
                          borderRadius: BorderRadius.circular(indicatorHeight / 2),
                        ),
                      ),
                    );
                  },
                ),

                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < widget.items.length; i++)
                          _NavItem(
                            icon: widget.items[i],
                            isSelected: i == widget.selectedIndex,
                            onTap: () => widget.onItemSelected(i),
                            scale: widget.isExpanded ? 1.08 : 0.95,
                          ),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color unselectedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(1000),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Center(
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: Icon(icon, size: 28, color: isSelected ? Colors.white : unselectedColor),
            ),
          ),
        ),
      ),
    );
  }
}
