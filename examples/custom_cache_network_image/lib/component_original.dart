import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

///
/// Custom Cache Network Image Component
///
class CustomCacheNetworkImageWidget extends StatelessWidget {
  const CustomCacheNetworkImageWidget({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return JCacheWidget(
      url: imageUrl,
      expiryDays: 0,
      onInitialized: (event, controller) {
        return OnInitializedWidget(
          event: event,
          controller: controller,
        );
      },
      onDownloading: (event, controller) {
        return OnDownloadingWidget(
          event: event,
          controller: controller,
        );
      },
      onCompleted: (event, controller) {
        return OnCompletedWidget(
          event: event,
          controller: controller,
        );
      },
      onError: (event, controller) {
        return OnErrorWidget(
          event: event,
          controller: controller,
        );
      },
      onCancelled: (event, controller) {
        return OnCancelledWidget(
          event: event,
          controller: controller,
        );
      },
    );
  }
}

///
/// Initialized
///
class OnInitializedWidget extends StatelessWidget {
  const OnInitializedWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {},
        ),
      ),
    );
  }
}

///
/// Downloading
///
class OnDownloadingWidget extends StatelessWidget {
  const OnDownloadingWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          color: Colors.green[100],
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: event.progress),
                IconButton(
                  onPressed: () {
                    controller.cancelDownload();
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    '${(event.progress * 100).toStringAsFixed(0)} %',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // ...
              const SizedBox(width: 8),
              // ...
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    '${(event.contentLength / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

///
/// Completed
///
class OnCompletedWidget extends StatelessWidget {
  const OnCompletedWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // ...
        Container(
          color: Colors.green[100],
        ),
        // ...
        Row(
          children: [
            Expanded(
              child: Image.file(
                File(event.resourcePath!),
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        // ...
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              child: Text(
                '${(event.contentLength / 1024 / 1024).toStringAsFixed(2)} MB',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

///
/// Error
///
class OnErrorWidget extends StatelessWidget {
  const OnErrorWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.broken_image_outlined),
          onPressed: () {},
        ),
      ),
    );
  }
}

///
/// Cancelled
///
class OnCancelledWidget extends StatelessWidget {
  const OnCancelledWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      child: Center(
        child: IconButton(
          onPressed: () {
            controller.startDownload(event.resourceUrl);
          },
          icon: const Icon(
            Icons.download,
          ),
          splashRadius: 20,
        ),
      ),
    );
  }
}
