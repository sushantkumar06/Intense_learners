import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

class StudentScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const StudentScaffold({super.key, required this.navigationShell});

  @override
  State<StudentScaffold> createState() => _StudentScaffoldState();
}

class _StudentScaffoldState extends State<StudentScaffold> {
  DateTime? _lastBackPressTime;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handlePop() {
    final currentIndex = widget.navigationShell.currentIndex;

    // Tab 1 (Notes), Tab 2 (Assignments), Tab 4 (Contact):
    // Back always goes directly to Dashboard (Tab 0). No sub-navigation on these tabs.
    if (currentIndex == 1 || currentIndex == 2 || currentIndex == 4) {
      widget.navigationShell.goBranch(0);
      return;
    }

    // Tab 3 (Videos): may have sub-navigation (FolderDetail → VideoPlayer).
    // Pop within the video branch if possible; otherwise go to Dashboard.
    if (currentIndex == 3) {
      final router = GoRouter.of(context);
      final canPop = router.canPop();
      if (canPop) {
        router.pop();
      } else {
        widget.navigationShell.goBranch(0);
      }
      return;
    }

    // Tab 0 (Dashboard): double-back to exit app.
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Press back again to exit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 70, left: 32, right: 32),
        ),
      );
      return;
    }

    // Double-back confirmed: exit app gracefully
    SystemNavigator.pop();
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.navigationShell.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _goBranch(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 8 : 4,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0x332EE6C5) // translucent aqua highlight pill
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: isSelected
                  ? Border.all(color: const Color(0x522EE6C5), width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isSelected ? 20 : 19,
                  color: isSelected ? AppColors.indigo : AppColors.inkMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: -0.2,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.indigo : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: isKeyboardOpen
            ? const SizedBox.shrink()
            : SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: RepaintBoundary(
                    child: Container(
                      height: 66,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: kGlassCardShadow,
                        gradient: kGlassRimGradient,
                      ),
                      padding: const EdgeInsets.all(1.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(49),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: kGlassBlurSigma,
                            sigmaY: kGlassBlurSigma,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: kGlassCardFillGradient,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNavItem(0, LucideIcons.home, 'Dashboard'),
                                _buildNavItem(1, LucideIcons.bookOpen, 'Notes'),
                                _buildNavItem(2, LucideIcons.fileText, 'Assignments'),
                                _buildNavItem(3, LucideIcons.play, 'Videos'),
                                _buildNavItem(4, LucideIcons.mail, 'Contact'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

