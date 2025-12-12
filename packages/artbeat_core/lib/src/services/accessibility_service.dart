import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive accessibility service for ARTbeat platform
/// Provides screen reader support, keyboard navigation, and accessibility utilities
class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _isScreenReaderEnabled = false;
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  double _textScaleFactor = 1.0;

  /// Initialize accessibility service
  Future<void> initialize() async {
    await _checkAccessibilitySettings();
  }

  /// Check current accessibility settings
  Future<void> _checkAccessibilitySettings() async {
    // Check if screen reader is enabled
    _isScreenReaderEnabled = await _isScreenReaderActive();

    // Check system accessibility settings
    final window = WidgetsBinding.instance.platformDispatcher;
    _isHighContrastEnabled = window.accessibilityFeatures.highContrast;
    _isLargeTextEnabled = window.accessibilityFeatures.accessibleNavigation;
    _textScaleFactor = window.textScaleFactor;
  }

  /// Check if screen reader is active
  Future<bool> _isScreenReaderActive() async {
    try {
      final binding = WidgetsBinding.instance;
      return binding
          .platformDispatcher
          .accessibilityFeatures
          .accessibleNavigation;
    } catch (e) {
      return false;
    }
  }

  // Getters
  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get isLargeTextEnabled => _isLargeTextEnabled;
  double get textScaleFactor => _textScaleFactor;

  /// Announce text to screen reader
  void announceToScreenReader(String message) {
    if (_isScreenReaderEnabled) {
      SystemChannels.accessibility.send(message);
    }
  }

  /// Create accessible button with proper semantics
  Widget createAccessibleButton({
    required String label,
    required VoidCallback onPressed,
    String? hint,
    Widget? child,
    ButtonStyle? style,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: true,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child ?? Text(label),
      ),
    );
  }

  /// Create accessible text field with proper semantics
  Widget createAccessibleTextField({
    required String label,
    String? hint,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  /// Create accessible image with proper alt text
  Widget createAccessibleImage({
    required String altText,
    required ImageProvider image,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Semantics(
      label: altText,
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: altText,
      ),
    );
  }

  /// Create accessible card with proper semantics
  Widget createAccessibleCard({
    required String label,
    String? hint,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create accessible list item
  Widget createAccessibleListItem({
    required String label,
    String? subtitle,
    String? hint,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      child: ListTile(
        leading: leading,
        title: Text(label),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Get high contrast colors
  ColorScheme getHighContrastColors(BuildContext context) {
    if (_isHighContrastEnabled) {
      return const ColorScheme.highContrastLight();
    }
    return Theme.of(context).colorScheme;
  }

  /// Get accessible text style
  TextStyle getAccessibleTextStyle(BuildContext context, TextStyle? baseStyle) {
    final theme = Theme.of(context);
    final style = baseStyle ?? theme.textTheme.bodyMedium!;

    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * _textScaleFactor,
      color: _isHighContrastEnabled
          ? (_isHighContrastEnabled ? Colors.black : style.color)
          : style.color,
    );
  }

  /// Create focus traversal group for keyboard navigation
  Widget createFocusTraversalGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: child,
    );
  }

  /// Create keyboard shortcuts
  Widget createKeyboardShortcuts({
    required Widget child,
    required Map<ShortcutActivator, Intent> shortcuts,
    required Map<Type, Action<Intent>> actions,
  }) {
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(actions: actions, child: child),
    );
  }

  /// Common keyboard shortcuts for ARTbeat
  Map<ShortcutActivator, Intent> getCommonShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.tab): const NextFocusIntent(),
      const SingleActivator(LogicalKeyboardKey.tab, shift: true):
          const PreviousFocusIntent(),
    };
  }

  /// Create accessible navigation
  Widget createAccessibleNavigation({
    required List<AccessibleNavItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return Semantics(
      label: 'Navigation',
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Semantics(label: item.label, child: item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Validate accessibility compliance
  bool validateAccessibility(Widget widget) {
    // This would typically run accessibility tests
    // For now, return true as a placeholder
    return true;
  }

  /// Create accessible dialog
  Widget createAccessibleDialog({
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return Semantics(
      label: 'Dialog: $title',
      child: AlertDialog(
        title: Semantics(label: title, child: Text(title)),
        content: content,
        actions: actions,
      ),
    );
  }

  /// Create accessible progress indicator
  Widget createAccessibleProgressIndicator({
    required String label,
    double? value,
    String? semanticsValue,
  }) {
    return Semantics(
      label: label,
      value:
          semanticsValue ??
          (value != null ? '${(value * 100).round()}%' : null),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }

  /// Create accessible form
  Widget createAccessibleForm({
    required String formLabel,
    required List<Widget> children,
    GlobalKey<FormState>? formKey,
  }) {
    return Semantics(
      label: formLabel,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: formLabel,
              child: Text(
                formLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Navigation item for accessible navigation
class AccessibleNavItem {
  final String label;
  final Widget icon;
  final String? hint;

  const AccessibleNavItem({required this.label, required this.icon, this.hint});
}

/// Accessibility mixin for widgets
mixin AccessibilityMixin {
  AccessibilityService get accessibility => AccessibilityService();

  /// Announce message to screen reader
  void announce(String message) {
    accessibility.announceToScreenReader(message);
  }

  /// Get accessible text style
  TextStyle getAccessibleTextStyle(
    BuildContext context, [
    TextStyle? baseStyle,
  ]) {
    return accessibility.getAccessibleTextStyle(context, baseStyle);
  }

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled => accessibility.isScreenReaderEnabled;

  /// Check if high contrast is enabled
  bool get isHighContrastEnabled => accessibility.isHighContrastEnabled;
}
