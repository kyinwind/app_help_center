import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_help_center_config.dart';
import '../app_help_center_controller.dart';
import '../l10n/app_help_center_localizations.dart';
import '../models/help_announcement.dart';
import '../models/help_quick_link.dart';
import '../models/version_history_item.dart';
import 'help_feedback_page.dart';

class AppHelpCenterPage extends StatefulWidget {
  const AppHelpCenterPage({
    super.key,
    required this.config,
    this.controller,
    this.title,
    this.subtitle,
  });

  final AppHelpCenterConfig config;
  final AppHelpCenterController? controller;
  final String? title;
  final String? subtitle;

  @override
  State<AppHelpCenterPage> createState() => _AppHelpCenterPageState();
}

class _AppHelpCenterPageState extends State<AppHelpCenterPage> {
  late final AppHelpCenterController _controller;
  late final bool _ownsController;
  var _showAllAnnouncements = false;
  var _showAllVersions = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? AppHelpCenterController(config: widget.config);
    _controller.addListener(_handleControllerChange);
    _controller.load(refreshRemote: widget.config.refreshRemoteOnOpen);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppHelpCenterLocalizations.of(
      context,
      locale: widget.config.locale,
      overrides: widget.config.copyOverrides,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? l10n.text('title')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _controller.load(refreshRemote: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(
                      title: widget.title ?? l10n.text('title'),
                      subtitle: widget.subtitle ?? l10n.text('subtitle'),
                      controller: _controller,
                      l10n: l10n,
                    ),
                    if (_controller.isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 22),
                    _AnnouncementsSection(
                      controller: _controller,
                      l10n: l10n,
                      showAll: _showAllAnnouncements,
                      onToggleShowAll: () {
                        setState(() {
                          _showAllAnnouncements = !_showAllAnnouncements;
                        });
                      },
                    ),
                    _QuickLinksSection(controller: _controller, l10n: l10n),
                    _VersionHistorySection(
                      controller: _controller,
                      l10n: l10n,
                      showAll: _showAllVersions,
                      onToggleShowAll: () {
                        setState(() {
                          _showAllVersions = !_showAllVersions;
                        });
                      },
                    ),
                    _FaqSection(config: widget.config, l10n: l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.l10n,
  });

  final String title;
  final String subtitle;
  final AppHelpCenterController controller;
  final AppHelpCenterLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <Widget>[
      if (controller.config.supportUrl != null ||
          controller.config.onOpenSupport != null)
        _ActionButton(
          icon: Icons.support_agent,
          label: l10n.text('support'),
          onPressed: controller.openSupport,
        ),
      if (controller.hasUnreadContent)
        _ActionButton(
          icon: Icons.check_circle_outline,
          label: l10n.text('markAllRead'),
          onPressed: controller.markAllAsRead,
        ),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            final titleBlock = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            );

            final actionBlock =
                Wrap(spacing: 10, runSpacing: 10, children: actions);

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    actionBlock,
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 18),
                  Flexible(child: actionBlock),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection({
    required this.controller,
    required this.l10n,
    required this.showAll,
    required this.onToggleShowAll,
  });

