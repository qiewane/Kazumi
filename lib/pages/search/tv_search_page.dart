import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/tv_focus_manager.dart';

/// TV 搜索页面 - 适配小米电视等设备的遥控器输入
class TVSearchPage extends StatefulWidget {
  const TVSearchPage({super.key});

  @override
  State<TVSearchPage> createState() => _TVSearchPageState();
}

class _TVSearchPageState extends State<TVSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showKeyboard = true;
  String _query = '';
  
  // T9 风格键盘布局 (适合遥控器)
  final List<List<String>> _keyboardLayout = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  void initState() {
    super.initState();
    // 小米电视: 默认显示屏幕键盘，禁用系统输入法
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        // 阻止系统键盘弹出
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _insertChar(String char) {
    setState(() {
      _query += char;
      _searchController.text = _query;
      _searchController.selection = TextSelection.collapsed(offset: _query.length);
    });
  }

  void _backspace() {
    if (_query.isNotEmpty) {
      setState(() {
        _query = _query.substring(0, _query.length - 1);
        _searchController.text = _query;
        _searchController.selection = TextSelection.collapsed(offset: _query.length);
      });
    }
  }

  void _clear() {
    setState(() {
      _query = '';
      _searchController.clear();
    });
  }

  void _search() {
    if (_query.isNotEmpty) {
      // 执行搜索
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _TVSearchResultsPage(query: _query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.contextMenu) {
            // 菜单键切换键盘显示
            setState(() => _showKeyboard = !_showKeyboard);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  TVButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _searchFocusNode.hasFocus 
                              ? TVFocusManager.defaultFocusColor 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: const InputDecoration(
                                hintText: '搜索番剧...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                              readOnly: true, // 禁用系统输入法
                              onTap: () {
                                setState(() => _showKeyboard = true);
                              },
                            ),
                          ),
                          if (_query.isNotEmpty)
                            TVButton(
                              onPressed: _clear,
                              child: const Icon(Icons.clear, color: Colors.white54, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TVButton(
                    onPressed: _search,
                    backgroundColor: TVFocusManager.defaultFocusColor,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('搜索', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            // 屏幕键盘
            if (_showKeyboard) _buildScreenKeyboard(),

            // 搜索建议/历史
            if (!_showKeyboard) Expanded(child: _buildSearchSuggestions()),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenKeyboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 字符键
          ..._keyboardLayout.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((char) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TVButton(
                      onPressed: () => _insertChar(char),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        char,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // 功能键
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TVButton(
                  onPressed: () => _insertChar(' '),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: const Text('空格', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                TVButton(
                  onPressed: _backspace,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: const Icon(Icons.backspace, color: Colors.white),
                ),
                const SizedBox(width: 12),
                TVButton(
                  onPressed: _clear,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: const Text('清空', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                TVButton(
                  onPressed: _search,
                  backgroundColor: TVFocusManager.defaultFocusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: const Text(
                    '搜索',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 小米电视提示
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              '按菜单键隐藏/显示键盘 | 遥控器方向键选择，确认键输入',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = ['热门搜索1', '热门搜索2', '新番推荐', '经典回顾'];
    final history = ['历史记录1', '历史记录2', '之前看的'];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TVButton(
                onPressed: () {},
                child: const Text('清空', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: history.map((item) {
              return TVButton(
                onPressed: () {
                  setState(() {
                    _query = item;
                    _searchController.text = item;
                  });
                  _search();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item, style: const TextStyle(color: Colors.white70)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
        const Text(
          '热门搜索',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: suggestions.map((item) {
            return TVButton(
              onPressed: () {
                setState(() {
                  _query = item;
                  _searchController.text = item;
                });
                _search();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: TVFocusManager.defaultFocusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TVFocusManager.defaultFocusColor.withOpacity(0.5)),
                ),
                child: Text(
                  item,
                  style: TextStyle(color: TVFocusManager.defaultFocusColor),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// 搜索结果页
class _TVSearchResultsPage extends StatelessWidget {
  final String query;

  const _TVSearchResultsPage({required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('"$query" 的搜索结果', style: const TextStyle(color: Colors.white)),
        leading: TVButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return TVCard(
            onPressed: () {},
            child: Container(
              color: Colors.grey[800],
              child: Center(
                child: Text(
                  '搜索结果 ${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
