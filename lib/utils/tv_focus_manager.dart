import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV 焦点管理器 - 全局焦点控制
class TVFocusManager {
  static final TVFocusManager _instance = TVFocusManager._internal();
  factory TVFocusManager() => _instance;
  TVFocusManager._internal();

  /// 焦点颜色配置
  static const Color defaultFocusColor = Color(0xFFFF6B6B);
  static const double defaultFocusScale = 1.05;
  static const Duration focusAnimationDuration = Duration(milliseconds: 150);

  /// 全局按键处理器
  static KeyEventResult handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        // 方向键导航由 Focus 系统自动处理
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        // 确认键触发当前焦点
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.backspace:
        // 返回键
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }
}

/// TV 优化按钮 - 可完全替代普通 ElevatedButton/TextButton
class TVButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final FocusNode? focusNode;
  final Color? focusColor;
  final double? focusScale;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool autofocus;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.focusNode,
    this.focusColor,
    this.focusScale,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.autofocus = false,
  });

  @override
  State<TVButton> createState() => _TVButtonState();
}

class _TVButtonState extends State<TVButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? TVFocusManager.defaultFocusColor;
    final focusScale = widget.focusScale ?? TVFocusManager.defaultFocusScale;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: TVFocusManager.focusAnimationDuration,
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scale(_isFocused ? focusScale : 1.0),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? 
                   (_isFocused ? focusColor.withOpacity(0.2) : Colors.transparent),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? focusColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: focusColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// TV 卡片组件 - 用于网格列表
class TVCard extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? aspectRatio;
  final FocusNode? focusNode;
  final bool autofocus;

  const TVCard({
    super.key,
    required this.onPressed,
    required this.child,
    this.aspectRatio,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<TVCard> createState() => _TVCardState();
}

class _TVCardState extends State<TVCard> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: TVFocusManager.focusAnimationDuration,
          scale: _isFocused ? 1.05 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused ? TVFocusManager.defaultFocusColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: TVFocusManager.defaultFocusColor.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 4,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: AspectRatio(
                aspectRatio: widget.aspectRatio ?? 16 / 9,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// TV 列表项
class TVListItem extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool autofocus;

  const TVListItem({
    super.key,
    required this.onPressed,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<TVListItem> createState() => _TVListItemState();
}

class _TVListItemState extends State<TVListItem> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: TVFocusManager.focusAnimationDuration,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isFocused ? TVFocusManager.defaultFocusColor.withOpacity(0.1) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _isFocused ? TVFocusManager.defaultFocusColor : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
                        color: _isFocused ? Colors.white : Colors.white70,
                      ),
                      child: widget.title,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 14,
                          color: _isFocused ? Colors.white70 : Colors.white54,
                        ),
                        child: widget.subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 16),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// TV 导航栏
class TVNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<TVNavigationItem> items;

  const TVNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Logo 区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Kazumi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TVFocusManager.defaultFocusColor,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 导航项
          ...List.generate(items.length, (index) {
            return TVButton(
              autofocus: index == 0,
              onPressed: () => onTap(index),
              backgroundColor: currentIndex == index 
                  ? TVFocusManager.defaultFocusColor.withOpacity(0.2) 
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      items[index].icon,
                      color: currentIndex == index 
                          ? TVFocusManager.defaultFocusColor 
                          : Colors.white70,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      items[index].label,
                      style: TextStyle(
                        fontSize: 16,
                        color: currentIndex == index 
                            ? TVFocusManager.defaultFocusColor 
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TVNavigationItem {
  final IconData icon;
  final String label;
  
  const TVNavigationItem({
    required this.icon,
    required this.label,
  });
}
