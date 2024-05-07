// Constantes para los colores
import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

const colorGreyLight = Color(0xFFCCCCCC);
const colorGreyDark = Color(0xFF9C9C9C);
const kIconColor = Colors.black;

abstract class BaseWidget extends StatelessWidget {
  final JFileDownloadEvent event;
  final JDownloadController controller;

  const BaseWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorGreyLight,
      child: buildChild(context),
    );
  }

  Widget buildChild(BuildContext context);
}
