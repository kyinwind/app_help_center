import 'package:flutter/material.dart';

import '../app_help_center_config.dart';
import '../l10n/app_help_center_localizations.dart';
import '../models/help_feedback.dart';
import '../services/feedback_service.dart';
import '../services/system_info_provider.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({
    super.key,
    required this.config,
    this.feedbackService = const FeedbackService(),
    this.systemInfoProvider = const SystemInfoProvider(),
  });

  final AppHelpCenterConfig config;
  final FeedbackService feedbackService;
  final SystemInfoProvider systemInfoProvider;

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
                    TextFormField(
                      controller: _contentController,
                      minLines: 6,
                      maxLines: 12,
                      textInputAction: TextInputAction.newline,
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
}
