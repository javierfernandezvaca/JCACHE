import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'base_widget.dart';

class OnInitialized extends BaseWidget {
  const OnInitialized({
    Key? key,
    required JFileDownloadEvent event,
    required JDownloadController controller,
  }) : super(
          key: key,
          event: event,
          controller: controller,
        );

  @override
  Widget buildChild(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
