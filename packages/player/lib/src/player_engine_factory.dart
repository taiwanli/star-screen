import 'package:star_domain/star_domain.dart' show PlayerEngineType;

import '../star_player.dart';

/// 播放内核工厂（docs/03 §1.2）：按偏好创建控制器，失败可回退。
class PlayerEngineFactory {
  const PlayerEngineFactory._();

  /// 创建内核控制器。
  /// [type]：libmpv / exo / system。
  static PlayerController create(PlayerEngineType type) {
    switch (type) {
      case PlayerEngineType.exo:
        return ExoVideoPlayerController();
      case PlayerEngineType.system:
        return ExternalPlayerController();
      case PlayerEngineType.libmpv:
        return MediaKitPlayerController();
    }
  }

  /// 当前内核显示名。
  static String label(PlayerEngineType type) => switch (type) {
        PlayerEngineType.libmpv => 'libmpv',
        PlayerEngineType.exo => 'ExoPlayer',
        PlayerEngineType.system => '外部播放器',
      };

  /// 格式适配说明（UI 提示）。
  static String describe(PlayerEngineType type) => switch (type) {
        PlayerEngineType.libmpv => '通用解码，三端一致（默认）',
        PlayerEngineType.exo => 'ExoPlayer：HLS/DASH/部分冷门封装更稳',
        PlayerEngineType.system => '调用本机 mpv/VLC/PotPlayer，适合特殊格式',
      };

  /// 建议回退序（同一 URL 播失败时）。
  static List<PlayerEngineType> fallbackOrder(PlayerEngineType current) {
    final all = <PlayerEngineType>[
      PlayerEngineType.libmpv,
      PlayerEngineType.exo,
      PlayerEngineType.system,
    ];
    return [for (final t in all) if (t != current) t];
  }
}
