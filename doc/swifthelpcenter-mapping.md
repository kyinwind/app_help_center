# SwiftHelpCenter 到 app_help_center 概念映射

本文档记录 Flutter 版第一阶段 MVP 与 SwiftHelpCenter 的概念对应关系。

## 总体原则

- 保留 SwiftHelpCenter 的产品概念和用户体验。
- 不复制 SwiftUI、AppKit、UIKit 专属 API。
- Flutter 版第一版保持轻量，以 Flutter Widget、Dart model 和 URL-first 外部动作作为核心。
- 第二版开始再补更开放的反馈、评分提醒和平台回调能力。

## 核心入口

| SwiftHelpCenter | app_help_center | 说明 |
| --- | --- | --- |
| `SHCHelpCenterConfiguration` | `AppHelpCenterConfig` | 帮助中心配置模型 |
| `SHCHelpCenterManager` | `AppHelpCenterController` | 状态、刷新、未读、打开链接 |
| `SHCVersionHistoryListView` | `AppHelpCenterPage` | 帮助中心主页面 |
| `SHCHelpButton` | 暂未实现 | 可由调用方自己放置按钮并打开 `AppHelpCenterPage` |
| `SHCHelpNavigationLink` | 暂未实现 | Flutter 中由调用方用 `Navigator` 自行接入 |

## 数据模型

| SwiftHelpCenter | app_help_center | 说明 |
| --- | --- | --- |
| `SHCAnnouncementItem` | `HelpAnnouncement` | 公告模型 |
| `SHCAnnouncementLevel` | `HelpAnnouncementLevel` | 公告级别：`info`、`success`、`warning`、`critical` |
| `SHCVersionHistoryItem` | `VersionHistoryItem` | 版本历史 |
| `SHCVersionHistorySupplement` | `VersionHistorySupplement` | 远程版本补充信息 |
| `SHCHelpVideoLink` | `HelpVideoLink` | 版本视频链接 |
| `SHCHelpFAQItem` | `HelpFaqItem` | FAQ |
| `SHCHelpQuickLinkItem` | `HelpQuickLink` | 快速入口 |
| `SHCHelpQuickLinkAction` | `HelpQuickLinkActionType` | URL、反馈、评分、技术支持 |

## 行为映射

| SwiftHelpCenter 行为 | app_help_center 第一版实现 |
| --- | --- |
| 本地公告 | 已支持 |
| 远程公告 JSON | 已支持 |
| SwiftHelpCenter 公告 JSON 字段 | 已兼容 |
| 公告置顶 | 已支持 |
| 公告过期时间 | 已支持 |
| 公告未读状态 | 已支持 |
| 版本历史默认显示最新一条 | 已支持 |
| 展开全部版本历史 | 已支持 |
| 版本视频链接 | 已支持 |
| 远程版本补充 JSON | 已支持，使用 `remoteVersionSupplementUrl` |
| FAQ 展开项 | 已支持 |
| 快速入口 | 已支持 |
| 默认反馈/评分/支持入口 | 已支持，基于配置自动出现 |
| App Store 版本检测 | 第一版暂不支持 |
| 原生评分弹窗 | 第一版暂不支持，先使用 URL-first 评分入口 |
| 反馈表单 | 第二阶段实现 |
| 评分提醒管理 | 第三阶段实现 |
| DesignSystem 独立组件库 | Flutter 版暂不复刻独立设计系统 |

## 远程公告 JSON 兼容字段

app_help_center 第一版兼容 SwiftHelpCenter 示例公告字段：

- `id`
- `title`
- `message`
- `publishedAt`
- `level`
- `linkTitle`
- `linkURL`
- `isPinned`
- `expiresAt`

也额外兼容部分 Flutter/Dart 风格别名：

- `body`
- `linkUrl`
- `url`
- `published_at`
- `expires_at`
- `is_pinned`

## 远程版本补充 JSON 兼容字段

app_help_center 兼容 SwiftHelpCenter 的版本补充字段：

- `id`
- `videoTitle`
- `videoLinks`

其中 `id` 会按以下顺序匹配本地版本历史：

- 本地版本项 `id`
- 本地版本项 `versionName`
- 去掉开头 `v` 并转小写后的版本号，例如 `v1.8.2` 可匹配 `1.8.2`

## 第一版刻意不做的事情

- 不内置客服 SDK。
- 不内置 Discord Bot 或论坛频道集成。
- 不依赖原生 in-app review 插件。
- 不解析 `CHANGELOG.md`。
- 不实现独立窗口 presenter。
- 不复制 SwiftHelpCenter 的 SwiftUI DesignSystem。
