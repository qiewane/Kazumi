import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:kazumi/utils/tv_focus_manager.dart';
import 'package:kazumi/utils/tv_detector.dart';

/// TV 专用播放器页面
/// 完全替代原有播放器页面用于 TV 设备
class TVPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final List<String>? episodes;
  final int? currentEpisodeIndex;

  const TVPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.episodes,
    this.currentEpisodeIndex,
  });

  @override
  State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  late final Player player;
  late final VideoController controller;
  
  bool _showControls = true;
  bool _isPlaying = true;
  double _currentProgress = 0;
  double _bufferedProgress = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isMenuOpen = false;
  int _selectedEpisodeIndex = 0;

  // 控制栏自动隐藏计时器
  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedEpisodeIndex = widget.currentEpisodeIndex ?? 0;
    
    player = Player();
    controller = VideoController(player);

    _initializePlayer();
    _startControlsTimer();
  }

  void _initializePlayer() async {
    await player.open(Media(widget.videoUrl));
    player.setVolume(_volume * 100);
    
    player.stream.position.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _currentProgress = position.inMilliseconds / 
              (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1);
        });
      }
    });

    player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    player.stream.buffer.listen((buffer) {
      if (mounted && _duration.inMilliseconds > 0) {
        setState(() {
          _bufferedProgress = buffer.inMilliseconds / _duration.inMilliseconds;
        });
      }
    });

    player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  void _startControlsTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      final inactive = DateTime.now().difference(_lastInteraction).inSeconds > 5;
      if (inactive && _showControls && _isPlaying) {
        setState(() => _showControls = false);
      }
      return mounted;
    });
  }

  void _resetControlsTimer() {
    setState(() {
      _lastInteraction = DateTime.now();
      _showControls = true;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            // 视频层
            Positioned.fill(
              child: Video(controller: controller),
            ),

            // 控制层
            if (_showControls) _buildControls(),

            // 菜单层 (选集等)
            if (_isMenuOpen) _buildSideMenu(),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    
    _resetControlsTimer();

    switch (event.logicalKey) {
      // 播放控制
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.space:
        _togglePlay();
        return KeyEventResult.handled;
        
      case LogicalKeyboardKey.mediaPlay:
        player.play();
        return KeyEventResult.handled;
        
      case LogicalKeyboardKey.mediaPause:
        player.pause();
        return KeyEventResult.handled;
        
      case LogicalKeyboardKey.mediaStop:
        player.stop();
        return KeyEventResult.handled;

      // 快进/快退
      case LogicalKeyboardKey.arrowRight:
        if (event is KeyRepeatEvent || HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft)) {
          _seekRelative(30); // 长按或Shift+右 = 30秒快进
        } else {
          _seekRelative(10); // 普通 = 10秒快进
        }
        return KeyEventResult.handled;
        
      case LogicalKeyboardKey.arrowLeft:
        if (event is KeyRepeatEvent || HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft)) {
          _seekRelative(-30);
        } else {
          _seekRelative(-10);
        }
        return KeyEventResult.handled;

      // 音量
      case LogicalKeyboardKey.arrowUp:
        _adjustVolume(0.1);
        return KeyEventResult.handled;
        
      case LogicalKeyboardKey.arrowDown:
        _adjustVolume(-0.1);
        return KeyEventResult.handled;

      // 返回
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
        if (_isMenuOpen) {
          setState(() => _isMenuOpen = false);
        } else {
          Navigator.of(context).pop();
        }
        return KeyEventResult.handled;

      // 菜单/选集
      case LogicalKeyboardKey.contextMenu:
      case LogicalKeyboardKey.keyM:
        setState(() => _isMenuOpen = !_isMenuOpen);
        return KeyEventResult.handled;

      // 数字键直接跳转进度
      case LogicalKeyboardKey.digit0:
        _seekToProgress(0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit1:
        _seekToProgress(0.1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit2:
        _seekToProgress(0.2);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit3:
        _seekToProgress(0.3);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit4:
        _seekToProgress(0.4);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit5:
        _seekToProgress(0.5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit6:
        _seekToProgress(0.6);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit7:
        _seekToProgress(0.7);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit8:
        _seekToProgress(0.8);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit9:
        _seekToProgress(0.9);
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seekRelative(int seconds) {
    final newPosition = _position + Duration(seconds: seconds);
    player.seek(newPosition.clamp(Duration.zero, _duration));
  }

  void _seekToProgress(double progress) {
    final newPosition = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    player.seek(newPosition);
  }

  void _adjustVolume(double delta) {
    setState(() {
      _volume = (_volume + delta).clamp(0.0, 1.0);
      player.setVolume(_volume * 100);
    });
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                TVButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.episodes != null)
                  TVButton(
                    onPressed: () => setState(() => _isMenuOpen = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TVFocusManager.defaultFocusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '第 ${_selectedEpisodeIndex + 1} 集',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // 底部控制栏
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 进度条
                _buildProgressBar(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // 播放/暂停
                    TVButton(
                      onPressed: _togglePlay,
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // 时间显示
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    // 音量
                    Row(
                      children: [
                        const Icon(Icons.volume_up, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: _volume,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            final progress = details.localPosition.dx / constraints.maxWidth;
            _seekToProgress(progress);
          },
          child: Container(
            height: 40,
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 背景
                Container(
                  height: 4,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 缓冲进度
                Container(
                  height: 4,
                  width: constraints.maxWidth * _bufferedProgress,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 播放进度
                Container(
                  height: 4,
                  width: constraints.maxWidth * _currentProgress,
                  decoration: BoxDecoration(
                    color: TVFocusManager.defaultFocusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 滑块
                Positioned(
                  left: (constraints.maxWidth * _currentProgress) - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: TVFocusManager.defaultFocusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TVFocusManager.defaultFocusColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSideMenu() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Row(
        children: [
          // 菜单内容
          Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TVButton(
                      onPressed: () => setState(() => _isMenuOpen = false),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '选集',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (widget.episodes != null)
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.episodes!.length,
                      itemBuilder: (context, index) {
                        return TVListItem(
                          autofocus: index == _selectedEpisodeIndex,
                          onPressed: () {
                            setState(() => _selectedEpisodeIndex = index);
                            // 切换视频源
                            player.open(Media(widget.episodes![index]));
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: index == _selectedEpisodeIndex
                                  ? TVFocusManager.defaultFocusColor
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: index == _selectedEpisodeIndex
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          title: Text('第 ${index + 1} 集'),
                          subtitle: index == _selectedEpisodeIndex
                              ? const Text('正在播放')
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // 点击关闭区域
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMenuOpen = false),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
