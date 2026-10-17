import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/rank_accent.dart';
import 'dashboard/dash_style.dart';

/// Lets screens (e.g. Stats app bar) open the slide-out menu when the floating
/// hamburger is hidden to avoid overlapping the app bar.
class MenuOverlayController {
  VoidCallback? _open;

  void _bind(VoidCallback open) => _open = open;

  void _unbind() => _open = null;

  void openMenu() => _open?.call();
}

class AnimatedHamburgerMenu extends StatefulWidget {
  final List<MenuButton> menuButtons;
  final VoidCallback? onClose;
  final Widget? headerWidget;
  final Color? backgroundColor;
  final Color? accentColor;
  final Function(bool)? onMenuStateChanged;
  /// When false, the floating top-left control is hidden (menu still works via [menuController]).
  final bool showMenuButton;
  final MenuOverlayController? menuController;

  /// Index into [menuButtons] of the screen currently shown; highlighted.
  final int? selectedIndex;

  const AnimatedHamburgerMenu({
    super.key,
    required this.menuButtons,
    this.onClose,
    this.headerWidget,
    this.backgroundColor,
    this.accentColor,
    this.onMenuStateChanged,
    this.showMenuButton = true,
    this.menuController,
    this.selectedIndex,
  });

  @override
  State<AnimatedHamburgerMenu> createState() => _AnimatedHamburgerMenuState();
}

