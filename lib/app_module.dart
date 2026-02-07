import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/index_module.dart';
import 'package:kazumi/pages/index/tv_index_page.dart';
import 'package:kazumi/pages/search/search_page.dart';
import 'package:kazumi/pages/search/tv_search_page.dart';
import 'package:kazumi/utils/tv_detector.dart';

class AppModule extends Module {
  @override
  void binds(i) {}

  @override
  void routes(r) {
    // 根路由 - 自动判断 TV 或手机
    r.child(
      "/",
      child: (context) => FutureBuilder<bool>(
        future: TVDetector().isTV,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isTV = snapshot.data ?? false;
          // TV 设备使用 TVIndexPage，否则使用原有的 IndexModule
          return isTV ? const TVIndexPage() : const _IndexModuleWrapper();
        },
      ),
    );

    // 搜索路由 - 自动判断 TV 或手机
    r.child(
      "/search",
      child: (context) => FutureBuilder<bool>(
        future: TVDetector().isTV,
        builder: (context, snapshot) {
          final isTV = snapshot.data ?? false;
          return isTV ? const TVSearchPage() : const SearchPage();
        },
      ),
    );

    // 其他模块路由保持原有
    r.module("/index", module: IndexModule());
  }
}

// 包装器用于加载原有 IndexModule
class _IndexModuleWrapper extends StatelessWidget {
  const _IndexModuleWrapper();

  @override
  Widget build(BuildContext context) {
    // 使用 Modular 导航到 IndexModule
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Modular.to.navigate('/index/');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