  final AppHelpCenterController controller;
  final AppHelpCenterLocalizations l10n;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  @override
  Widget build(BuildContext context) {
    final announcements = controller.announcements;
    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = showAll || announcements.length == 1
        ? announcements
        : [_featuredAnnouncement(announcements)];

    return _Section(
      title: l10n.text('announcements'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in visible) ...[
            _AnnouncementCard(
              item: item,
              isUnread: controller.isAnnouncementUnread(item),
              controller: controller,
              l10n: l10n,
              summaryText: !showAll && announcements.length > 1
                  ? _announcementSummaryText(announcements)
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          if (announcements.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleShowAll,
                icon: Icon(showAll ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  showAll
                      ? l10n.text('collapseAnnouncements')
                      : l10n.text('viewAllAnnouncements'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  HelpAnnouncement _featuredAnnouncement(List<HelpAnnouncement> items) {
    final unread = items.where(controller.isAnnouncementUnread).toList();
    if (unread.isNotEmpty) {
      return unread.first;
    }
    return items.first;
  }

  String _announcementSummaryText(List<HelpAnnouncement> items) {
    final unreadCount = items.where(controller.isAnnouncementUnread).length;
    if (unreadCount > 0) {
      return l10n.format('unreadAnnouncementCount', unreadCount);
    }
    return l10n.format('announcementCount', items.length);
  }
}

class _AnnouncementCard extends StatefulWidget {
  const _AnnouncementCard({
    required this.item,
    required this.isUnread,
    required this.controller,
    required this.l10n,
    this.summaryText,
  });

  final HelpAnnouncement item;
  final bool isUnread;
  final AppHelpCenterController controller;
  final AppHelpCenterLocalizations l10n;
  final String? summaryText;

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = _levelColor(theme, widget.item.level);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.isUnread
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
                widget.controller.markAnnouncementRead(widget.item);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_levelIcon(widget.item.level), color: levelColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (widget.item.isPinned)
                              _Badge(
                                label: widget.l10n.text('pinned'),
                                color: levelColor,
                              ),
                            _Badge(
                              label: widget.l10n.text(
                                  'announcement.${widget.item.level.name}'),
                              color: levelColor,
                            ),
                            if (widget.isUnread)
                              _Badge(
                                label: widget.l10n.text('new'),
                                color: theme.colorScheme.error,
                              ),
                            if (widget.summaryText != null)
                              _Badge(
                                label: widget.summaryText!,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.item.title,
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.message,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_expanded && widget.item.linkUrl != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _ActionButton(
                  icon: Icons.open_in_new,
                  label:
                      widget.item.linkTitle ?? widget.l10n.text('viewDetails'),
                  onPressed: () async {
                    await widget.controller.markAnnouncementRead(widget.item);
                    await widget.controller.openUrl(widget.item.linkUrl!);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickLinksSection extends StatelessWidget {
  const _QuickLinksSection({
    required this.controller,
    required this.l10n,
  });

  final AppHelpCenterController controller;
  final AppHelpCenterLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final links = controller.quickLinks;
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: l10n.text('quickLinks'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 3 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 86,
            ),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return _QuickLinkCard(
                link: link,
                title: _quickLinkTitle(link),
                controller: controller,
                onOpenFeedback: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HelpFeedbackPage(
                        config: controller.config,
                        feedbackService: controller.feedbackService,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _quickLinkTitle(HelpQuickLink link) {
    if (link.title.isNotEmpty) {
      return link.title;
    }
    switch (link.actionType) {
      case HelpQuickLinkActionType.feedback:
        return l10n.text('feedback');
      case HelpQuickLinkActionType.rating:
        return l10n.text('rating');
      case HelpQuickLinkActionType.support:
        return l10n.text('support');
      case HelpQuickLinkActionType.url:
        return link.title;
    }
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.link,
    required this.title,
    required this.controller,
    required this.onOpenFeedback,
  });

  final HelpQuickLink link;
  final String title;
  final AppHelpCenterController controller;
  final VoidCallback onOpenFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (link.actionType == HelpQuickLinkActionType.feedback &&
              controller.hasFeedback) {
            onOpenFeedback();
            return;
          }
          controller.openQuickLink(link);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(link.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (link.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        link.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionHistorySection extends StatelessWidget {
  const _VersionHistorySection({
    required this.controller,
    required this.l10n,
    required this.showAll,
    required this.onToggleShowAll,
  });

  final AppHelpCenterController controller;
  final AppHelpCenterLocalizations l10n;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  @override
  Widget build(BuildContext context) {
    final items = controller.versionHistory;
    return _Section(
      title: l10n.text('versionHistory'),
      child: items.isEmpty
          ? _EmptyState(
              icon: Icons.history,
              title: l10n.text('noVersionHistory'),
              message: l10n.text('noVersionHistoryMessage'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in _visibleItems(items)) ...[
                  _VersionHistoryCard(
                    item: item,
                    isUnread: controller.isVersionUnread(item),
                    controller: controller,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 10),
                ],
                if (items.length > 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onToggleShowAll,
                      icon:
                          Icon(showAll ? Icons.expand_less : Icons.expand_more),
                      label: Text(
                        showAll
                            ? l10n.text('collapseVersions')
                            : l10n.text('viewAllVersions'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  List<VersionHistoryItem> _visibleItems(List<VersionHistoryItem> items) {
    if (showAll || items.length == 1) {
      return items;
    }
    final unread = items.where(controller.isVersionUnread).toList();
    if (unread.isNotEmpty) {
      return [unread.first];
    }
    return [items.first];
  }
}

class _VersionHistoryCard extends StatelessWidget {
  const _VersionHistoryCard({
    required this.item,
    required this.isUnread,
    required this.controller,
    required this.l10n,
  });

  final VersionHistoryItem item;
  final bool isUnread;
  final AppHelpCenterController controller;
  final AppHelpCenterLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isUnread
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isUnread) _UnreadDot(color: theme.colorScheme.error),
                Text(item.versionName, style: theme.textTheme.titleMedium),
                if (isUnread)
                  _Badge(
                      label: l10n.text('new'), color: theme.colorScheme.error),
                Text(
                  DateFormat.yMMMd(l10n.locale.toLanguageTag())
                      .format(item.publishedAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.changes),
            if (item.videoTitle != null) ...[
              const SizedBox(height: 12),
              Text(item.videoTitle!, style: theme.textTheme.labelLarge),
            ],
            if (item.videoLinks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final link in item.videoLinks)
                    _ActionButton(
                      icon: Icons.ondemand_video_outlined,
                      label: link.title,
                      onPressed: () async {
                        await controller.markVersionRead(item);
                        await controller.openUrl(link.url);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({
    required this.config,
    required this.l10n,
  });

  final AppHelpCenterConfig config;
  final AppHelpCenterLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (config.faqItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: l10n.text('faq'),
      child: Card(
        elevation: 0,
        child: Column(
          children: [
            for (final entry in config.faqItems.asMap().entries) ...[
              ExpansionTile(
                title: Text(entry.value.question),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entry.value.answer),
                  ),
                ],
              ),
              if (entry.key < config.faqItems.length - 1)
                const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {
        onPressed();
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

IconData _levelIcon(HelpAnnouncementLevel level) {
  switch (level) {
    case HelpAnnouncementLevel.info:
      return Icons.campaign_outlined;
    case HelpAnnouncementLevel.success:
      return Icons.check_circle_outline;
    case HelpAnnouncementLevel.warning:
      return Icons.warning_amber_outlined;
    case HelpAnnouncementLevel.critical:
      return Icons.error_outline;
  }
}

Color _levelColor(ThemeData theme, HelpAnnouncementLevel level) {
  switch (level) {
    case HelpAnnouncementLevel.info:
      return theme.colorScheme.primary;
    case HelpAnnouncementLevel.success:
      return Colors.green;
    case HelpAnnouncementLevel.warning:
      return Colors.orange;
    case HelpAnnouncementLevel.critical:
      return theme.colorScheme.error;
  }
}
