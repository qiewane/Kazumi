import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/widget/custom_dropdown_menu.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:kazumi/utils/logger.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/utils/tv_focus_utils.dart';  // TV焦点工具

class PopularPage extends StatefulWidget {
  const PopularPage({super.key});

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with AutomaticKeepAliveClientMixin {
  DateTime? _lastPressedAt;
  late NavigationBarState navigationBarState;
  final FocusNode _focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final PopularController popularController = Modular.get<PopularController>();

  // Key used to position the dropdown menu for the tag selector
  final GlobalKey selectorKey = GlobalKey();

  // TV焦点状态
  int _tvFocusedIndex = 0;
  int _tvCrossCount = 3;
  bool _isTVMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    if (popularController.trendList.isEmpty) {
      popularController.queryBangumiByTrend();
    }
    // 检测TV模式（通过屏幕宽度判断，TV通常大于1280）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectTVMode();
    });
  }

  void _detectTVMode() {
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _isTVMode = width > 800; // TV屏幕宽度通常较大
      if (_isTVMode) {
        _tvCrossCount = 5; // TV上显示更多列
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    scrollController.removeListener(scrollListener);
    super.dispose();
  }

  void scrollListener() {
    popularController.scrollOffset = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !popularController.isLoadingMore) {
      KazumiLogger().i('PopularPageController: Fetching next recommendation batch');
      if (popularController.currentTag != '') {
        popularController.queryBangumiByTag();
      } else {
        popularController.queryBangumiByTrend();
      }
    }
  }

  bool showWindowButton() {
    return GStorage.setting
        .get(SettingBoxKey.showWindowButton, defaultValue: false);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) >
            const Duration(seconds: 2)) {
      _lastPressedAt = DateTime.now();
      KazumiDialog.showToast(message: "再按一次退出应用", context: context);
      return;
    }
    SystemNavigator.pop();
  }

  /// TV焦点移动
  void _moveTVFocus(int delta) {
    final bangumiList = (popularController.currentTag == '')
        ? popularController.trendList
        : popularController.bangumiList;
    
    if (bangumiList.isEmpty) return;
    
    final int newIndex = (_tvFocusedIndex + delta).clamp(0, bangumiList.length - 1);
    if (newIndex != _tvFocusedIndex) {
      setState(() => _tvFocusedIndex = newIndex);
      _scrollToTVIndex(newIndex);
    }
  }

  /// TV自动滚动到焦点项
  void _scrollToTVIndex(int index) {
    final double itemHeight = MediaQuery.of(context).size.width / _tvCrossCount / 0.65 + 32.0;
    final double targetOffset = (index ~/ _tvCrossCount) * (itemHeight + StyleString.cardSpace);
    
    if (scrollController.hasClients) {
      scrollController.animateTo(
        targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// TV选中番剧
  void _onTVItemSelected(int index) {
    final bangumiList = (popularController.currentTag == '')
        ? popularController.trendList
        : popularController.bangumiList;
    
    if (index >= 0 && index < bangumiList.length) {
      // 模拟点击卡片，进入详情页
      Modular.to.pushNamed('/info/', arguments: bangumiList[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // TV模式：用RawKeyboardListener包裹，拦截遥控器按键
    Widget body = PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        onBackPressed(context);
      },
      child: Scaffold(
        body: CustomScrollView(
          controller: scrollController,
          slivers: [
            buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Observer(
                builder: (_) => AnimatedOpacity(
                  opacity: popularController.isLoadingMore ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: popularController.isLoadingMore
                      ? const LinearProgressIndicator(minHeight: 4)
                      : const SizedBox(height: 4),
                ),
              ),
            ),
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    StyleString.cardSpace, 0, StyleString.cardSpace, 0),
                sliver: Observer(builder: (_) {
                  if (popularController.isTimeOut) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: 400,
                        child: GeneralErrorWidget(
                          errMsg: '什么都没有找到 (´;ω;`)',
                          actions: [
                            GeneralErrorButton(
                              onPressed: () {
                                if (popularController.trendList.isEmpty) {
                                  popularController.queryBangumiByTrend();
                                } else {
                                  popularController.queryBangumiByTag();
                                }
                              },
                              text: '点击重试',
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return contentGrid(
                    (popularController.currentTag == '')
                        ? popularController.trendList
                        : popularController.bangumiList,
                  );
                })),
          ],
        ),
        // TV模式隐藏浮动按钮（遥控器不需要）
        floatingActionButton: _isTVMode ? null : FloatingActionButton(
          onPressed: () => scrollController.animateTo(0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut),
          child: const Icon(Icons.arrow_upward),
        ),
      ),
    );

    // TV模式添加键盘监听
    if (_isTVMode) {
      body = RawKeyboardListener(
        focusNode: TVFocusUtils.rootFocusNode,
        autofocus: true,
        onKey: (event) {
          return TVFocusUtils.handleDirectionKey(
            event,
            onUp: () => _moveTVFocus(-_tvCrossCount),
            onDown: () => _moveTVFocus(_tvCrossCount),
            onLeft: () => _moveTVFocus(-1),
            onRight: () => _moveTVFocus(1),
            onSelect: () => _onTVItemSelected(_tvFocusedIndex),
            onBack: () => onBackPressed(context),
          );
        },
        child: body,
      );
    }

    return body;
  }

  Widget contentGrid(bangumiList) {
    int crossCount = 3;
    if (MediaQuery.sizeOf(context).width > LayoutBreakpoint.compact['width']!) {
      crossCount = 5;
    }
    if (MediaQuery.sizeOf(context).width > LayoutBreakpoint.medium['width']!) {
      crossCount = 6;
    }
    
    // TV模式强制使用TV计算的值
    if (_isTVMode) {
      crossCount = _tvCrossCount;
    }
    
    // 更新TV列数
    _tvCrossCount = crossCount;

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // 行间距
          mainAxisSpacing: StyleString.cardSpace - 2,
          // 列间距
          crossAxisSpacing: StyleString.cardSpace,
          // 列数
          crossAxisCount: crossCount,
          mainAxisExtent:
              MediaQuery.of(context).size.width / crossCount / 0.65 +
                  MediaQuery.textScalerOf(context).scale(32.0),
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (bangumiList!.isEmpty) return null;
            
            // TV模式：用TVFocusable包装卡片，实现焦点高亮
            if (_isTVMode) {
              return TVFocusable(
                autoFocus: index == 0,
                onSelect: () => _onTVItemSelected(index),
                onFocus: () => setState(() => _tvFocusedIndex = index),
                child: BangumiCardV(bangumiItem: bangumiList[index]),
              );
            }
            
            // 手机模式：保持原样
            return BangumiCardV(bangumiItem: bangumiList[index]);
          },
          childCount: bangumiList!.isNotEmpty ? bangumiList!.length : 10,
        ),
      ),
    );
  }

  Widget buildSliverAppBar() {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 120,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: buildActions(),
      title: null,
      flexibleSpace: SafeArea(
        child: dtb.DragToMoveArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxExtent = 120 - MediaQuery.of(context).padding.top;
              final t = (1 -
                  ((constraints.maxHeight - kToolbarHeight) /
                          (maxExtent - kToolbarHeight))
                      .clamp(0.0, 1.0));
              // 字重收缩后为 w500，展开时为 w700
              final fontWeight = t < 0.5 ? FontWeight.w700 : FontWeight.w500;
              final fontSize = lerpDouble(28, 20, t)!;
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, top: 8, bottom: 8, right: 60),
                  child: SizedBox(
                    height: 44,
                    child: Observer(
                      builder: (_) {
                        final bool isTrend = popularController.currentTag == '';
                        return InkWell(
                          key: selectorKey,
                          borderRadius: BorderRadius.circular(8),
                          onTap: showTagMenu,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isTrend ? '热门番组' : popularController.currentTag,
                                style: theme.textTheme.headlineMedium!.copyWith(
                                  fontWeight: fontWeight,
                                  fontSize: fontSize,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down,
                                  size: fontSize, color: theme.iconTheme.color),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> buildActions() {
    final actions = <Widget>[
      if (MediaQuery.of(context).orientation == Orientation.portrait)
        IconButton(
          tooltip: '搜索',
          onPressed: () => Modular.to.pushNamed('/search/'),
          icon: const Icon(Icons.search),
        ),
    ];
    actions.add(
      IconButton(
        tooltip: '历史记录',
        onPressed: () => Modular.to.pushNamed('/settings/history/'),
        icon: const Icon(Icons.history),
      ),
    );
    if (Utils.isDesktop()) {
      if (!showWindowButton()) {
        actions.add(
          IconButton(
            tooltip: '退出',
            onPressed: () => windowManager.close(),
            icon: const Icon(Icons.close),
          ),
        );
      }
    }
    return actions;
  }

  Future<void> showTagMenu() async {
    // Calculate the position of the button manually to position the dropdown menu.
    // Using CustomDropdownMenu instead of PopupMenuButton to avoid flickering issues
    // and to support different font sizes in the button and menu items.
    final RenderBox renderBox =
        selectorKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final selected = await Navigator.push<String>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return CustomDropdownMenu(
            offset: offset,
            buttonSize: size,
            animation: animation,
            maxWidth: 80,
            items: [
              '',
              ...defaultAnimeTags,
            ],
            itemBuilder: (item) => item.isEmpty ? '热门番组' : item,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );

    if (selected == null) return;
    if (selected == '' && popularController.currentTag != '') {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      popularController.setCurrentTag('');
      popularController.clearBangumiList();
      if (popularController.trendList.isEmpty) {
        await popularController.queryBangumiByTrend();
      }
    } else if (selected != '' && selected != popularController.currentTag) {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      popularController.setCurrentTag(selected);
      await popularController.queryBangumiByTag(type: 'init');
    }
  }
}