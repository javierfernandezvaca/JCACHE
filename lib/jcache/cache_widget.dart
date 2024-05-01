import 'package:flutter/material.dart';

import 'download_controller.dart';
import 'download_event.dart';
import 'download_status.dart';
import 'stream_builder.dart';

class JCacheWidget extends StatefulWidget {
  const JCacheWidget({
    Key? key,
    required this.url,
    required this.onDownloading,
    required this.onCompleted,
    required this.onError,
    required this.onCancelled,
    required this.onInitialized,
    this.expiryInDays,
  }) : super(key: key);

  final String url;
  final Widget Function(JFileDownloadEvent, JDownloadController) onDownloading;
  final Widget Function(JFileDownloadEvent, JDownloadController) onCompleted;
  final Widget Function(JFileDownloadEvent, JDownloadController) onError;
  final Widget Function(JFileDownloadEvent, JDownloadController) onCancelled;
  final Widget Function(JFileDownloadEvent, JDownloadController) onInitialized;
  final int? expiryInDays;

  @override
  JCacheWidgetState createState() => JCacheWidgetState();
}

class JCacheWidgetState extends State<JCacheWidget> {
  late JDownloadController controller;

  @override
  void initState() {
    super.initState();
    controller = JDownloadController();
  }

  @override
  Widget build(BuildContext context) {
    return JCacheStreamBuilder(
      controller: controller,
      url: widget.url,
      expiryInDays: widget.expiryInDays,
      builder: (context, event) {
        if (event.status == JFileDownloadStatus.downloading) {
          return widget.onDownloading(event, controller);
        } else if (event.status == JFileDownloadStatus.completed) {
          return widget.onCompleted(event, controller);
        } else if (event.status == JFileDownloadStatus.error) {
          return widget.onError(event, controller);
        } else if (event.status == JFileDownloadStatus.cancelled) {
          return widget.onCancelled(event, controller);
        } else {
          return widget.onInitialized(event, controller);
        }
      },
    );
  }
}
