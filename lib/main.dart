import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'app_module.dart';
import 'app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TV模式初始化
  _initializeTVMode();

  runApp(ModularApp(
    module: AppModule(),
    child: const AppWidget(),
  ));
}

void _initializeTVMode() {
  // 强制横屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 隐藏系统UI (TV全屏模式)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 设置TV专用主题
  // 高对比度、大字体、清晰的焦点标识
}

/// TV主题配置
class TVTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // TV上使用更大的字体
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 18.0),
        titleMedium: TextStyle(fontSize: 16.0),
        titleSmall: TextStyle(fontSize: 14.0),
        bodyLarge: TextStyle(fontSize: 16.0),
        bodyMedium: TextStyle(fontSize: 14.0),
        bodySmall: TextStyle(fontSize: 12.0),
      ),
      // 焦点高亮颜色
      focusColor: Colors.blue[300],
      // 更大的点击区域
      visualDensity: VisualDensity.comfortable,
    );
  }

  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    );
  }
}