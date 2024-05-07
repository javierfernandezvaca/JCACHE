import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'on_cancelled.dart';
import 'on_completed.dart';
import 'on_downloading.dart';
import 'on_error.dart';
import 'on_initialized.dart';

///
/// Custom Cached Network Image
///
class CachedNetworkImage extends StatelessWidget {
  const CachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.expiryDays,
  }) : super(key: key);

  final String imageUrl;
  final int? expiryDays;

  @override
  Widget build(BuildContext context) {
    return JCacheWidget(
      url: imageUrl,
      expiryDays: expiryDays ?? 1,
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
        return OnCompleted(
          event: event,
          controller: controller,
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
