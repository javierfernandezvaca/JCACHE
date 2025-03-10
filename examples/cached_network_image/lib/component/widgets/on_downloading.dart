import 'package:flutter/material.dart';

import 'base_widget.dart';

class OnDownloading extends BaseWidget {
  const OnDownloading({
    super.key,
    required super.event,
    required super.controller,
    this.iconColor,
  });

  final Color? iconColor;

  @override
  Widget buildChild(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: event.progress),
                  IconButton(
                    onPressed: () {
                      controller.cancelDownload();
                    },
                    icon: Icon(
                      Icons.close,
                      color: iconColor ?? Colors.black,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
        // ...
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
