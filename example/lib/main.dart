import 'package:app_help_center/app_help_center.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_help_center example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AppHelpCenterPage(config: _config),
    );
  }
}

final _config = AppHelpCenterConfig(
  appName: 'Demo App',
  supportUrl: Uri.parse('https://example.com/support'),
  ratingUrl: Uri.parse('https://example.com/rate'),
  feedback: HelpFeedbackConfig(
    email: 'feedback@example.com',
    webFormUrl: Uri.parse('https://example.com/feedback'),
    submitHandler: (payload) async {
      debugPrint(payload.combinedContent);
    },
  ),
  remoteVersionSupplementUrl:
      Uri.parse('https://example.com/version-supplements.json'),
  announcements: [
    HelpAnnouncement(
      id: 'welcome-help-center',
      title: '欢迎使用帮助中心',
      message: '这里会展示产品公告、重要提醒和与用户沟通相关的内容。',
      publishedAt: DateTime(2026, 6, 3),
      level: HelpAnnouncementLevel.info,
      linkTitle: '查看项目',
      linkUrl: Uri.parse('https://github.com/yangxuehui/app_help_center'),
      isPinned: true,
    ),
    HelpAnnouncement(
      id: 'scheduled-maintenance',
      title: '技术支持服务维护提醒',
      message: '技术支持页面将在维护窗口内短暂不可用，用户仍可通过邮件提交反馈。',
      publishedAt: DateTime(2026, 6),
      level: HelpAnnouncementLevel.warning,
      expiresAt: DateTime(2026, 7),
    ),
  ],
  versionHistory: [
    VersionHistoryItem(
      versionName: 'v1.1.0',
      publishedAt: DateTime(2026, 6, 6),
      changes: '1. 新增远程公告\n2. 优化帮助中心布局\n3. 修复若干体验问题',
      videoTitle: '版本介绍视频',
      videoLinks: [
        HelpVideoLink(title: 'YouTube', url: Uri.parse('https://youtube.com')),
        HelpVideoLink(
            title: 'Bilibili', url: Uri.parse('https://bilibili.com')),
      ],
    ),
    VersionHistoryItem(
      versionName: 'v1.0.0',
      publishedAt: DateTime(2026, 5, 20),
      changes: '首次发布帮助中心、FAQ、快速入口和评分入口。',
    ),
  ],
  quickLinks: [
    HelpQuickLink.url(
      title: '使用指南',
      subtitle: '查看在线文档',
      icon: Icons.menu_book_outlined,
      url: Uri.parse('https://example.com/guide'),
    ),
  ],
  faqItems: [
    HelpFaqItem(
      question: '如何开始使用？',
      answer:
          '导入 app_help_center，创建 AppHelpCenterConfig，然后展示 AppHelpCenterPage。',
    ),
    HelpFaqItem(
      question: '远程公告支持什么格式？',
      answer:
          '支持 SwiftHelpCenter 风格 JSON 数组，也支持 {"announcements": [...]} 包装结构。',
    ),
  ],
);
