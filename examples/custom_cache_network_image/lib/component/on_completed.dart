import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'base_widget.dart';

class OnCompleted extends BaseWidget {
  const OnCompleted({
    Key? key,
    required JFileDownloadEvent event,
    required JDownloadController controller,
  }) : super(key: key, event: event, controller: controller);

  @override
  Widget buildChild(BuildContext context) {
    // ...
    File imageFile = File(event.resourcePath!);
    // ...
    return Stack(
      alignment: Alignment.bottomLeft,
      fit: StackFit.loose,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Row(
              children: [
                Expanded(
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.clear,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () async {
                await JCacheManager.remove(event.resourceUrl);
                if (await imageFile.exists()) {
                  await imageFile.delete();
                }
                controller.startDownload(event.resourceUrl);
              },
              splashRadius: 20,
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
