import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV焦点管理工具类
class TVFocusUtils {
  static final FocusNode _rootFocusNode = FocusNode();

  /// 获取根焦点节点
  static FocusNode get rootFocusNode => _rootFocusNode;

  /// 初始化TV焦点系统
  static void initialize() {
    // 请求初始焦点
    _rootFocusNode.requestFocus();
  }

  /// 处理方向键导航
  static bool handleDirectionKey(RawKeyEvent event, {
    required VoidCallback onUp,
    required VoidCallback onDown,
    required VoidCallback onLeft,
    required VoidCallback onRight,
    required VoidCallback onSelect,
    required VoidCallback onBack,
  }) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        onUp();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        onDown();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        onLeft();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        onRight();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.select ||
                 event.logicalKey == LogicalKeyboardKey.enter) {
        onSelect();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
                 event.logicalKey == LogicalKeyboardKey.goBack) {
        onBack();
        return true;
      }
    }
    return false;
  }
}

/// TV焦点包装器 - 为任意Widget添加焦点支持
class TVFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onFocus;
  final VoidCallback? onUnfocus;
  final bool autoFocus;
  final FocusNode? focusNode;

  const TVFocusable({
    Key? key,
    required this.child,
    this.onSelect,
    this.onFocus,
    this.onUnfocus,
    this.autoFocus = false,
    this.focusNode,
  }) : super(key: key);

  @override
  State<TVFocusable> createState() => _TVFocusableState();
}

class _TVFocusableState extends State<TVFocusable> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      widget.onFocus?.call();
    } else {
      widget.onUnfocus?.call();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: (node, event) {
        if (event is RawKeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onSelect?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          border: _isFocused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3.0,
                )
              : null,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  )
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// TV网格焦点管理器
class TVGridFocusManager extends StatefulWidget {
  final int crossAxisCount;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final void Function(int index)? onItemSelected;
  final ScrollController? scrollController;

  const TVGridFocusManager({
    Key? key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.onItemSelected,
    this.scrollController,
  }) : super(key: key);

  @override
  State<TVGridFocusManager> createState() => _TVGridFocusManagerState();
}

class _TVGridFocusManagerState extends State<TVGridFocusManager> {
  int _focusedIndex = 0;
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
  }

  void _initializeFocusNodes() {
    for (int i = 0; i < widget.itemCount; i++) {
      _focusNodes.add(FocusNode());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(TVGridFocusManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _disposeFocusNodes();
      _initializeFocusNodes();
    }
  }

  void _disposeFocusNodes() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  @override
  void dispose() {
    _disposeFocusNodes();
    super.dispose();
  }

  void _moveFocus(int dx, int dy) {
    final int currentRow = _focusedIndex ~/ widget.crossAxisCount;
    final int currentCol = _focusedIndex % widget.crossAxisCount;

    int newRow = currentRow + dy;
    int newCol = currentCol + dx;

    // 边界检查
    if (newCol < 0 || newCol >= widget.crossAxisCount) return;

    final int newIndex = newRow * widget.crossAxisCount + newCol;
    if (newIndex < 0 || newIndex >= widget.itemCount) return;

    setState(() {
      _focusedIndex = newIndex;
    });

    _focusNodes[newIndex].requestFocus();

    // 自动滚动到可见区域
    _scrollToFocusedItem(newIndex);
  }

  void _scrollToFocusedItem(int index) {
    if (widget.scrollController == null) return;

    final double itemHeight = 200.0; // 根据实际布局调整
    final double targetOffset = (index ~/ widget.crossAxisCount) * itemHeight;

    widget.scrollController!.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveFocus(0, -1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveFocus(0, 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _moveFocus(-1, 0);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _moveFocus(1, 0);
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
                     event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onItemSelected?.call(_focusedIndex);
          }
        }
      },
      child: GridView.builder(
        controller: widget.scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: 0.7,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return Focus(
            focusNode: _focusNodes[index],
            child: Container(
              decoration: BoxDecoration(
                border: _focusNodes[index].hasFocus
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3.0,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: widget.itemBuilder(context, index),
            ),
          );
        },
      ),
    );
  }
}