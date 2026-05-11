import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 小米电视输入法适配器
class MiInputAdapter {
  /// 检测是否为小米电视
  static bool get isMiTV {
    // 通过系统属性检测
    // 实际项目中可通过MethodChannel获取设备信息
    return true; // 默认启用TV模式
  }

  /// 创建适配TV的TextField
  static Widget buildTVTextField({
    required TextEditingController controller,
    required String hintText,
    ValueChanged<String>? onSubmitted,
    TextInputType? keyboardType,
  }) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          // 处理小米输入法特殊按键
          if (event.logicalKey == LogicalKeyboardKey.select) {
            // 触发搜索
            onSubmitted?.call(controller.text);
          }
        }
      },
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 18.0),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 18.0,
            color: Colors.grey[600],
          ),
          prefixIcon: const Icon(Icons.search, size: 28.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              width: 3.0,
              color: Colors.blue[300]!,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
        ),
      ),
    );
  }

  /// 显示TV专用软键盘
  static void showTVKeyboard(BuildContext context, {
    required TextEditingController controller,
    required String title,
    ValueChanged<String>? onSubmitted,
  }) {
    showDialog(
      context: context,
      builder: (context) => TVKeyboardDialog(
        controller: controller,
        title: title,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// TV专用键盘对话框
class TVKeyboardDialog extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final ValueChanged<String>? onSubmitted;

  const TVKeyboardDialog({
    Key? key,
    required this.controller,
    required this.title,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<TVKeyboardDialog> createState() => _TVKeyboardDialogState();
}

class _TVKeyboardDialogState extends State<TVKeyboardDialog> {
  late TextEditingController _localController;

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController(text: widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 600.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _localController,
              autofocus: true,
              style: const TextStyle(fontSize: 20.0),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16.0),
              ),
              onSubmitted: (value) {
                widget.controller.text = value;
                widget.onSubmitted?.call(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16.0),
            // TV友好的虚拟键盘布局
            _buildVirtualKeyboard(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(fontSize: 16.0)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.controller.text = _localController.text;
            widget.onSubmitted?.call(_localController.text);
            Navigator.of(context).pop();
          },
          child: const Text('确定', style: TextStyle(fontSize: 16.0)),
        ),
      ],
    );
  }

  Widget _buildVirtualKeyboard() {
    final List<String> keys = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
      'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',
      'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L',
      'Z', 'X', 'C', 'V', 'B', 'N', 'M',
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: keys.map((key) {
        return Focus(
          child: Builder(
            builder: (context) {
              final bool isFocused = Focus.of(context).hasFocus;
              return Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocused ? Colors.blue : Colors.grey,
                    width: isFocused ? 3.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: InkWell(
                  onTap: () {
                    _localController.text += key;
                  },
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: isFocused ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }
}