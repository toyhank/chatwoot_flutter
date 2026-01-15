import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../utils/app_logger.dart';

/// 日志查看器页面
class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(
      talker: AppLogger.instance,
      appBarTitle: '应用日志',
      theme: TalkerScreenTheme(
        backgroundColor: Colors.black,
        cardColor: const Color(0xFF1C1C1E),
        textColor: Colors.white,
      ),
    );
  }
}
