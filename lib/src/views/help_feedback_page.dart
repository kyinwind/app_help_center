import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_help_center_config.dart';
import '../l10n/app_help_center_localizations.dart';
import '../models/help_feedback.dart';
import '../services/feedback_service.dart';
import '../services/help_link_launcher.dart';
import '../services/system_info_provider.dart';

/// Built-in feedback form for configured feedback channels.
class HelpFeedbackPage extends StatefulWidget {
  /// Creates a feedback page for config.feedback.
  const HelpFeedbackPage({
    super.key,
    required this.config,
    this.feedbackService = const FeedbackService(),
    this.systemInfoProvider = const SystemInfoProvider(),
    this.imagePicker,
  });

  /// Help center configuration containing feedback settings.
  final AppHelpCenterConfig config;

  /// Service used to submit feedback.
  final FeedbackService feedbackService;

  /// Provider used to collect system information for feedback.
  final SystemInfoProvider systemInfoProvider;

  /// Optional ImagePicker injection (for testing).
  /// If null, uses the default ImagePicker.
  final ImagePicker? imagePicker;

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  var _selectedChannels = <HelpFeedbackChannel>{};
  var _includeSystemInfo = true;
  var _isSubmitting = false;
  final _attachments = <Uint8List>[];
  final _attachmentFilenames = <String>[];
  final _imagePicker = ImagePicker();

  HelpFeedbackConfig get _feedback => widget.config.feedback!;

