/// 播放引擎偏好（docs/03 §1.2 / 多内核切换）。
enum PlayerEngineType {
  libmpv,
  exo,
  system,
}

class PlayerEnginePref {
  static PlayerEngineType parse(String? raw) {
    if (raw == 'exo') return PlayerEngineType.exo;
    if (raw == 'system') return PlayerEngineType.system;
    return PlayerEngineType.libmpv;
  }

  static String nameOf(PlayerEngineType t) => switch (t) {
        PlayerEngineType.exo => 'exo',
        PlayerEngineType.system => 'system',
        PlayerEngineType.libmpv => 'libmpv',
      };

  /// 供 UI 显示的说明。
  static String describe(PlayerEngineType t) => switch (t) {
        PlayerEngineType.libmpv => 'libmpv（三端通用，默认）',
        PlayerEngineType.exo => 'ExoPlayer（video_player，HLS/DASH 更稳）',
        PlayerEngineType.system => '外部播放器（mpv / VLC / PotPlayer）',
      };
}
