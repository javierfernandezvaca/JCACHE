import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'base_widget.dart';

class OnCompleted extends BaseWidget {
  const OnCompleted({
    super.key,
    required super.event,
    required super.controller,
  });

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
                  child: Builder(builder: (context) {
                    // ContentLength / 1024 / 1024;
                    double size =
                        event.contentLength * pow(1024, -2).toDouble();
                    return Text(
                      '${size.toStringAsFixed(2)} MB',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
