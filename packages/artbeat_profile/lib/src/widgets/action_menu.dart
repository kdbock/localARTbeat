import 'package:flutter/material.dart';

class ActionMenu extends StatelessWidget {
  final List<PopupMenuEntry<dynamic>> menuItems;
  final void Function(dynamic value)? onSelected;
  final Icon icon;

  const ActionMenu({
    super.key,
    required this.menuItems,
    this.onSelected,
    this.icon = const Icon(Icons.more_vert),
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: icon,
      onSelected: onSelected,
      itemBuilder: (context) => menuItems,
    );
  }
}
