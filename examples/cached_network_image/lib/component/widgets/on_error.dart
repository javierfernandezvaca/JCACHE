import 'package:flutter/material.dart';

import 'base_widget.dart';

class OnError extends BaseWidget {
  const OnError({
    super.key,
    required super.event,
    required super.controller,
  });

  @override
  Widget buildChild(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.broken_image_outlined),
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          Text(event.error ?? 'An error has occurred'),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text('Please try again'),
            onPressed: () {
              controller.startDownload(event.resourceUrl);
            },
          ),
        ],
      ),
    );
  }
}
