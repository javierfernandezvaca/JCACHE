// Constantes para los colores
import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

// const kIconColor = Colors.black;

abstract class BaseWidget extends StatelessWidget {
  final JFileDownloadEvent event;
  final JDownloadController controller;
  final Color? color;

  const BaseWidget({
    super.key,
    required this.event,
    required this.controller,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? const Color(0xFFCCCCCC),
      child: buildChild(context),
    );
  }

  Widget buildChild(BuildContext context);
}
