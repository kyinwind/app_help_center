import 'package:flutter/material.dart';

import '../app_help_center_config.dart';
import '../app_help_center_controller.dart';
import '../l10n/app_help_center_localizations.dart';
import 'app_help_center_page.dart';

/// Opens the standard help-center page with a Material route.
Future<T?> showAppHelpCenter<T>(
  BuildContext context, {
  required AppHelpCenterConfig config,
  AppHelpCenterController? controller,
  String? title,
  String? subtitle,
  bool fullscreenDialog = false,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      fullscreenDialog: fullscreenDialog,
      builder: (_) => AppHelpCenterPage(
        config: config,
        controller: controller,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

/// Standard help-center entry button with an optional unread indicator.
class AppHelpCenterButton extends StatefulWidget {
  /// Creates a button that opens [AppHelpCenterPage].
  const AppHelpCenterButton({
    super.key,
    required this.config,
    this.controller,
    this.title,
    this.subtitle,
    this.label,
    this.icon = const Icon(Icons.help_outline),
    this.showUnreadIndicator = true,
    this.fullscreenDialog = false,
  });

  final AppHelpCenterConfig config;
  final AppHelpCenterController? controller;
  final String? title;
  final String? subtitle;
  final String? label;
  final Widget icon;
  final bool showUnreadIndicator;
  final bool fullscreenDialog;

  @override
  State<AppHelpCenterButton> createState() => _AppHelpCenterButtonState();
}

class _AppHelpCenterButtonState extends State<AppHelpCenterButton> {
  late AppHelpCenterController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(AppHelpCenterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.config != widget.config) {
      _detachController();
      _attachController();
    }
  }

  void _attachController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? AppHelpCenterController(config: widget.config);
    _controller.addListener(_changed);
    _controller.load();
  }

  void _detachController() {
    _controller.removeListener(_changed);
    if (_ownsController) {
      _controller.reviewPromptManager?.dispose();
      _controller.dispose();
    }
  }

  void _changed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppHelpCenterLocalizations.of(
      context,
      locale: widget.config.locale,
      overrides: widget.config.copyOverrides,
    );
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        widget.icon,
        if (widget.showUnreadIndicator && _controller.hasUnreadContent)
          PositionedDirectional(
            top: -2,
            end: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );

    return TextButton.icon(
      icon: icon,
      label: Text(widget.label ?? l10n.text('title')),
      onPressed: () => showAppHelpCenter<void>(
        context,
        config: widget.config,
        controller: _controller,
        title: widget.title,
        subtitle: widget.subtitle,
        fullscreenDialog: widget.fullscreenDialog,
      ),
    );
  }
}
