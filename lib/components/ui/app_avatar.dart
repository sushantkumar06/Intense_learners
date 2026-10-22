import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppAvatarSize { sm, md, lg, xl }

class AppAvatar extends StatelessWidget {
  final String name;
  final String? uri;
  final AppAvatarSize size;

  const AppAvatar({
    super.key,
    required this.name,
    this.uri,
    this.size = AppAvatarSize.md,
  });

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    double boxSize;
    double fontSize;

    switch (size) {
      case AppAvatarSize.sm:
        boxSize = 32;
        fontSize = 12;
        break;
      case AppAvatarSize.md:
        boxSize = 44;
        fontSize = 15;
        break;
      case AppAvatarSize.lg:
        boxSize = 60;
        fontSize = 20;
        break;
      case AppAvatarSize.xl:
        boxSize = 88;
        fontSize = 28;
        break;
    }

    if (uri != null && uri!.isNotEmpty) {
      final cachePx = (boxSize * 2).toInt();
      return ClipOval(
        child: Image.network(
          uri!,
          width: boxSize,
          height: boxSize,
          cacheWidth: cachePx,
          cacheHeight: cachePx,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(boxSize, fontSize),
        ),
      );
    }

    return _buildFallback(boxSize, fontSize);
  }

  Widget _buildFallback(double boxSize, double fontSize) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: const BoxDecoration(
        color: AppColors.indigoTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: AppTypography.label.copyWith(
          color: AppColors.indigo,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
