import 'package:flutter/material.dart';

enum HelpQuickLinkActionType {
  url,
  feedback,
  rating,
  support,
}

class HelpQuickLink {
  HelpQuickLink({
    String? id,
    required this.title,
    this.subtitle,
    this.icon = Icons.open_in_new,
    required this.actionType,
    this.url,
    this.onTap,
  }) : id = id ?? title;

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

  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final HelpQuickLinkActionType actionType;
  final Uri? url;
  final VoidCallback? onTap;
}
