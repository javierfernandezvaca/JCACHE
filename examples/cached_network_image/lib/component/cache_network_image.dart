import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'widgets/fade_in_widget.dart';
import 'widgets/on_cancelled.dart';
import 'widgets/on_completed.dart';
import 'widgets/on_downloading.dart';
import 'widgets/on_error.dart';
import 'widgets/on_initialized.dart';

///
/// Custom Cached Network Image
///
class CachedNetworkImage extends StatelessWidget {
  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.expiryDuration,
  });

  final String imageUrl;
  final Duration? expiryDuration;

  @override
  Widget build(BuildContext context) {
    return JCacheWidget(
      url: imageUrl,
      expiryDuration: expiryDuration ?? const Duration(days: 1),
      onInitialized: (event, controller) {
        return OnInitialized(
          event: event,
          controller: controller,
        );
      },
      onDownloading: (event, controller) {
        return OnDownloading(
          event: event,
          controller: controller,
        );
      },
      onCompleted: (event, controller) {
        return FadeInWidget(
          child: OnCompleted(
            event: event,
            controller: controller,
          ),
        );
      },
      onError: (event, controller) {
        return OnError(
          event: event,
          controller: controller,
        );
      },
      onCancelled: (event, controller) {
        return OnCancelled(
          event: event,
          controller: controller,
        );
      },
    );
  }
}
