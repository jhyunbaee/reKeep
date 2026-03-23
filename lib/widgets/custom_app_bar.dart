import 'package:flutter/material.dart';

PreferredSizeWidget customAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  bool centerTitle = true,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 1,
    centerTitle: centerTitle,
    leading: Navigator.canPop(context)
        ? IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black), // ← 요거
            onPressed: () => Navigator.pop(context),
          )
        : null,
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        fontSize: 18,
      ),
    ),
    actions: actions,
  );
}
