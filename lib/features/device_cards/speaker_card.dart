import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 音箱设备卡片
class SpeakerCard extends StatefulWidget {
  final Device device;

  const SpeakerCard({
    super.key,
    required this.device,
  });

  @override
  State<SpeakerCard> createState() => _SpeakerCardState();
}

class _SpeakerCardState extends State<SpeakerCard> {
  bool _isPlaying = false;
  int _volume = 50;
  String _currentSong = '暂无播放';
  String _currentArtist = '-';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🔊', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.device.isOnline ? '已连接' : '离线',
                        style: TextStyle(
                          color: widget.device.isOnline
                              ? AppColors.statusOnline
                              : AppColors.statusOffline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isPlaying && widget.device.isOnline)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.device.isOnline) ...[
              // 当前播放
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentSong,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentArtist,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 播放控制
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 32,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 40,
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                          if (_isPlaying) {
                            _currentSong = '夜曲';
                            _currentArtist = '周杰伦';
                          } else {
                            _currentSong = '暂无播放';
                            _currentArtist = '-';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 32,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 音量控制
              Row(
                children: [
                  const Icon(Icons.volume_down),
                  Expanded(
                    child: Slider(
                      value: _volume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$_volume',
                      onChanged: (value) {
                        setState(() {
                          _volume = value.toInt();
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up),
                  const SizedBox(width: 8),
                  Text(
                    '$_volume%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 快捷功能
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.mic_outlined, size: 18),
                      label: const Text('语音助手'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.library_music_outlined, size: 18),
                      label: const Text('播放列表'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '音箱离线',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

