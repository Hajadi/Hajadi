import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar that copes with the three shapes a photo can take in this app: a
/// remote URL, a local file path (demo mode / just-picked image), or nothing
/// at all — in which case we draw initials.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  String get _initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? url = photoUrl;

    Widget fallback() => CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Text(
            _initials,
            style: TextStyle(
              fontSize: radius * 0.72,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        );

    if (url == null || url.isEmpty) {
      return fallback();
    }
    if (!url.startsWith('http')) {
      final File file = File(url);
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primary.withValues(alpha: 0.12),
        backgroundImage: file.existsSync() ? FileImage(file) : null,
        child: file.existsSync() ? null : fallback(),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (BuildContext context, String _) => fallback(),
          errorWidget: (BuildContext context, String _, Object __) => fallback(),
        ),
      ),
    );
  }
}
