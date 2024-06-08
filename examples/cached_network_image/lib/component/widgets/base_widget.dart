// Constantes para los colores
import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

// const kIconColor = Colors.black;

abstract class BaseWidget extends StatelessWidget {
  final JFileDownloadEvent event;
  final JDownloadController controller;
  final Color? color;

  const BaseWidget({
    Key? key,
    required this.event,
    required this.controller,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? const Color(0xFFCCCCCC),
      child: buildChild(context),
    );
  }

  Widget buildChild(BuildContext context);
}
