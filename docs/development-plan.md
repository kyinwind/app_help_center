# app_help_center 开发计划

> 目标：基于现有 SwiftHelpCenter 的产品经验，用纯 Flutter/Dart 重新实现一套跨平台帮助中心组件库，支持 Android、iOS、macOS、Windows，并发布到 pub.dev。

这份文件是后续开发检查清单。每完成一项，就把对应任务从 `[ ]` 改成 `[x]`。

## 0. 产品与 SwiftHelpCenter 对齐

- [x] 阅读 SwiftHelpCenter 的 README、英文 README、示例 JSON 和核心源码。
- [x] 梳理 SwiftHelpCenter 已实现的公开能力与 Flutter 版需要复刻的能力。
- [x] 定义 Flutter 版命名，保留 SwiftHelpCenter 的产品概念，但不复制 SwiftUI 专属 API。
- [x] 整理 SwiftHelpCenter 到 app_help_center 的概念映射。
- [x] 确认 `0.1.0` 首个可发布版本范围。
- [x] 确认第一版保持轻量 URL-first，第二版再开放更多平台回调接口。

## 1. 包基础工程

- [x] 在 `/Users/yangxuehui/Documents/dev_open_source/app_help_center` 创建 Flutter package 骨架。
- [x] 更新 `pubspec.yaml` 的 pub.dev 元信息。
- [x] 添加核心依赖：`url_launcher`、`shared_preferences`、`http`、`intl`。
- [x] 建立 `lib/src/` 源码目录结构。
- [x] 替换 Flutter 模板代码，导出 app_help_center 的公开 API。

## 2. 帮助中心 MVP 核心能力

- [x] 实现帮助中心配置模型。
- [x] 实现公告模型，并兼容 SwiftHelpCenter 的远程公告 JSON 字段。
- [x] 实现公告级别：`info`、`success`、`warning`、`critical`。
- [x] 实现版本历史模型，支持视频链接。
- [x] 实现远程版本补充 JSON，用于补充版本视频/文章链接。
- [x] 实现 FAQ 模型。
- [x] 实现快速入口模型和动作：URL、反馈、评分、技术支持。
- [x] 实现控制器，负责排序、合并、刷新和未读状态。
- [x] 使用 `shared_preferences` 保存本地未读状态。
- [x] 使用 `http` 加载远程公告。
- [x] 使用 `url_launcher` 打开技术支持、评分、视频和普通链接。
- [x] 实现单条公告标记已读。
- [x] 实现单条版本历史标记已读。
- [x] 实现全部内容标记已读。
- [x] 实现重置阅读状态。

## 3. 帮助中心界面

- [x] 实现 `AppHelpCenterPage`。
- [x] 实现移动端和桌面端响应式布局。
- [x] 实现顶部标题区和快捷操作按钮。
- [x] 实现公告区，支持摘要折叠和展开全部。
- [x] 实现版本历史区，默认只展示最新一条，支持展开全部。
- [x] 实现快速入口网格或列表。
- [x] 实现 FAQ 折叠列表。
- [x] 实现未读红点和未读徽标。
- [x] 支持 Flutter `ThemeData` 的明暗模式。

## 4. 国际化

- [x] 内置中文文案。
- [x] 内置英文文案。
- [x] 支持跟随系统 locale。
- [x] 支持调用方指定 locale。
- [x] 支持调用方覆盖插件内置文案。
- [x] 在 README 中说明国际化用法。

## 5. 示例应用

- [x] 创建可运行的 example app。
- [x] 添加本地公告示例。
- [x] 添加带视频链接的版本历史示例。
- [x] 添加 FAQ 示例。
- [x] 添加快速入口示例。
- [x] 演示技术支持和评分链接。
- [x] 演示远程公告 JSON 格式。

## 6. README 与发布文档

- [x] 写清楚包定位：Flutter apps 的帮助中心与用户沟通套件。
- [x] 说明与 SwiftHelpCenter 的关系。
- [x] 添加安装方式。
- [x] 添加基础用法。
- [x] 添加完整配置示例。
- [x] 添加远程公告 JSON 示例。
- [x] 添加平台支持说明。
- [x] 添加当前限制和路线图。
- [x] 补充 License 和 pub.dev 发布准备说明。

## 7. 测试与验证

- [x] 测试公告 JSON 解析。
- [x] 测试公告排序。
- [x] 测试公告过期逻辑。
- [x] 测试公告未读状态。
- [x] 测试版本历史未读状态。
- [x] 测试全部已读和重置逻辑。
- [x] 运行 `dart format`。
- [x] 运行 `flutter analyze`。
- [x] 运行 `flutter test`。

## 8. 第二阶段：反馈系统

- [x] 确认 Flutter 版反馈系统不做独立全局配置，统一收敛到 `AppHelpCenterConfig`。
- [x] 确认 `feedback == null` 时不显示反馈入口，`feedback != null` 时显示内置反馈表单。
- [x] 确认反馈配置采用 `HelpFeedbackConfig` 子配置，避免把 `AppHelpCenterConfig` 顶层字段撑散。
- [x] 设计 `FeedbackConfig`。
- [x] 设计 `FeedbackPayload`。
- [x] 设计 `FeedbackChannel`。
- [x] 实现邮件渠道，通过 `mailto:` 打开系统邮件客户端。
- [x] 实现网页表单渠道。
- [x] 实现 Discord webhook 渠道。
- [x] 实现钉钉 webhook 渠道。
- [x] 实现自定义 submit handler。
- [x] 实现 `FeedbackPage`。
- [x] 实现系统信息收集。
- [x] 补充测试和 README 示例。

## 9. 第三阶段：评分提醒管理

- [ ] 设计 `ReviewPromptConfig`。
- [ ] 实现使用次数阈值。
- [ ] 实现使用天数阈值。
- [ ] 实现“稍后再说”逻辑。
- [ ] 实现“不再提醒”逻辑。
- [ ] 实现评分提醒弹窗。
- [ ] 实现多平台商店链接打开工具。
- [ ] 补充测试和 README 示例。

## 10. 第四阶段：多平台打磨

- [ ] 优化桌面端布局。
- [ ] 优化移动端布局。
- [ ] 添加 pub.dev 展示截图。
- [x] 添加 CHANGELOG。
- [x] 运行 pub.dev dry-run 验证。
