import 'package:flutter/material.dart';

import 'base_widget.dart';

class OnCancelled extends BaseWidget {
  const OnCancelled({
    super.key,
    required super.event,
    required super.controller,
    this.iconColor,
  });

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