  @override
  void initState() {
    super.initState();
    _includeSystemInfo = _feedback.includeSystemInfo;
    _selectedChannels = _feedback.availableChannels.toSet();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppHelpCenterLocalizations.of(
      context,
      locale: widget.config.locale,
      overrides: widget.config.copyOverrides,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('feedbackTitle'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Feedback header (mirrors SwiftHelpCenter's FeedbackView.header)
                    _FeedbackHeader(config: widget.config, l10n: l10n),
                    // Feedback action buttons: Rate + Tech Support
                    // (mirrors SwiftHelpCenter's FeedbackView.feedbackActions)
                    _FeedbackActions(config: widget.config, l10n: l10n),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _contentController,
                      minLines: 6,
                      maxLines: 12,
                      textInputAction: TextInputAction.newline,
                      maxLength: 1700,
                      buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) {
                        return Text(
                          l10n.format('feedbackCharCount', currentLength),
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                      decoration: InputDecoration(
                        labelText: l10n.text('feedbackContent'),
                        hintText: l10n.text('feedbackContentHint'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.text('feedbackRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: l10n.text('feedbackContact'),
                        hintText: l10n.text('feedbackContactHint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_feedback.allowChannelSelection &&
                        _feedback.availableChannels.length > 1) ...[
                      const SizedBox(height: 18),
                      Text(
                        l10n.text('feedbackChannels'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final channel in _feedback.availableChannels)
                            FilterChip(
                              label: Text(_channelLabel(l10n, channel)),
                              selected: _selectedChannels.contains(channel),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedChannels.add(channel);
                                  } else if (_selectedChannels.length > 1) {
                                    _selectedChannels.remove(channel);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Screenshot picker (only when Discord is selected and allowed)
                    if (_feedback.allowScreenshots &&
                        _selectedChannels
                            .contains(HelpFeedbackChannel.discordWebhook))
                      _ScreenshotPicker(
                        attachments: _attachments,
                        attachmentFilenames: _attachmentFilenames,
                        maxCount: _feedback.maxScreenshots,
                        l10n: l10n,
                        onAdd: _addScreenshot,
                        onRemove: _removeScreenshot,
                      ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.text('feedbackIncludeSystemInfo')),
                      value: _includeSystemInfo,
                      onChanged: (value) {
                        setState(() {
                          _includeSystemInfo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : () => _submit(l10n),
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(l10n.text('feedbackSubmit')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppHelpCenterLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final systemInfo = _includeSystemInfo
          ? widget.systemInfoProvider.collect(
              appName: widget.config.appName,
              locale: widget.config.locale,
            )
          : null;

      final payload = HelpFeedbackPayload(
        content: _contentController.text,
        contact: _contactController.text,
        systemInfo: systemInfo,
        channels: _selectedChannels.toList(),
        attachments: _attachments,
        attachmentFilenames: _attachmentFilenames,
      );

      await widget.feedbackService.submit(config: _feedback, payload: payload);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('feedbackSuccess'))),
      );
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.text('feedbackFailure')}: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _channelLabel(
    AppHelpCenterLocalizations l10n,
    HelpFeedbackChannel channel,
  ) {
    return l10n.text('feedback.${channel.name}');
  }

  Future<void> _addScreenshot() async {
    final picker = widget.imagePicker ?? _imagePicker;
    final maxCount = _feedback.maxScreenshots;
    if (_attachments.length >= maxCount) return;

    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final filename = xFile.name;

    setState(() {
      _attachments.add(bytes);
      _attachmentFilenames.add(filename);
    });
  }

  void _removeScreenshot(int index) {
    setState(() {
      _attachments.removeAt(index);
      _attachmentFilenames.removeAt(index);
    });
  }
}

// ---------------------------------------------------------------------------
// Feedback Header (mirrors SwiftHelpCenter's FeedbackView.feedbackHeader)
// ---------------------------------------------------------------------------

class _FeedbackHeader extends StatelessWidget {
  const _FeedbackHeader({
    required this.config,
    required this.l10n,
  });

  /// Help center configuration containing feedback settings.
  final AppHelpCenterConfig config;
  final AppHelpCenterLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bubble_chart_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.text('feedbackTitle'),
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                l10n.text('feedbackFollowUp'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback Action Buttons (mirrors SwiftHelpCenter's FeedbackView.feedbackActions)
// ---------------------------------------------------------------------------

class _FeedbackActions extends StatelessWidget {
  const _FeedbackActions({
    required this.config,
    required this.l10n,
  });

  /// Help center configuration containing feedback settings.
  final AppHelpCenterConfig config;
  final AppHelpCenterLocalizations l10n;
  final HelpLinkLauncher linkLauncher = const HelpLinkLauncher();

  @override
  Widget build(BuildContext context) {
    final hasRating = config.ratingUrl != null || config.onOpenRating != null;
    final hasSupport =
        config.supportUrl != null || config.onOpenSupport != null;

    if (!hasRating && !hasSupport) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (hasRating)
          FilledButton.tonalIcon(
            onPressed: () => _openRating(),
            icon: const Icon(Icons.star_outline),
            label: Text(l10n.text('feedbackRate')),
          ),
        if (hasSupport)
          OutlinedButton.icon(
            onPressed: () => _openSupport(),
            icon: const Icon(Icons.support_agent),
            label: Text(l10n.text('feedbackTechSupport')),
          ),
      ],
    );
  }

  Future<void> _openRating() async {
    final callback = config.onOpenRating;
    if (callback != null) {
      await callback();
      return;
    }
    final url = config.ratingUrl;
    if (url != null) {
      await linkLauncher.open(url);
    }
  }

  Future<void> _openSupport() async {
    final callback = config.onOpenSupport;
    if (callback != null) {
      await callback();
      return;
    }
    final url = config.supportUrl;
    if (url != null) {
      await linkLauncher.open(url);
    }
  }
}

// ---------------------------------------------------------------------------
// Screenshot Picker (mirrors SwiftHelpCenter's ScreenshotPickerView)
// ---------------------------------------------------------------------------

class _ScreenshotPicker extends StatelessWidget {
  const _ScreenshotPicker({
    required this.attachments,
    required this.attachmentFilenames,
    required this.maxCount,
    required this.l10n,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Uint8List> attachments;
  final List<String> attachmentFilenames;
  final int maxCount;
  final AppHelpCenterLocalizations l10n;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('screenshotAdd'), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              if (attachments.length < maxCount)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (int i = 0; i < attachments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          attachments[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton.filledTonal(
                          onPressed: () => onRemove(i),
                          icon: const Icon(Icons.close, size: 14),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(24, 24),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.text('screenshotMax'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
