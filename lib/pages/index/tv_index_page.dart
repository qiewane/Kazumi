import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/tv_focus_manager.dart';
import 'package:kazumi/utils/tv_detector.dart';
import 'package:kazumi/pages/player/tv_player_page.dart';

/// TV 版首页 - 完全替代普通首页用于 TV 设备
class TVIndexPage extends StatefulWidget {
  const TVIndexPage({super.key});

  @override
  State<TVIndexPage> createState() => _TVIndexPageState();
}

class _TVIndexPageState extends State<TVIndexPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<TVNavigationItem> _navItems = const [
    TVNavigationItem(icon: Icons.home, label: '推荐'),
    TVNavigationItem(icon: Icons.schedule, label: '时间表'),
    TVNavigationItem(icon: Icons.favorite, label: '追番'),
    TVNavigationItem(icon: Icons.history, label: '历史'),
    TVNavigationItem(icon: Icons.settings, label: '设置'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Row(
        children: [
          // 左侧导航
          TVNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavChanged,
            items: _navItems,
          ),
          
          // 右侧内容
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _TVRecommendTab(onVideoSelected: _playVideo),
                _TVScheduleTab(onVideoSelected: _playVideo),
                _TVFavoriteTab(onVideoSelected: _playVideo),
                _TVHistoryTab(onVideoSelected: _playVideo),
                _TVSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playVideo(String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TVPlayerPage(
          videoUrl: url,
          title: title,
        ),
      ),
    );
  }
}

// 推荐标签页
class _TVRecommendTab extends StatelessWidget {
  final Function(String url, String title) onVideoSelected;

  const _TVRecommendTab({required this.onVideoSelected});

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final items = List.generate(20, (i) => {
      'title': '热门番剧 ${i + 1}',
      'image': 'https://via.placeholder.com/400x225/FF6B6B/FFFFFF?text=Anime+$i',
      'url': 'https://example.com/video$i.mp4',
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '为你推荐',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 16 / 9,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return TVCard(
                  autofocus: index == 0,
                  onPressed: () => onVideoSelected(item['url']!, item['title']!),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item['image']!,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Text(
                            item['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 时间表标签页
class _TVScheduleTab extends StatelessWidget {
  final Function(String url, String title) onVideoSelected;

  const _TVScheduleTab({required this.onVideoSelected});

  @override
  Widget build(BuildContext context) {
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: TVFocusManager.defaultFocusColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: TVFocusManager.defaultFocusColor,
            tabs: weekDays.map((day) => Tab(text: day)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: weekDays.map((day) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return TVListItem(
                      onPressed: () => onVideoSelected(
                        'https://example.com/video.mp4',
                        '$day 更新番剧 ${index + 1}',
                      ),
                      leading: Container(
                        width: 120,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54)),
                      ),
                      title: Text('$day 更新番剧 ${index + 1}'),
                      subtitle: Text('更新时间: ${12 + index % 12}:00'),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 追番标签页
class _TVFavoriteTab extends StatelessWidget {
  final Function(String url, String title) onVideoSelected;

  const _TVFavoriteTab({required this.onVideoSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的追番',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 15,
              itemBuilder: (context, index) {
                return TVListItem(
                  onPressed: () => onVideoSelected(
                    'https://example.com/video.mp4',
                    '追番列表 ${index + 1}',
                  ),
                  leading: Container(
                    width: 160,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('封面 ${index + 1}', style: const TextStyle(color: Colors.white54))),
                  ),
                  title: Text('追番列表 ${index + 1}'),
                  subtitle: Text('更新至第 ${index + 5} 集'),
                  trailing: TVButton(
                    onPressed: () {},
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 历史标签页
class _TVHistoryTab extends StatelessWidget {
  final Function(String url, String title) onVideoSelected;

  const _TVHistoryTab({required this.onVideoSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '观看历史',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TVButton(
                onPressed: () {},
                child: const Text('清空历史', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return TVListItem(
                  onPressed: () => onVideoSelected(
                    'https://example.com/video.mp4',
                    '历史记录 ${index + 1}',
                  ),
                  leading: Container(
                    width: 160,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        const Center(child: Icon(Icons.history, color: Colors.white54)),
                        LinearProgressIndicator(
                          value: (20 - index) / 20,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(TVFocusManager.defaultFocusColor.withOpacity(0.8)),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                  title: Text('历史记录 ${index + 1}'),
                  subtitle: Text('观看到 ${((20 - index) / 20 * 100).toInt()}%'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 设置标签页
class _TVSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = [
      {'icon': Icons.palette, 'title': '主题设置', 'subtitle': '深色模式'},
      {'icon': Icons.video_settings, 'title': '播放设置', 'subtitle': '自动播放下一集'},
      {'icon': Icons.subtitles, 'title': '弹幕设置', 'subtitle': '弹幕透明度: 80%'},
      {'icon': Icons.storage, 'title': '缓存管理', 'subtitle': '已使用 1.2GB'},
      {'icon': Icons.info, 'title': '关于', 'subtitle': '版本 1.0.0'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: settings.length,
              itemBuilder: (context, index) {
                final setting = settings[index];
                return TVListItem(
                  onPressed: () {},
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: TVFocusManager.defaultFocusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      setting['icon'] as IconData,
                      color: TVFocusManager.defaultFocusColor,
                    ),
                  ),
                  title: Text(setting['title'] as String),
                  subtitle: Text(setting['subtitle'] as String),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
