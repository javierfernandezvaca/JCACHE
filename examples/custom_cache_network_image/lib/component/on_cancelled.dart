import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'base_widget.dart';

class OnCancelled extends BaseWidget {
  const OnCancelled({
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
    return Center(
      child: IconButton(
        onPressed: () {
          controller.startDownload(event.resourceUrl);
        },
        icon: const Icon(
          Icons.download,
          color: kIconColor,
        ),
        splashRadius: 20,
      ),
    );
  }
}
