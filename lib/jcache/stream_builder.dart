import 'dart:async';
import 'package:flutter/material.dart';

import 'download_controller.dart';
import 'download_event.dart';

class JCacheStreamBuilder extends StatefulWidget {
  final String url;
  final Widget Function(BuildContext context, JFileDownloadEvent event) builder;
  final JDownloadController controller;
  final int? expiryDays;

  const JCacheStreamBuilder({
    super.key,
    required this.url,
    required this.builder,
    required this.controller,
    this.expiryDays,
  });

  @override
  JCacheStreamBuilderState createState() => JCacheStreamBuilderState();
}

class JCacheStreamBuilderState extends State<JCacheStreamBuilder> {
  late final StreamSubscription<JFileDownloadEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.progressStream.listen(
      (JFileDownloadEvent event) {
        setState(() {});
      },
    );
    widget.controller.startDownload(
      widget.url,
      expiryDays: widget.expiryDays,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.controller.currentEvent);
  }
}
