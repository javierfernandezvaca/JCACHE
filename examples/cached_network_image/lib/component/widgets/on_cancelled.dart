import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'base_widget.dart';

class OnCancelled extends BaseWidget {
  const OnCancelled({
    Key? key,
    required JFileDownloadEvent event,
    required JDownloadController controller,
    this.iconColor,
  }) : super(
          key: key,
          event: event,
          controller: controller,
        );

  final Color? iconColor;

  @override
  Widget buildChild(BuildContext context) {
    return Center(
      child: IconButton(
        onPressed: () {
          controller.startDownload(event.resourceUrl);
        },
        icon: Icon(
          Icons.download,
          color: iconColor ?? Colors.black,
        ),
        splashRadius: 20,
      ),
    );
  }
}
