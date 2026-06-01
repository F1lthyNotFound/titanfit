import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../flavor/gym_flavor_service.dart';

/// Resolves API media paths (relative, absolute, or data URLs) for display.
String resolveMediaUrl(String raw, {String? apiBase}) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('data:')) return value;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value.replaceFirst(RegExp(r'^http://'), 'https://');
  }
  final base = _normalizeBase(apiBase ??
      GymFlavorService.instance.flavor?.apiBase ??
      ApiConfig.defaultApiBase);
  if (base.isEmpty) return value.startsWith('/') ? value : '/$value';
  if (value.startsWith('/')) return '$base$value';
  return '$base/$value';
}

String _normalizeBase(String url) {
  var u = url.trim().replaceAll(RegExp(r'/+$'), '');
  if (u.isEmpty) return u;
  if (!u.contains('://')) u = 'https://$u';
  return u.replaceFirst(RegExp(r'^http://'), 'https://');
}

class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.source,
    this.apiBase,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  final String source;
  final String? apiBase;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(source, apiBase: apiBase);
    if (url.isEmpty) {
      return _wrap(placeholder ?? _defaultPlaceholder(context));
    }
    if (url.startsWith('data:')) {
      try {
        final comma = url.indexOf(',');
        if (comma > 0) {
          final bytes = base64Decode(url.substring(comma + 1));
          return _wrap(Image.memory(bytes, width: width, height: height, fit: fit));
        }
      } catch (_) {
        return _wrap(_defaultPlaceholder(context));
      }
    }
    return _wrap(
      CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (_, __, ___) => placeholder ?? _defaultPlaceholder(context),
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.outline),
    );
  }
}
