import 'package:flutter/material.dart';

import 'base_widget.dart';

class OnInitialized extends BaseWidget {
  const OnInitialized({
    super.key,
    required super.event,
    required super.controller,
  });

  @override
  Widget buildChild(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
