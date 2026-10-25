import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Top SafeHer logo mark with shield & leaf vector motif (Screen 1 & 5)
class SafeHerLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? iconColor;

  const SafeHerLogo({
    super.key,
    this.size = 64,
    this.showText = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SafeHerColors.brightPink, SafeHerColors.primaryRose],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SafeHerColors.primaryRose.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.shield_rounded,
              size: size * 0.6,
              color: iconColor ?? Colors.white,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.eco_rounded,
                color: SafeHerColors.primaryRose,
                size: 24,
              ),
              SizedBox(width: 6),
              Text(
                'SafeHer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Standard full-width pink gradient action button
typedef SafeHerButton = SafeHerPrimaryButton;

class SafeHerPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;

  const SafeHerPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : SafeHerColors.pinkButtonGradient,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(26),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: SafeHerColors.primaryRose.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 19),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button (light pink background or plain text)
class SafeHerSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;

  const SafeHerSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? SafeHerColors.secondaryText,
        minimumSize: const Size.fromHeight(46),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    );
  }
}

/// Dark or light top AppBar matching the reference
class SafeHerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool isDark;

  const SafeHerAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? SafeHerColors.midnightPurple
        : SafeHerColors.surfaceWhite;
    final fgColor = isDark ? Colors.white : SafeHerColors.primaryText;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      centerTitle: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: fgColor,
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: fgColor,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: trailing != null ? [trailing!, const SizedBox(width: 12)] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Custom Bottom Navigation matching Screen 5 from Reference:
/// Home, History, AI Assistant, Profile
class SafeHerBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SafeHerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SafeHerColors.midnightPurple,
        border: Border(
          top: BorderSide(
            color: SafeHerColors.darkBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: SafeHerColors.midnightPurple,
        selectedItemColor: SafeHerColors.primaryRose,
        unselectedItemColor: const Color(0xFF8E7E9C),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