class _AnimatedHamburgerMenuState extends State<AnimatedHamburgerMenu>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _overlayController;
  late AnimationController _buttonAnimationController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _overlayAnimation;
  late Animation<double> _buttonStaggerAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    
    // Slide animation controller - much faster closing animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // Overlay fade animation controller - much faster for better responsiveness
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Button stagger animation controller - much faster closing
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart, // Smoother curve for slide animation
    ));

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOutSine, // Smoother fade transition
    ));

    _buttonStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.linear, // Each item eases its own slice
    ));

    _syncMenuControllerBinding();
  }

  void _syncMenuControllerBinding() {
    widget.menuController?._bind(() {
      if (!_isOpen) _openMenu();
    });
  }

  @override
  void didUpdateWidget(AnimatedHamburgerMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuController != widget.menuController) {
      oldWidget.menuController?._unbind();
      _syncMenuControllerBinding();
    }
  }

  @override
  void dispose() {
    widget.menuController?._unbind();
    _slideController.dispose();
    _overlayController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    setState(() {
      _isOpen = true;
    });
    
    _slideController.forward();
    _overlayController.forward();
    
    // Stagger button animations - reduced delay for smoother feel
    Future.delayed(const Duration(milliseconds: 100), () {
      _buttonAnimationController.forward();
    });
    
    widget.onMenuStateChanged?.call(true);
  }

  void _closeMenu() {
    _slideController.reverse();
    _overlayController.reverse();
    _buttonAnimationController.reverse();
    
    // Immediately notify that menu is closing so main content animation starts right away
    widget.onMenuStateChanged?.call(false);
    
    // Update internal state after a short delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });

    widget.onClose?.call();
  }

  void _onButtonTap(int index, VoidCallback onTap) {
    _closeMenu();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final accentColor = widget.accentColor ?? RankAccent.instance.tier?.deep ?? const Color(0xFF2563eb);

    return Stack(
      children: [
        // Hamburger menu button (hidden on Stats where it overlapped the app bar)
        if (widget.showMenuButton)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 10,
            child: _HamburgerButton(onTap: _toggleMenu, isDark: isDark),
          ),
        
        // Overlay background
        if (_isOpen)
          AnimatedBuilder(
            animation: _overlayAnimation,
            builder: (context, child) {
              // Only render overlay if animation value is significant to avoid blocking touches when closed
              if (_overlayAnimation.value < 0.01) return const SizedBox.shrink();
              return Opacity(
                opacity: _overlayAnimation.value * 0.5,
                child: Container(
                  color: Colors.black,
                  child: GestureDetector(
                    onTap: _closeMenu,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        
        // Slide-out menu
        if (_isOpen)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: (MediaQuery.of(context).size.width * 0.78).clamp(0.0, 320.0),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _MenuPanel(
                    accentColor: accentColor,
                    isDark: isDark,
                    headerWidget: widget.headerWidget,
                    menuButtons: widget.menuButtons,
                    selectedButtonIndex: widget.selectedIndex ?? -1,
                    buttonStaggerAnimation: _buttonStaggerAnimation,
                    onButtonTap: _onButtonTap,
                    onClose: _closeMenu,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Two-line menu glyph in the text color, sized and placed to line up with
/// the app bar title.
class _HamburgerButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _HamburgerButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open menu',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: CustomPaint(
              size: const Size(20, 12),
              painter: _MenuGlyphPainter(dashText(isDark)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGlyphPainter extends CustomPainter {
  final Color color;

  _MenuGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(1, 1), Offset(size.width - 1, 1), paint);
    canvas.drawLine(Offset(1, size.height - 1), Offset(size.width * 0.6, size.height - 1), paint);
  }

  @override
  bool shouldRepaint(_MenuGlyphPainter old) => old.color != color;
}

class _MenuPanel extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final Widget? headerWidget;
  final List<MenuButton> menuButtons;
  final int selectedButtonIndex;
  final Animation<double> buttonStaggerAnimation;
  final Function(int, VoidCallback) onButtonTap;
  final VoidCallback onClose;

  const _MenuPanel({
    required this.isDark,
    required this.accentColor,
    required this.headerWidget,
    required this.menuButtons,
    required this.selectedButtonIndex,
    required this.buttonStaggerAnimation,
    required this.onButtonTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111113) : Colors.white,
        border: Border(right: BorderSide(color: dashBorder(isDark))),
      ),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx < -500) onClose();
        },
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                child: Row(
                  children: [
                    if (headerWidget != null) Expanded(child: headerWidget!) else const Spacer(),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Close menu',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, size: 20, color: dashMuted(isDark)),
                    ),
                  ],
                ),
              ),
              dashDivider(isDark),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: menuButtons.length,
                  itemBuilder: (context, index) => _AnimatedMenuButton(
                    button: menuButtons[index],
                    index: index,
                    count: menuButtons.length,
                    isSelected: selectedButtonIndex == index,
                    accentColor: accentColor,
                    isDark: isDark,
                    buttonStaggerAnimation: buttonStaggerAnimation,
                    onTap: () => onButtonTap(index, menuButtons[index].onTap),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedMenuButton extends StatelessWidget {
  final MenuButton button;
  final int index;
  final int count;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final Animation<double> buttonStaggerAnimation;
  final VoidCallback onTap;

  const _AnimatedMenuButton({
    required this.button,
    required this.index,
    required this.count,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.buttonStaggerAnimation,
    required this.onTap,
  });

  static const _stagger = 0.06;

  @override
  Widget build(BuildContext context) {
    // Each item gets an equal-length slice of the animation, so the last one
    // still finishes at full opacity and position.
    final span = 1 - _stagger * (count - 1).clamp(0, count);
    final textColor = isSelected ? dashText(isDark) : dashText(isDark).withValues(alpha: 0.78);

    return AnimatedBuilder(
      animation: buttonStaggerAnimation,
      builder: (context, child) {
        final t = ((buttonStaggerAnimation.value - index * _stagger) / span).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(offset: Offset(-12 * (1 - eased), 0), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: isSelected
              ? (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(left: 2, right: 11),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Icon(
                    button.icon,
                    size: 20,
                    color: isSelected ? accentColor : dashMuted(isDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      button.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (button.badge != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        button.badge!,
                        style: dashLabel(isDark, size: 9.5).copyWith(color: accentColor),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuButton {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const MenuButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badge,
  });
}
