import 'package:flutter/material.dart';

/// Action performed when a quick link is tapped.
enum HelpQuickLinkActionType {
  /// Opens HelpQuickLink.url.
  url,

  /// Opens the built-in feedback form.
  feedback,

  /// Opens the configured rating action.
  rating,

  /// Opens the configured support action.
  support,
}

/// Shortcut action shown in the help center quick links section.
class HelpQuickLink {
  /// Creates a custom quick link.
  HelpQuickLink({
    String? id,
    required this.title,
    this.subtitle,
    this.icon = Icons.open_in_new,
    required this.actionType,
    this.url,
    this.onTap,
  }) : id = id ?? title;

  /// Creates a quick link that opens a URL.
  HelpQuickLink.url({
    String? id,
    required String title,
    String? subtitle,
    IconData icon = Icons.open_in_new,
    required Uri url,
  }) : this(
          id: id,
          title: title,
          subtitle: subtitle,
          icon: icon,
          actionType: HelpQuickLinkActionType.url,
          url: url,
        );

  /// Creates a quick link that opens the feedback form.
  HelpQuickLink.feedback({
    String? title,
    String? subtitle,
    IconData icon = Icons.feedback_outlined,
    VoidCallback? onTap,
  }) : this(
          id: 'app_help_center.default.feedback',
          title: title ?? '',
          subtitle: subtitle,
          icon: icon,
          actionType: HelpQuickLinkActionType.feedback,
          onTap: onTap,
        );

  /// Creates a quick link that opens the rating action.
  HelpQuickLink.rating({
    String? title,
    String? subtitle,
    IconData icon = Icons.star_outline,
    VoidCallback? onTap,
  }) : this(
          id: 'app_help_center.default.rating',
          title: title ?? '',
          subtitle: subtitle,
          icon: icon,
          actionType: HelpQuickLinkActionType.rating,
          onTap: onTap,
        );

  /// Creates a quick link that opens the support action.
  HelpQuickLink.support({
    String? title,
    String? subtitle,
    IconData icon = Icons.support_agent,
    VoidCallback? onTap,
  }) : this(
          id: 'app_help_center.default.support',
          title: title ?? '',
          subtitle: subtitle,
          icon: icon,
          actionType: HelpQuickLinkActionType.support,
          onTap: onTap,
        );

  /// Stable identifier for this quick link.
  final String id;

  /// Title shown in the quick link card.
  final String title;

  /// Optional subtitle shown under title.
  final String? subtitle;

  /// Icon shown beside the title.
  final IconData icon;

  /// Action type used by the controller.
  final HelpQuickLinkActionType actionType;

  /// URL opened when actionType is HelpQuickLinkActionType.url.
  final Uri? url;

  /// Optional custom tap callback.
  final VoidCallback? onTap;
}
